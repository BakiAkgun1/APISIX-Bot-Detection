#!/bin/bash

# ArgoCD Kurulum Script'i
echo "🚀 ArgoCD Kurulumu Başlıyor..."

# 1. ArgoCD namespace oluştur
echo "📁 ArgoCD namespace oluşturuluyor..."
kubectl create namespace argocd

# 2. ArgoCD kurulumu
echo "📦 ArgoCD kuruluyor..."
kubectl apply -n argocd -f https://raw.githubusercontent.com/argoproj/argo-cd/stable/manifests/install.yaml

# 3. Kurulum tamamlanana kadar bekle
echo "⏳ ArgoCD pod'ları başlatılıyor..."
kubectl wait --for=condition=available --timeout=300s deployment/argocd-server -n argocd

# 4. ArgoCD admin şifresini al
echo "🔑 ArgoCD admin şifresi:"
kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}" | base64 -d && echo

# 5. Port forward başlat
echo "🌐 ArgoCD UI port forward başlatılıyor..."
kubectl port-forward svc/argocd-server -n argocd 8081:443 &

echo "✅ ArgoCD kurulumu tamamlandı!"
echo "🌐 ArgoCD UI: https://localhost:8081"
echo "👤 Username: admin"
echo "🔑 Password: Yukarıdaki şifre"
echo ""
echo "📝 Sonraki adımlar:"
echo "1. ArgoCD UI'ya git: https://localhost:8081"
echo "2. Login ol (admin + yukarıdaki şifre)"
echo "3. New App oluştur"
echo "4. Repository: https://github.com/your-username/apisix-bot-routing"
echo "5. Path: k8s/"
echo "6. Sync et!"
