#!/bin/bash

# APISIX Manual Route Creation Script - FIXED VERSION
# Bu script tüm route'ları manuel olarak oluşturur

echo "=== APISIX MANUAL ROUTE CREATION (FIXED) ==="

# Önce tüm route'ları sil
echo "Deleting all existing routes..."
curl -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes | jq -r '.list | keys[]' | while read route_id; do
  echo "Deleting route: $route_id"
  curl -X DELETE -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes/$route_id
done

sleep 2

# 1. Bot Route (User-Agent ile) - Priority 100
echo "Creating Bot Route (Priority 100)..."
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
      "limit-count": {
        "count": 2,
        "time_window": 1,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429,
        "rejected_msg": "Bot rate limit exceeded (2 req/s)",
        "policy": "local"
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/1

echo ""

# 2. IP Whitelist Route - Priority 150
echo "Creating IP Whitelist Route (Priority 150)..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/*",
    "priority": 150,
    "vars": [["http_x_forwarded_for", "~~", "^(192\\.168\\.1\\.100|10\\.0\\.0\\.50|172\\.16\\.0\\.25|203\\.0\\.113\\.10)$"]],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc-bot.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "limit-count": {
        "count": 5,
        "time_window": 1,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429,
        "rejected_msg": "IP whitelist rate limit exceeded (5 req/s)",
        "policy": "local"
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/2

echo ""

# 3. JWT Normal Route - Priority 200
echo "Creating JWT Normal Route (Priority 200)..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/jwt-auth",
    "priority": 200,
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "serverless-pre-function": {
        "functions": [
          "return function(conf, ctx) local core = require(\"apisix.core\") local jwt = require(\"resty.jwt\") local token = core.request.header(ctx, \"authorization\") if not token then core.response.exit(400, {success = false, message = \"No JWT token found\"}) return end token = string.gsub(token, \"^Bearer \", \"\") token = string.gsub(token, \"^bearer \", \"\") local jwt_obj = jwt:load_jwt(token) if not jwt_obj or not jwt_obj.valid or not jwt_obj.payload then core.response.exit(400, {success = false, message = \"Invalid JWT token\"}) return end local payload = jwt_obj.payload local username = payload.name or \"unknown\" local sub = payload.sub or \"unknown\" local admin = payload.admin or false local bot_users = {[\"bot_user\"] = true, [\"testuser\"] = true, [\"admin_user\"] = true, [\"bot\"] = true} local user_type = \"normal\" if bot_users[username] or bot_users[sub] then user_type = \"bot\" end core.request.set_header(ctx, \"X-User-Type\", user_type) core.request.set_header(ctx, \"X-Username\", username) core.log.info(\"JWT User Type: \" .. user_type .. \" Username: \" .. username) end"
        ],
        "phase": "access"
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/3

echo ""

# 4. JWT Bot Route - Priority 250
echo "Creating JWT Bot Route (Priority 250)..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/jwt-auth",
    "priority": 250,
    "vars": [["http_x_user_type", "==", "bot"]],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc-bot.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "limit-count": {
        "count": 2,
        "time_window": 1,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429,
        "rejected_msg": "Bot JWT rate limit exceeded (2 req/s)",
        "policy": "local"
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/4

echo ""

# 5. Normal User Route - Priority 50 (En düşük)
echo "Creating Normal User Route (Priority 50)..."
curl -X PUT \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{
    "uri": "/*",
    "priority": 50,
    "vars": [["http_user_agent", "~~", "Mozilla"]],
    "upstream": {
      "type": "roundrobin",
      "nodes": {
        "portal-svc.default.svc.cluster.local:80": 1
      }
    },
    "plugins": {
      "limit-count": {
        "count": 10,
        "time_window": 1,
        "key": "remote_addr",
        "key_type": "var",
        "rejected_code": 429,
        "rejected_msg": "Normal user rate limit exceeded (10 req/s)",
        "policy": "local"
      }
    }
  }' \
  http://localhost:9180/apisix/admin/routes/5

echo ""

echo "=== ROUTE CREATION COMPLETED ==="

# Route'ları kontrol et
echo "=== CHECKING ROUTES ==="
curl -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" http://localhost:9180/apisix/admin/routes | jq '.list | to_entries[] | {id: .key, uri: .value.value.uri, priority: .value.value.priority, upstream: .value.value.upstream}'

echo ""
echo "=== TESTING ROUTES ==="

# Bot test
echo "=== BOT TEST ==="
curl -H "User-Agent: googlebot" http://localhost:8080

echo ""

# Normal user test
echo "=== NORMAL USER TEST ==="
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36" http://localhost:8080

echo ""

# IP whitelist test
echo "=== IP WHITELIST TEST ==="
curl -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080

echo ""

# JWT Normal user test
echo "=== JWT NORMAL USER TEST ==="
curl --request POST 'localhost:8080/jwt-auth' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiIxMjM0NTY3ODkwIiwibmFtZSI6IkpvaG4gRG9lIiwiYWRtaW4iOnRydWUsImlhdCI6MTUxNjIzOTAyMn0.KMUFsIDTnFmyG3nMiGM6H9FNFUROf3wh7SmqJp-QV30'

echo ""

# JWT Bot user test
echo "=== JWT BOT USER TEST ==="
curl --request POST 'localhost:8080/jwt-auth' \
--header 'Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJzdWIiOiJib3RfdXNlciIsIm5hbWUiOiJib3RfdXNlciIsImFkbWluIjpmYWxzZSwiaWF0IjoxNTE2MjM5MDIyfQ.example_signature'

echo ""
echo "=== ALL TESTS COMPLETED ==="
