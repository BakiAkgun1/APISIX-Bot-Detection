#!/bin/bash

echo "🧪 APISIX Bot Routing Test Ediliyor..."

# Port forward başlat
echo "📡 APISIX Gateway port forward başlatılıyor..."
kubectl port-forward -n apisix service/apisix-gateway 8080:80 >/dev/null 2>&1 &
PF_PID=$!

# Port forward'ın hazır olması için bekle
sleep 5

echo "✅ Test başlıyor..."
echo ""

# Normal kullanıcı testi
echo "🌟 Normal Kullanıcı Testi:"
echo "HTTP Response:"
curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://localhost:8080 | head -5
echo ""

# Bot kullanıcı testi
echo "🤖 Bot Kullanıcı Testi:"
echo "HTTP Response:"
curl -s -H "User-Agent: googlebot/2.1" http://localhost:8080 | head -5
echo ""

# Rate limit testi
echo "⚡ Rate Limit Testi:"
for i in {1..6}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "User-Agent: googlebot" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  RATE LIMITED!"
  fi
  sleep 0.3
done

echo ""
echo "✅ Test tamamlandı!"

# Port forward'ı kapat
kill $PF_PID 2>/dev/null || true

echo "💡 Uygulamayı kapatmak için: ./scripts/stop.sh"
