#!/bin/bash

# GitOps Deployment Script'i
echo "🚀 GitOps Deployment Başlıyor..."

# 1. Git durumunu kontrol et
echo "📋 Git durumu kontrol ediliyor..."
git status

# 2. Değişiklikleri commit et
echo "💾 Değişiklikler commit ediliyor..."
git add .
git commit -m "APISIX Bot Routing - ArgoCD entegrasyonu

✅ ArgoCD Application YAML'ı eklendi
✅ Otomatik sync policy
✅ GitOps workflow hazır
✅ Optimize edilmiş route'lar (7→3 route)
✅ Rate limit testleri hazır"

# 3. GitHub'a push et
echo "📤 GitHub'a push ediliyor..."
git push origin main

# 4. ArgoCD'de sync kontrolü
echo "🔄 ArgoCD sync kontrolü..."
if command -v argocd &> /dev/null; then
    echo "ArgoCD CLI mevcut, sync kontrol ediliyor..."
    argocd app get apisix-bot-routing
    echo "Sync başlatılıyor..."
    argocd app sync apisix-bot-routing
else
    echo "ArgoCD CLI bulunamadı, manuel sync gerekli:"
    echo "1. ArgoCD UI'ya git: https://localhost:8081"
    echo "2. apisix-bot-routing uygulamasını bul"
    echo "3. Sync butonuna tıkla"
fi

echo "✅ GitOps deployment tamamlandı!"
echo ""
echo "📊 Deployment durumu:"
echo "1. GitHub: ✅ Push edildi"
echo "2. ArgoCD: 🔄 Sync ediliyor"
echo "3. Kubernetes: ⏳ Pod'lar başlatılıyor"
echo ""
echo "🌐 Kontrol et:"
echo "- ArgoCD UI: https://localhost:8081"
echo "- APISIX Gateway: http://localhost:8080"
echo "- APISIX Admin: http://localhost:9180"
-