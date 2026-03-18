# gitops

GitOps repository for the Astha platform. ArgoCD watches this repo and automatically syncs Kubernetes resources to the GKE cluster.

## How It Works

```
Service CI pushes new image tag to environments/<env>/<service>.yaml
  -> ArgoCD detects the change
    -> Renders Helm chart with new values
      -> Applies to GKE namespace
```

No one runs `kubectl apply` manually. All deployments go through this repo.

## Repository Structure

```
gitops/
  charts/
    microservice/          Shared Helm chart (Deployment, Service, ConfigMap, etc.)
      templates/
        deployment.yaml
        service.yaml
        configmap.yaml
        external-secret.yaml
        hpa.yaml
        ...
      values.yaml            Default values
      Chart.yaml

  environments/
    dev/                     Dev environment values (one file per service)
      authentication.yaml
      authorization.yaml
      user-management.yaml
      course.yaml
      notification.yaml
      questionnaires.yaml
      api-gateway.yaml
      ui-application.yaml
      values-global.yaml
    staging/                 Staging overrides
    production/              Production overrides

  argocd/
    applicationsets/
      platform-services.yaml   ApplicationSet for all microservices
      infrastructure.yaml      ApplicationSet for infra components
    projects/
      dev.yaml                 ArgoCD AppProject (RBAC, allowed resources)
      staging.yaml
      production.yaml

  infrastructure/
    databases/               StatefulSets for dev (Redis)
    gateway/                 Envoy/gateway config
    secrets/                 ExternalSecret cluster config
```

## Adding a New Service

1. Create `environments/dev/<service-name>.yaml`:

```yaml
serviceName: ms-my-new-service
image:
  repository: astha-platform/ms-my-new-service
  tag: "sha-abc1234"
config:
  APP_NAME: "ms-my-new-service"
  APP_PORT: "5000"
  APP_ENVIRONMENT: "development"
externalSecret:
  enabled: true
  secrets:
    - key: dev-postgres-my-new-service-url
      property: DATABASE_URL
```

2. The ApplicationSet auto-discovers it — no ArgoCD config changes needed.

## Updating a Service

Service CI does this automatically, but to do it manually:

```bash
# Update the image tag
yq -i '.image.tag = "sha-new1234"' environments/dev/authentication.yaml
git commit -am "deploy: authentication sha-new1234" && git push
```

ArgoCD syncs within ~3 minutes (or immediately if you click Sync in the UI).

## Environment Config

Each service YAML has three sections:

| Section | Purpose |
|---------|---------|
| `image` | Docker image repository and tag |
| `config` | Non-secret environment variables (injected via ConfigMap) |
| `externalSecret` | Secret references pulled from GCP Secret Manager via ESO |

Secrets are **never** stored in this repo. They live in GCP Secret Manager and are synced by External Secrets Operator.

## Helm Chart

All services share a single Helm chart (`charts/microservice/`). It provides:

- Deployment with rolling updates
- Service (ClusterIP)
- ConfigMap from `config` values
- ExternalSecret for pulling secrets from GCP SM
- HPA (optional)
- Startup/liveness/readiness probes
- Security hardening (readOnlyRootFilesystem, runAsNonRoot, tmpfs)

## Accessing ArgoCD UI

```bash
# Get admin password
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d

# Port-forward
kubectl port-forward svc/argocd-server -n argocd 8443:443

# Open https://localhost:8443 (user: admin)
```
