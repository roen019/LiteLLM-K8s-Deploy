# LiteLLM Kubernetes Deployment

This repository contains environment-specific configurations for deploying LiteLLM on Kubernetes.

## Repository Structure

```
├── local-manifests/           # Local development with kubectl
│   ├── namespace.yaml
│   ├── secrets.yaml          # Plain text secrets for local testing
│   ├── postgresql.yaml       # PostgreSQL for local development
│   └── litellm.yaml         # LiteLLM deployment manifest
├── helm-chart/               # Helm chart for LiteLLM
│   ├── Chart.yaml
│   ├── values.yaml
│   └── templates/
├── flux/                     # Flux GitOps configuration
│   ├── helmrelease.yaml     # Production deployment
│   └── helmrelease-local.yaml
├── configmaps/               # Environment-specific configurations
│   └── litellm-config.yaml
├── sealed-secrets/           # Encrypted secrets for production
│   ├── litellm-api-keys-sealedsecret.yaml
│   ├── litellm-secrets-sealedsecret.yaml
│   └── litellm-db-credentials.yaml
└── scripts/                 # Deployment scripts
    ├── deploy.bat          # Windows deployment script
    ├── deploy-kubectl.sh   # Unix deployment script
    └── database-queries.sql
```

## Prerequisites

- Kubernetes cluster
- Flux v2 installed (for GitOps deployment)
- Sealed Secrets controller (for production)
- Nginx Ingress Controller
- Cert-manager (for TLS)

## Deployment Steps

### Local Development

1. **Quick deployment with kubectl:**
   ```bash
   # Windows
   scripts\deploy.bat
   
   # Unix/Linux
   chmod +x scripts/deploy-kubectl.sh
   ./scripts/deploy-kubectl.sh
   ```

2. **Manual deployment:**
   ```bash
   kubectl apply -f local-manifests/namespace.yaml
   kubectl apply -f local-manifests/secrets.yaml
   kubectl apply -f local-manifests/postgresql.yaml
   kubectl apply -f local-manifests/litellm.yaml
   ```

3. **Access the application:**
   ```bash
   kubectl port-forward svc/litellm 4000:4000 -n litellm
   # Open: http://localhost:4000/ui
   # Master Key: sk-local-master-key-123
   ```

### Production Deployment

1. **Create namespace:**
   ```bash
   kubectl create namespace litellm
   ```

2. **Apply configurations in order:**
   ```bash
   # Apply SealedSecrets first
   kubectl apply -f sealed-secrets/
   
   # Apply ConfigMaps
   kubectl apply -f configmaps/
   
   # Apply HelmRelease
   kubectl apply -f flux/
   ```

## Configuration Management

### Environment-Specific Files

- **`configmaps/litellm-config.yaml`**: Contains LiteLLM configuration with model definitions
- **`sealed-secrets/`**: All sensitive credentials encrypted with SealedSecrets
- **`flux/helmrelease.yaml`**: Production deployment configuration
- **`local-manifests/`**: Local development manifests with plain text secrets

### Secret Structure

- **API Keys (`litellm-api-keys`)**:
  - `openai-api-key`: OpenAI API key (sk-...)
  - `anthropic-api-key`: Anthropic API key (sk-ant-...)
  - `azure-api-key`: Azure OpenAI API key
  - `azure-api-base`: Azure OpenAI endpoint URL
  - `google-api-key`: Google AI Studio API key

- **Admin Authentication (`litellm-admin-auth`)**:
  - `master-key`: Master key for API access
  - `jwt-secret`: JWT signing secret

- **Database Credentials (`litellm-db-credentials`)**:
  - `postgres-password`: PostgreSQL admin password
  - `user-password`: LiteLLM database user password

### Environment Variables (Auto-mapped)

- `OPENAI_API_KEY`
- `ANTHROPIC_API_KEY`
- `AZURE_API_KEY`
- `AZURE_API_BASE`
- `GOOGLE_API_KEY`
- `LITELLM_MASTER_KEY`
- `ADMIN_EMAIL`
- `ADMIN_PASSWORD`

## Troubleshooting

1. Check pod logs: `kubectl logs -n litellm deployment/litellm`
2. Verify secrets: `kubectl get secrets -n litellm`
3. Check HelmRelease status: `kubectl get helmrelease -n litellm`
4. Verify SealedSecrets: `kubectl get sealedsecrets -n litellm`
5. Check ConfigMaps: `kubectl get configmaps -n litellm`


### Deployment Steps

1. **Apply ConfigMap:**
   ```bash
   kubectl apply -f configmaps/litellm-config.yaml
   ```

2. **Apply HelmRelease:**
   ```bash
   kubectl apply -f flux/helmrelease.yaml
   ```

3. **Create Admin Users manually via UI:**
   ```
   Login URL: https://litellm.example.com/ui
   ```

### User Management in Database

### Automatische Speicherung
Wenn PostgreSQL aktiviert ist, speichert LiteLLM automatisch alle User-Daten:

**Gespeicherte Informationen:**
- ✅ **User Email & Password** (gehashed)
- ✅ **API Keys** (generiert und persistent)
- ✅ **User Roles** (proxy_admin, internal_user, etc.)
- ✅ **Teams & Permissions**
- ✅ **Usage Statistics & Logs**
- ✅ **Rate Limits & Budgets**

### Database Tabellen
LiteLLM erstellt automatisch diese Tabellen:
- `litellm_users` - User-Informationen
- `litellm_keys` - API Keys
- `litellm_teams` - Team-Management
- `litellm_usage` - Usage Logs
- `litellm_budgets` - Budget & Limits

### User über UI erstellen:
1. **Login** mit Master Key oder Admin Account
2. **Navigate** zu "Users" → "Add New User"
3. **Eingeben:**
   - Email Address
   - Password
   - User Role (proxy_admin für Admin-Rechte)
   - Optional: Teams, Budgets, Rate Limits

### User über API erstellen:
```bash
# Admin User erstellen
curl -X POST "https://litellm.example.com/user/new" \
  -H "Authorization: Bearer YOUR_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_email": "admin@example.com",
    "user_role": "proxy_admin",
    "password": "SecurePassword123!",
    "max_budget": 100.0,
    "tpm_limit": 10000,
    "rpm_limit": 100
  }'
```

### Database Zugriff (für Troubleshooting):
```bash
# PostgreSQL Shell
kubectl exec -it litellm-postgresql-0 -n litellm -- psql -U litellm -d litellm

# User anzeigen
SELECT user_email, user_role, created_at FROM litellm_users;

# API Keys anzeigen
SELECT key_name, user_id, created_at, expires FROM litellm_keys;
```

## Deployment Optionen

### 1. Lokale Entwicklung (local-manifests/)
- Plain text secrets
- LoadBalancer service
- Reduzierte Resources
- Einfacher kubectl deploy

### 2. Cluster Deployment (flux/)
- SealedSecrets
- Ingress mit TLS
- Production Resources
- GitOps mit Flux
- Ingress mit TLS
- Production Resources
- GitOps mit Flux
### 2. Cluster Deployment (flux/)
- SealedSecrets
- Ingress mit TLS
- Production Resources
- GitOps mit Flux
