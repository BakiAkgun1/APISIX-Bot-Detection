#!/bin/bash

echo "🚀 APISIX Bot Routing Uygulaması Başlatılıyor..."

# APISIX namespace kontrolü
if ! kubectl get namespace apisix >/dev/null 2>&1; then
    echo "❌ APISIX namespace bulunamadı!"
    echo "💡 Önce APISIX'i kurun: helm install apisix apisix/apisix --namespace apisix --values apisix-working-values.yaml"
    exit 1
fi

# Portal servislerini başlat
echo "🚪 Portal servisleri başlatılıyor..."
kubectl apply -f k8s/portal-svc.yaml
kubectl apply -f k8s/portal-svc-bot.yaml

# Pod'ların hazır olmasını bekle
echo "⏳ Pod'ların hazır olması bekleniyor..."
kubectl wait --for=condition=ready pod --all --timeout=120s

if [ $? -eq 0 ]; then
    echo "✅ Portal servisleri başarıyla başlatıldı!"
else
    echo "❌ Pod'lar başlatılamadı!"
    exit 1
fi

# Gelişmiş routing konfigürasyonunu uygula
echo "🛣️ Gelişmiş APISIX routing konfigürasyonu uygulanıyor..."
kubectl apply -f k8s/advanced-bot-routing.yaml
kubectl apply -f k8s/simple-jwt-routing.yaml

echo "⏳ Route'ların aktif olması bekleniyor..."
sleep 5

# Port forward'ı kapat
kill $PF_PID 2>/dev/null || true

echo "✅ Uygulama başarıyla başlatıldı!"
echo "🧪 Test etmek için:"
echo "   kubectl port-forward -n apisix service/apisix-gateway 8080:80 &"
echo "   curl -H 'User-Agent: googlebot' http://localhost:8080"
echo "💡 Uygulamayı kapatmak için: ./scripts/stop.sh"
