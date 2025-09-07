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
kubectl apply -f k8s/jwt-decode-routing.yaml

# JWT Consumer'ları uygula
echo "🔐 JWT Consumer'ları uygulanıyor..."
kubectl apply -f k8s/jwt-consumers.yaml

echo "⏳ Route'ların aktif olması bekleniyor..."
sleep 5

echo "✅ Uygulama başarıyla başlatıldı!"
echo ""
echo "🧪 Test etmek için:"
echo "   # Port forward başlat"
echo "   kubectl port-forward -n apisix service/apisix-gateway 8080:80 &"
echo "   kubectl port-forward -n apisix service/apisix-admin 9180:9180 &"
echo ""
echo "   # Test komutları"
echo "   curl -H 'User-Agent: Bot' http://localhost:8080"
echo "   curl -H 'X-User-Role: admin' http://localhost:8080"
echo "   curl -H 'X-Forwarded-For: 192.168.1.100' http://localhost:8080"
echo ""
echo "   # Tüm testleri çalıştır"
echo "   ./scripts/test-all-routes.sh"
echo ""
echo "💡 Uygulamayı kapatmak için: ./scripts/stop.sh"
