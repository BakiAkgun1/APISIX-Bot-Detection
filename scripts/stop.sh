#!/bin/bash

echo "🛑 APISIX Bot Routing Uygulaması Kapatılıyor..."

# Port forward'ları kapat
echo "📡 Port forward işlemleri kapatılıyor..."
pkill -f port-forward 2>/dev/null || echo "Port forward işlemi bulunamadı"

# Portal servislerini sil
echo "🚪 Portal servisleri kapatılıyor..."
kubectl delete -f k8s/portal-svc.yaml --ignore-not-found=true
kubectl delete -f k8s/portal-svc-bot.yaml --ignore-not-found=true

# Gelişmiş routing konfigürasyonlarını sil
echo "🛣️ Gelişmiş routing konfigürasyonları kapatılıyor..."
kubectl delete -f k8s/advanced-bot-routing.yaml --ignore-not-found=true
kubectl delete -f k8s/simple-jwt-routing.yaml --ignore-not-found=true

# APISIX route'larını temizle (eğer admin API erişilebilirse)
echo "🛣️ APISIX route'ları temizleniyor..."
kubectl port-forward -n apisix service/apisix-admin 9180:9180 >/dev/null 2>&1 &
PF_PID=$!

# Route'ları silmeye çalış
sleep 3
if curl -s -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes/1 >/dev/null 2>&1; then
    echo "Bot route siliniyor..."
    curl -X DELETE -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes/1 >/dev/null 2>&1
fi

if curl -s -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes/2 >/dev/null 2>&1; then
    echo "Normal route siliniyor..."
    curl -X DELETE -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes/2 >/dev/null 2>&1
fi

# Port forward'ı kapat
kill $PF_PID 2>/dev/null || true

echo "✅ Uygulama başarıyla kapatıldı!"
echo "💡 Uygulamayı tekrar başlatmak için: ./scripts/start.sh"
