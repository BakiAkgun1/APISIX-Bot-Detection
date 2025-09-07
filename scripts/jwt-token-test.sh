#!/bin/bash

# JWT Token Test Script'i
echo "🔐 JWT Token Authentication Test"
echo "================================"

# JWT Token'ları oluştur (Base64 encoded)
echo "📝 JWT Token'ları oluşturuluyor..."

# Admin Token (HS256)
ADMIN_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJhZG1pbi11c2VyIiwicm9sZSI6ImFkbWluIiwibmFtZSI6IkFkbWluIFVzZXIiLCJpYXQiOjE1MTYyMzkwMjJ9.abc123"

# Bot Token (HS256)
BOT_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJib3QtdXNlciIsInR5cGUiOiJib3RfdXNlciIsIm5hbWUiOiJCb3QgVXNlciIsImlhdCI6MTUxNjIzOTAyMn0.def456"

# Normal Token (HS256)
NORMAL_TOKEN="eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJrZXkiOiJub3JtYWwtdXNlciIsInJvbGUiOiJub3JtYWwiLCJuYW1lIjoiTm9ybWFsIFVzZXIiLCJpYXQiOjE1MTYyMzkwMjJ9.ghi789"

echo "✅ Token'lar hazır!"
echo ""

# Test fonksiyonu
test_jwt_route() {
    local test_name="$1"
    local token="$2"
    local expected_backend="$3"
    
    echo "🧪 $test_name Testi"
    echo "   Token: ${token:0:50}..."
    echo "   Beklenen Backend: $expected_backend"
    echo ""
    
    # İstek gönder
    response=$(curl -s -H "Authorization: Bearer $token" http://localhost:8080 2>/dev/null)
    
    if echo "$response" | grep -q "Portal Bot Sayfası"; then
        echo "   ✅ Bot Sayfası (portal-svc-bot)"
    elif echo "$response" | grep -q "Portal Ana Sayfa"; then
        echo "   ✅ Normal Sayfa (portal-svc)"
    elif echo "$response" | grep -q "401"; then
        echo "   ❌ Authentication Failed (401)"
    else
        echo "   ❌ Bilinmeyen yanıt"
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
echo "🎯 JWT Token Testleri"
echo "===================="

test_jwt_route "Admin Token" "$ADMIN_TOKEN" "portal-svc"
test_jwt_route "Bot Token" "$BOT_TOKEN" "portal-svc-bot"
test_jwt_route "Normal Token" "$NORMAL_TOKEN" "portal-svc"

echo "🎉 JWT Token testleri tamamlandı!"
echo ""
echo "💡 Gerçek JWT token'ları için:"
echo "   https://jwt.io/ adresini kullanabilirsin"
echo "   Secret key'leri consumer'larda tanımlı"

