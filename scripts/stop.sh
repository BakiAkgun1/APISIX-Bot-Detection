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

# Tüm APISIX route'larını temizle
echo "🛣️ Tüm APISIX route'ları temizleniyor..."
kubectl delete apisixroute --all --ignore-not-found=true

echo "✅ Uygulama başarıyla kapatıldı!"
echo "💡 Uygulamayı tekrar başlatmak için: ./scripts/start.sh"
