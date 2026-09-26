# Cozforge 2.0 — Deploy to Cloud Run

This repo holds the shared CI/CD pipeline. You don't need any GCP access — everything runs through this one reusable workflow, keyed off your GitHub push. Build/deploy logs show up in **your own repo's Actions tab**.

## What you need to do (once)

1. **Add a `Dockerfile`** to your repo root. Pick the closest match from [`templates/`](./templates) and adjust the entrypoint/build paths for your app:
   - `Dockerfile.python-django` — Django + Gunicorn
   - `Dockerfile.python-fastapi` — FastAPI/ASGI
   - `Dockerfile.angular` — Angular (needs `templates/nginx.conf` alongside it)
   - `Dockerfile.react` — React/Vite (needs `templates/nginx.conf` alongside it)
   - `Dockerfile.dotnet` — ASP.NET Core

   Your app **must listen on `$PORT`** (Cloud Run sets this, default `8080`) — the templates already do this.

2. **Add this file** to your repo at `.github/workflows/deploy.yml`, using **your** service name from the table below:

   ```yaml
   name: Deploy

   on:
     push:
       branches: [main]
     workflow_dispatch: {}

   jobs:
     deploy:
       uses: Cozentus-Technologies/hackathon-deploy/.github/workflows/deploy-cloud-run.yml@main
       with:
         service_name: <YOUR SERVICE NAME FROM THE TABLE BELOW>
   ```

3. **Push to `main`.** That's it — no secrets to configure, no GCP login. The Actions tab in your repo shows the build/deploy logs.

## Your service name and URL

| Repo | `service_name` | URL after first deploy |
|---|---|---|
| eternal_host_ui | `eternal-host-ui` | https://eternalhost.cozentus.com |
| eternal_host_be | `eternal-host-be` | https://eternalhostapi.cozentus.com |
| codesmash-frontend | `codesmash-frontend` | https://codesmash.cozentus.com |
| codesmash-api | `codesmash-api` | https://codesmashapi.cozentus.com |
| hack-ims-frontend | `hack-ims-frontend` | https://dotnetcommando.cozentus.com |
| hack-ims-backend | `hack-ims-backend` | https://dotnetcommandoapi.cozentus.com |
| bitstorm-ui | `bitstorm-ui` | https://bitstorm.cozentus.com |
| bitstorm-api | `bitstorm-api` | https://bitstormapi.cozentus.com |
| kinetix-api-service | `kinetix-api-service` | https://kinetixapi.cozentus.com |
| kinetix-ui-service | `kinetix-ui-service` | https://kinetix.cozentus.com |
| ai-mavericks-ui | `ai-mavericks-ui` | https://aimavericks.cozentus.com |
| ai-mavericks-api | `ai-mavericks-api` | https://aimavericksapi.cozentus.com |
| patronus-global-help-desk | `patronus-global-help-desk` | https://patronus.cozentus.com |
| patronus-ai-support-investigator | `patronus-ai-support-investigator` | https://patronusapi.cozentus.com |
| patronus-target-application | `patronus-target-application` | https://patronus-target.cozentus.com |
| team-tesseract-backend | `team-tesseract-backend` | https://teamtesseractapi.cozentus.com |
| team-tesseract-ui | `team-tesseract-ui` | https://teamtesseract.cozentus.com |
| colorsweep-BE | `colorsweep-be` | https://colorsweepapi.cozentus.com |
| colorsweep-UI | `colorsweep-ui` | https://colorsweep.cozentus.com |

Until GoDaddy DNS is configured (DevOps handles this), your app is still reachable at the direct `*.run.app` URL shown in your deploy's Action log.

## Secrets (API keys, DB credentials, etc.)

You don't have GCP access, so you can't create these yourself. Tell DevOps what you need (env var name + value, sent privately, not in a group chat) and we'll create it in Secret Manager and wire it into your service. It shows up as a normal environment variable in your app — nothing to change in your code.

## eternal-host-worker (Celery background worker)

This is already provisioned as a dedicated **always-on** Cloud Run service (`eternal-host-worker`) — it does not scale to zero and is not reachable from the internet, it just keeps running your Celery worker process. To deploy it:

1. Add a second Dockerfile to `eternal_host_be`, e.g. `Dockerfile.worker`, with `CMD` running `celery -A myproject worker` instead of gunicorn (no `$PORT`/web server needed here).
2. Add a second caller workflow, e.g. `.github/workflows/deploy-worker.yml`:
   ```yaml
   name: Deploy Worker
   on:
     push:
       branches: [main]
     workflow_dispatch: {}
   jobs:
     deploy:
       uses: Cozentus-Technologies/hackathon-deploy/.github/workflows/deploy-cloud-run.yml@main
       with:
         service_name: eternal-host-worker
         dockerfile: Dockerfile.worker
   ```

## Notes

- Cold starts happen after idle periods (web services scale to zero) — the first request after a quiet spell takes a couple seconds longer.
- Database connectivity: DevOps is handling this separately — ping us once your app needs specific ports opened.
