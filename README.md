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
| eternal_host_ui | `eternal-host-ui` | https://eternal-host-ui.hackathon.cozentus.com |
| eternal_host_be | `eternal-host-be` | https://eternal-host-be.hackathon.cozentus.com |
| codesmash-frontend | `codesmash-frontend` | https://codesmash-frontend.hackathon.cozentus.com |
| codesmash-api | `codesmash-api` | https://codesmash-api.hackathon.cozentus.com |
| hack-ims-frontend | `hack-ims-frontend` | https://hack-ims-frontend.hackathon.cozentus.com |
| hack-ims-backend | `hack-ims-backend` | https://hack-ims-backend.hackathon.cozentus.com |
| bitstorm-ui | `bitstorm-ui` | https://bitstorm-ui.hackathon.cozentus.com |
| bitstorm-api | `bitstorm-api` | https://bitstorm-api.hackathon.cozentus.com |
| kinetix-api-service | `kinetix-api-service` | https://kinetix-api-service.hackathon.cozentus.com |
| kinetix-ui-service | `kinetix-ui-service` | https://kinetix-ui-service.hackathon.cozentus.com |
| ai-mavericks-ui | `ai-mavericks-ui` | https://ai-mavericks-ui.hackathon.cozentus.com |
| ai-mavericks-api | `ai-mavericks-api` | https://ai-mavericks-api.hackathon.cozentus.com |
| patronus-global-help-desk | `patronus-global-help-desk` | https://patronus-global-help-desk.hackathon.cozentus.com |
| patronus-ai-support-investigator | `patronus-ai-support-investigator` | https://patronus-ai-support-investigator.hackathon.cozentus.com |
| patronus-target-application | `patronus-target-application` | https://patronus-target-application.hackathon.cozentus.com |
| team-tesseract-backend | `team-tesseract-backend` | https://team-tesseract-backend.hackathon.cozentus.com |
| team-tesseract-ui | `team-tesseract-ui` | https://team-tesseract-ui.hackathon.cozentus.com |
| colorsweep-BE | `colorsweep-be` | https://colorsweep-be.hackathon.cozentus.com |
| colorsweep-UI | `colorsweep-ui` | https://colorsweep-ui.hackathon.cozentus.com |

Until GoDaddy DNS is configured (DevOps handles this), your app is still reachable at the direct `*.run.app` URL shown in your deploy's Action log.

## Notes

- **eternal-host-be**: if you need a Celery worker, that doesn't fit this pipeline as-is (Cloud Run is request-driven) — talk to DevOps, we'll set up a dedicated always-on service for it.
- Cold starts happen after idle periods (services scale to zero) — the first request after a quiet spell takes a couple seconds longer.
- Database connectivity: DevOps is handling this separately — ping us once your app needs specific ports opened.
