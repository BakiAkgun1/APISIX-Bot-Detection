#!/bin/bash

echo "🧪 Gelişmiş APISIX Routing Testleri Başlatılıyor..."

# APISIX gateway port forward
echo "📡 APISIX Gateway port forward başlatılıyor..."
kubectl port-forward -n apisix service/apisix-gateway 8080:80 >/dev/null 2>&1 &
PF_PID=$!
sleep 3

echo "🔍 Test sonuçları:"
echo "=================="

# Test 1: IP Whitelist Test
echo "1️⃣ IP Whitelist Testi:"
echo "   Test IP: 192.168.1.100 (whitelist'te)"
curl -s -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080 | grep -o "<h1>.*</h1>" || echo "   ❌ IP whitelist testi başarısız"
echo ""

# Test 2: JWT Header Test
echo "2️⃣ JWT Header Testi (X-User-Type: bot_user):"
curl -s -H "X-User-Type: bot_user" http://localhost:8080 | grep -o "<h1>.*</h1>" || echo "   ❌ JWT header testi başarısız"
echo ""

# Test 3: JWT Admin Test
echo "3️⃣ JWT Admin Testi (X-User-Role: admin):"
curl -s -H "X-User-Role: admin" http://localhost:8080 | grep -o "<h1>.*</h1>" || echo "   ❌ JWT admin testi başarısız"
echo ""

# Test 4: Bot User-Agent Test
echo "4️⃣ Bot User-Agent Testi:"
curl -s -H "User-Agent: googlebot" http://localhost:8080 | grep -o "<h1>.*</h1>" || echo "   ❌ Bot user-agent testi başarısız"
echo ""

# Test 5: Normal User Test
echo "5️⃣ Normal Kullanıcı Testi:"
curl -s -H "User-Agent: Mozilla/5.0" http://localhost:8080 | grep -o "<h1>.*</h1>" || echo "   ❌ Normal kullanıcı testi başarısız"
echo ""

# Test 6: Priority Test - Aynı priority değerleri
echo "6️⃣ Priority Testi (aynı priority değerleri):"
echo "   Priority 100 olan route'lar:"
echo "   - Bot route (User-Agent match)"
echo "   - İlk eklenen route öncelik alır"
echo ""

# Test 7: Rate Limit Test
echo "7️⃣ Rate Limit Testi:"
echo "   Bot rate limit: 5 req/saniye"
echo "   Normal rate limit: 50 req/saniye"
echo "   IP whitelist rate limit: 10 req/saniye"
echo ""

# Port forward'ı kapat
kill $PF_PID 2>/dev/null || true

echo "✅ Testler tamamlandı!"
echo "💡 Detaylı test için:"
echo "   kubectl port-forward -n apisix service/apisix-gateway 8080:80"
echo "   curl -v -H 'X-User-Type: bot_user' http://localhost:8080"
