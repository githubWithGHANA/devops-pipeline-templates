# Gold Standard Deployment Template

Sanitized, reusable AWS CodePipeline → CodeBuild → CodeDeploy → Docker Compose template extracted from production repositories.

## Structure

```
devops-pipeline-templates/
├── README.md
├── setup-pipeline.sh
├── test-pipeline-locally.sh
├── .githooks/
│   └── pre-push
└── templates/
    └── [stack]/
        ├── Dockerfile
        ├── docker-compose.yml
        ├── buildspec.yml
        ├── appspec.yml
        └── scripts/
            ├── before_install.sh
            ├── after_install.sh
            ├── application_start.sh
            └── validate_service.sh
```

## Conventions extracted from production repos

- Destination on EC2: `/opt/<app-name>` (configurable via `setup-pipeline.sh`).
- CodeDeploy hooks run as `root`.
- ECR login uses `aws ecr get-login-password --region $AWS_DEFAULT_REGION | docker login --username AWS --password-stdin $ECR_REGISTRY`.
- Compose stacks are started with `docker compose up -d` and stopped with `docker compose down || true` before new revisions start.
- `validate_service.sh` loops against the real health endpoint and dumps `docker logs` on failure.
- `buildspec.yml` artifacts explicitly package `appspec.yml`, `docker-compose.yml`, `image_definition.env`, `scripts/**/*`, and `deploy.env*`.

## Quick start

```bash
./setup-pipeline.sh my-app /opt/my-app
./test-pipeline-locally.sh
```
