#!/bin/bash

# JWT Token Decode Test Script
echo "🔐 JWT Token Decode Test"
echo "========================"

# JWT Decode endpoint'ini test et
echo "📝 JWT Decode endpoint'i test ediliyor..."

# Test JWT Token (gerçek JWT formatında)
TEST_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoidGVzdHVzZXIiLCJzdWIiOiIxMjM0NTY3ODkwIiwiaWF0IjoxNTE2MjM5MDIyLCJhZG1pbiI6ZmFsc2V9.SflKxwRJSMeKKF2QT4fwpMeJf36POk6yJV_adQssw5c"
ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiYWRtaW5fdXNlciIsInN1YiI6ImFkbWluIiwiaWF0IjoxNTE2MjM5MDIyLCJhZG1pbiI6dHJ1ZX0.example"
BOT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJuYW1lIjoiYm90X3VzZXIiLCJzdWIiOiJib3QiLCJpYXQiOjE1MTYyMzkwMjIsImFkbWluIjpmYWxzZX0.example"

echo "✅ Token'lar hazır!"
echo ""

# Test fonksiyonu
# JWT Decode endpoint test fonksiyonu
test_jwt_decode() {
    local test_name="$1"
    local token="$2"
    
    echo "🧪 $test_name"
    echo "   Token: ${token:0:50}..."
    echo ""
    
    # JWT Decode endpoint'ine istek gönder
    response=$(curl -s -H "Authorization: Bearer $token" http://localhost:8080/jwt-decode 2>/dev/null)
    
    if echo "$response" | grep -q '"success":true'; then
        echo "   ✅ JWT Decode Başarılı"
        echo "   User Type: $(echo "$response" | grep -o '"user_type":"[^"]*"' | cut -d'"' -f4)"
        echo "   Is Bot: $(echo "$response" | grep -o '"is_bot":[^,}]*' | cut -d':' -f2)"
    else
        echo "   ❌ JWT Decode Başarısız"
        echo "   Response: $response"
    fi
    
    echo ""
}

# Normal routing test fonksiyonu
test_normal_routing() {
    echo "🧪 Normal Routing Testi"
    echo ""
    
    # Normal browser User-Agent ile test
    response=$(curl -s -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" http://localhost:8080 2>/dev/null)
    
    if echo "$response" | grep -q "Portal Ana Sayfa"; then
        echo "   ✅ Normal Sayfa (portal-svc) - Yeşil Arka Plan"
    elif echo "$response" | grep -q "Portal Bot Sayfası"; then
        echo "   ❌ Bot Sayfası (portal-svc-bot) - Kırmızı Arka Plan"
    else
        echo "   ❌ Bilinmeyen yanıt: ${response:0:100}..."
    fi
    
    echo ""
}

# Bot routing test fonksiyonu
test_bot_routing() {
    echo "🧪 Bot Routing Testi"
    echo ""
    
    # Bot User-Agent ile test
    response=$(curl -s -H "User-Agent: Bot" http://localhost:8080 2>/dev/null)
    
    if echo "$response" | grep -q "Portal Bot Sayfası"; then
        echo "   ✅ Bot Sayfası (portal-svc-bot) - Kırmızı Arka Plan"
    elif echo "$response" | grep -q "Portal Ana Sayfa"; then
        echo "   ❌ Normal Sayfa (portal-svc) - Yeşil Arka Plan"
    else
        echo "   ❌ Bilinmeyen yanıt: ${response:0:100}..."
    fi
    
    echo ""
}

# Port kontrolü
echo "🔍 Port kontrolü yapılıyor..."
if ! curl -s http://localhost:8080 > /dev/null; then
    echo "❌ HATA: localhost:8080 erişilemiyor!"
    echo "   Port forward'ları başlattığınızdan emin olun:"
    echo "   kubectl port-forward -n apisix service/apisix-gateway 8080:80 &"
    exit 1
fi
echo "✅ Port 8080 erişilebilir"
echo ""

# Testleri çalıştır
echo "🎯 APISIX Bot Routing Testleri"
echo "==============================="

# JWT Decode testleri
echo "1️⃣ JWT Decode Endpoint Testleri"
echo "--------------------------------"
test_jwt_decode "Normal User Token" "$TEST_TOKEN"
test_jwt_decode "Admin User Token" "$ADMIN_TOKEN"
test_jwt_decode "Bot User Token" "$BOT_TOKEN"

# Routing testleri
echo "2️⃣ Routing Testleri"
echo "-------------------"
test_normal_routing
test_bot_routing

echo "🎉 Tüm testler tamamlandı!"
echo ""
echo "💡 Not:"
echo "   - Normal kullanıcılar YEŞİL sayfayı görmeli"
echo "   - Bot'lar KIRMIZI sayfayı görmeli"
echo "   - JWT decode endpoint /jwt-decode'da çalışıyor"

