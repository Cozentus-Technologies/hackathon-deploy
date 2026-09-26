#!/bin/sh
# Generic SSH-tunnel wrapper for reaching a private-network DB from Cloud Run
# through a jump host. Establishes the tunnel in the background, waits for it
# to be ready, then execs the real app command (passed as "$@") in the
# foreground so it becomes PID 1.
#
# Required env vars (set these in the Dockerfile or via Cloud Run env vars):
#   DB_TUNNEL_SSH_KEY_PATH  - path to the mounted SSH private key secret
#                             (e.g. /secrets/db_tunnel_key)
#   DB_TUNNEL_JUMP_HOST     - jump host address (e.g. 49.249.180.187)
#   DB_TUNNEL_JUMP_USER     - jump host SSH user (e.g. innovation)
#   DB_TUNNEL_REMOTE_HOST   - DB private host, as reached from the jump host
#                             (e.g. 192.168.1.13)
#   DB_TUNNEL_REMOTE_PORT   - DB port on that host (e.g. 7035)
#   DB_TUNNEL_LOCAL_PORT    - local port your app should connect to instead
#                             (e.g. 3306) -- point your app's DB_URL/host at
#                             127.0.0.1:$DB_TUNNEL_LOCAL_PORT
#
# Needs openssh-client (and netcat for the readiness check) installed in the
# final image stage. Ask DevOps for the shared db-jump-host-ssh-key secret
# and your team's own DB credential secrets before using this.

set -e

# Cloud Run mounts Secret Manager volumes read-only (mode 0444), and ssh
# refuses to use a private key that's group/world-readable -- chmod on the
# mounted path itself fails silently (read-only filesystem). Copy it to a
# writable location first, then lock that copy down.
RUNTIME_KEY_PATH=/tmp/db_tunnel_key
cp "$DB_TUNNEL_SSH_KEY_PATH" "$RUNTIME_KEY_PATH"
chmod 600 "$RUNTIME_KEY_PATH"

ssh -N \
  -o IdentitiesOnly=yes \
  -o StrictHostKeyChecking=accept-new \
  -o ServerAliveInterval=30 \
  -o ExitOnForwardFailure=yes \
  -i "$RUNTIME_KEY_PATH" \
  -L 127.0.0.1:"$DB_TUNNEL_LOCAL_PORT":"$DB_TUNNEL_REMOTE_HOST":"$DB_TUNNEL_REMOTE_PORT" \
  "$DB_TUNNEL_JUMP_USER"@"$DB_TUNNEL_JUMP_HOST" &

echo "waiting for db tunnel on 127.0.0.1:$DB_TUNNEL_LOCAL_PORT ..."
for i in $(seq 1 30); do
  if nc -z 127.0.0.1 "$DB_TUNNEL_LOCAL_PORT" 2>/dev/null; then
    echo "db tunnel ready"
    break
  fi
  sleep 1
done

exec "$@"
