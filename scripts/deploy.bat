@echo off
REM Local deployment script for LiteLLM

echo 🚀 Deploying LiteLLM locally with kubectl...
echo.

REM Navigate to project root to access local-manifests
cd /d "%~dp0..\.."

REM 1. Namespace und Secrets erstellen
echo 📁 Creating namespace and secrets...
kubectl apply -f local-manifests/namespace.yaml
kubectl apply -f local-manifests/secrets.yaml

REM 2. PostgreSQL deployen
echo 🐘 Deploying PostgreSQL...
kubectl apply -f local-manifests/postgresql.yaml

REM 3. Kurz warten
echo ⏳ Waiting 30 seconds for PostgreSQL...
timeout /t 30 /nobreak

REM 4. LiteLLM deployen
echo 🤖 Deploying LiteLLM...
kubectl apply -f local-manifests/litellm.yaml

REM 5. Status prüfen
echo 📊 Checking deployment status...
kubectl get pods -n litellm
kubectl get svc -n litellm

echo.
echo ✅ Deployment completed!
echo.
echo 🔗 Access URLs:
echo - Port-forward: kubectl port-forward svc/litellm 4000:4000 -n litellm
echo - UI: http://localhost:4000/ui
echo - Master Key: sk-local-master-key-123
echo.
echo 🛠️ Useful commands:
echo - Logs: kubectl logs -n litellm deployment/litellm -f
echo - DB Access: kubectl exec -it deployment/postgres -n litellm -- psql -U litellm -d litellm
echo - Port-forward DB: kubectl port-forward svc/postgres 5432:5432 -n litellm
echo - Cleanup: kubectl delete namespace litellm

echo.
echo 🎯 Next steps:
echo 1. Run: kubectl port-forward svc/litellm 4000:4000 -n litellm
echo 2. Open: http://localhost:4000/ui
echo 3. Login with Master Key: sk-local-master-key-123

pause
