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

# APISIX route'larını ekle
echo "🛣️ APISIX route'ları kuruluyor..."
kubectl port-forward -n apisix service/apisix-admin 9180:9180 >/dev/null 2>&1 &
PF_PID=$!

# Route'ların eklenmesi için bekle
sleep 3

# Bot route ekle
echo "🤖 Bot route ekleniyor..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/*",
    "priority": 100,
    "vars": [["http_user_agent", "~~", ".*(bot|crawler|spider|scraper|googlebot|bingbot).*"]],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc-bot.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "limit-req": {
        "rate": 5,
        "burst": 10,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429,
        "rejected_msg": "Bot rate limit exceeded",
        "nodelay": true
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/1

# Normal route ekle
echo "🌟 Normal route ekleniyor..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/*",
    "priority": 50,
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "limit-req": {
        "rate": 50,
        "burst": 100,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/2

# Port forward'ı kapat
kill $PF_PID 2>/dev/null || true

echo "✅ Uygulama başarıyla başlatıldı!"
echo "🧪 Test etmek için:"
echo "   kubectl port-forward -n apisix service/apisix-gateway 8080:80 &"
echo "   curl -H 'User-Agent: googlebot' http://localhost:8080"
echo "💡 Uygulamayı kapatmak için: ./scripts/stop.sh"
