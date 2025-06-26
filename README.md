# LiteLLM Kubernetes Deployment

This repository contains environment-specific configurations for deploying LiteLLM on Kubernetes using a two-repository approach.

## Repository Structure

### Chart Repository (Separate Repo)
```
helm-chart/                 # Reusable Helm chart for LiteLLM
├── Chart.yaml
├── values.yaml            # Default values only
└── templates/
```

### Deployment Repository (This Repo)
```
├── local/                      # Lokale Entwicklung
│   ├── manifests/             # Kubernetes Manifeste für lokales Testing
│   ├── scripts/               # Deployment Scripts
│   └── README.md
├── flux/                      # Flux HelmRelease configuration
│   └── helmrelease.yaml      # References external chart repository
├── configmaps/                # Environment-specific configurations
│   └── litellm-config.yaml
├── sealedsecrets/             # All secrets management (cluster only)
│   ├── litellm-api-keys-sealedsecret.yaml
│   ├── litellm-secrets-sealedsecret.yaml
│   └── litellm-db-credentials.yaml
├── scripts/                   # Übergreifende Scripts
│   └── deploy-kubectl.sh
└── README.md
```

## Prerequisites

- Kubernetes cluster
- Flux v2 installed
- Sealed Secrets controller
- Nginx Ingress Controller
- Cert-manager (for TLS)

## Deployment Steps

1. **Create namespace:**
   ```bash
   kubectl create namespace litellm
   ```

2. **Generate and apply sealed secrets:**
   ```bash
   # For API keys
   echo -n "sk-your-openai-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "sk-ant-your-anthropic-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "your-azure-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "https://your-resource.openai.azure.com/" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "your-google-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   
   # For admin auth
   echo -n "your-master-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-admin-auth --namespace=litellm
   echo -n "your-jwt-secret" | kubeseal --raw --from-file=/dev/stdin --name=litellm-admin-auth --namespace=litellm
   
   # For database credentials
   echo -n "strong-postgres-password" | kubeseal --raw --from-file=/dev/stdin --name=litellm-db-credentials --namespace=litellm
   echo -n "strong-user-password" | kubeseal --raw --from-file=/dev/stdin --name=litellm-db-credentials --namespace=litellm
   ```

3. **Apply configurations in order:**
   ```bash
   # Apply SealedSecrets first
   kubectl apply -f sealedsecrets/
   
   # Apply ConfigMaps
   kubectl apply -f configmaps/
   
   # Apply HelmRelease
   kubectl apply -f flux/
   ```

## Configuration Management

### Environment-Specific Files

- **`configmaps/litellm-config.yaml`**: Contains LiteLLM configuration with model definitions
- **`sealedsecrets/`**: All sensitive credentials encrypted with SealedSecrets
- **`flux/helmrelease.yaml`**: Deployment configuration referencing external chart

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

## Benefits of Two-Repository Approach

1. **Chart Reusability**: Helm chart can be used across multiple environments
2. **Security**: Secrets stay in deployment repository, never in chart repository
3. **Environment Isolation**: Each environment has its own deployment repository
4. **GitOps**: Clear separation of concerns for GitOps workflows
5. **Version Management**: Chart and deployment configurations can be versioned independently

## Troubleshooting

1. Check pod logs: `kubectl logs -n litellm deployment/litellm`
2. Verify secrets: `kubectl get secrets -n litellm`
3. Check HelmRelease status: `kubectl get helmrelease -n litellm`
4. Verify SealedSecrets: `kubectl get sealedsecrets -n litellm`
5. Check ConfigMaps: `kubectl get configmaps -n litellm`

## Azure Key Vault Setup

### Prerequisites
1. **External Secrets Operator** installed in cluster
2. **Azure Key Vault** with secrets stored
3. **Managed Identity** with Key Vault access

### Azure Key Vault Secrets

Store these secrets in your Azure Key Vault:
- `litellm-master-key`: Strong master key for LiteLLM
- `litellm-jwt-secret`: JWT signing secret
- `openai-api-key`: OpenAI API key
- `anthropic-api-key`: Anthropic API key
- `azure-openai-key`: Azure OpenAI API key
- `azure-openai-endpoint`: Azure OpenAI endpoint URL
- `google-ai-key`: Google AI Studio API key
- `postgres-admin-password`: PostgreSQL admin password
- `litellm-db-user-password`: LiteLLM database user password

### Deployment Steps

1. **Apply External Secrets:**
   ```bash
   kubectl apply -f flux/azure-keyvault-integration.yaml
   ```

2. **Apply ConfigMap:**
   ```bash
   kubectl apply -f configmaps/litellm-config.yaml
   ```

3. **Apply HelmRelease:**
   ```bash
   kubectl apply -f flux/helmrelease.yaml
   ```

4. **Create Admin Users manually via UI:**
   ```
   Login URL: https://litellm.yourdomain.com/ui
   ```

## User Management in Database

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
curl -X POST "https://litellm.yourdomain.com/user/new" \
  -H "Authorization: Bearer YOUR_MASTER_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "user_email": "admin@company.com",
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

### Vorteile der Database-Integration:
- 🔒 **Persistent Users** - Überleben Pod-Restarts
- 📊 **Usage Tracking** - Vollständige Logs und Analytics
- 👥 **Team Management** - Gruppen-basierte Zugriffskontrollen
- 💰 **Budget Controls** - Pro-User Spending Limits
- ⚡ **Rate Limiting** - Pro-User Request Limits
- 🔄 **API Key Management** - Rotation und Verwaltung

## Security Benefits

✅ **Secrets encrypted with SealedSecrets**  
✅ **GitOps-friendly secret management**  
✅ **Database for persistent user storage**  
✅ **4-6 Admin Users** mit eigenen Passwörtern und API Keys

## Deployment Optionen

### 1. Lokale Entwicklung (local/)
- Plain text secrets
- LoadBalancer service
- Reduzierte Resources
- Einfacher kubectl deploy

### 2. Cluster Deployment (flux/)
- SealedSecrets
- Ingress mit TLS
- Production Resources
- GitOps mit Flux
