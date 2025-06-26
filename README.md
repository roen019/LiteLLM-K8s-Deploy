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
├── flux/                   # Flux HelmRelease configuration
│   └── helmrelease.yaml   # References external chart repository
├── configmaps/             # Environment-specific configurations
│   └── litellm-config.yaml
├── sealedsecrets/          # All secrets management
│   ├── litellm-api-keys.yaml
│   └── litellm-admin-auth.yaml
└── README.md
```

## Prerequisites

- Kubernetes cluster
- Flux v2 installed
- Sealed Secrets controller
- Nginx Ingress Controller
- Cert-manager (for TLS)
- Access to LiteLLM Helm chart repository

## Deployment Steps

1. **Create namespace:**
   ```bash
   kubectl create namespace litellm
   ```

2. **Add Helm repository (if using Helm repository):**
   ```bash
   helm repo add litellm-charts https://your-chart-repo.com/
   ```

3. **Generate and apply sealed secrets:**
   ```bash
   # For API keys
   echo -n "sk-your-openai-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "sk-ant-your-anthropic-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "your-azure-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "https://your-resource.openai.azure.com/" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   echo -n "your-google-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-api-keys --namespace=litellm
   
   # For admin auth
   echo -n "your-master-key" | kubeseal --raw --from-file=/dev/stdin --name=litellm-admin-auth --namespace=litellm
   echo -n "admin@yourcompany.com" | kubeseal --raw --from-file=/dev/stdin --name=litellm-admin-auth --namespace=litellm
   echo -n "your-admin-password" | kubeseal --raw --from-file=/dev/stdin --name=litellm-admin-auth --namespace=litellm
   ```

4. **Apply configurations in order:**
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
  - `admin-email`: Admin email for UI login
  - `admin-password`: Admin password for UI login
  - `jwt-secret`: JWT signing secret

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
