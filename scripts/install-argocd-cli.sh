#!/bin/bash

# ArgoCD CLI Kurulum Script'i
echo "🚀 ArgoCD CLI Kurulumu Başlıyor..."

# 1. ArgoCD CLI indir
echo "📥 ArgoCD CLI indiriliyor..."
curl -sSL -o argocd-linux-amd64 https://github.com/argoproj/argo-cd/releases/latest/download/argocd-linux-amd64

# 2. Executable yap
echo "🔧 Executable yapılıyor..."
chmod +x argocd-linux-amd64

# 3. /usr/local/bin'e taşı
echo "📁 /usr/local/bin'e taşınıyor..."
sudo mv argocd-linux-amd64 /usr/local/bin/argocd

# 4. Kurulum kontrolü
echo "✅ Kurulum kontrolü..."
argocd version --client

echo "🎉 ArgoCD CLI kurulumu tamamlandı!"
echo ""
echo "📝 Kullanım:"
echo "1. ArgoCD server'a bağlan:"
echo "   argocd login localhost:8081"
echo ""
echo "2. Application oluştur:"
echo "   argocd app create apisix-bot-routing \\"
echo "     --repo https://github.com/BakiAkgun1/APISIX-Bot-Detection.git \\"
echo "     --path k8s \\"
echo "     --dest-server https://kubernetes.default.svc \\"
echo "     --dest-namespace default \\"
echo "     --sync-policy automated"
echo ""
echo "3. Application durumunu kontrol et:"
echo "   argocd app get apisix-bot-routing"
echo ""
echo "4. Sync et:"
echo "   argocd app sync apisix-bot-routing"
