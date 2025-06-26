#!/bin/bash

echo "🚀 Deploying LiteLLM with kubectl (no Helm needed)..."

# Namespace und Secrets
kubectl apply -f local/manifests/namespace.yaml
kubectl apply -f local/manifests/secrets.yaml

# PostgreSQL
kubectl apply -f local/manifests/postgresql.yaml

# Warten bis PostgreSQL ready ist
echo "⏳ Waiting for PostgreSQL..."
kubectl wait --for=condition=ready pod -l app=postgres -n litellm --timeout=300s

# LiteLLM
kubectl apply -f local/manifests/litellm.yaml

# Warten bis LiteLLM ready ist
echo "⏳ Waiting for LiteLLM..."
kubectl wait --for=condition=ready pod -l app=litellm -n litellm --timeout=300s

echo "✅ Deployment completed!"
echo ""
echo "🔗 Access URLs:"
echo "- Port-forward: kubectl port-forward svc/litellm 4000:4000 -n litellm"
echo "- UI: http://localhost:4000/ui"
echo "- Master Key: sk-local-master-key-123"
echo ""
echo "📊 Status Commands:"
echo "- Pods: kubectl get pods -n litellm"
echo "- Services: kubectl get svc -n litellm"
echo "- Logs: kubectl logs -n litellm deployment/litellm"
echo "- Database: kubectl exec -it deployment/postgres -n litellm -- psql -U litellm -d litellm"
echo "- Cleanup: kubectl delete namespace litellm"
