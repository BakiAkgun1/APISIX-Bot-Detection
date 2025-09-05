#!/bin/bash

# APISIX Bot Routing - Rate Limit Test Komutları
# Bu dosya sadece test komutlarını içerir, çalıştırma script'i değil
# Kopyala-yapıştır ile kullanabilirsin

echo "=== IP WHITELIST TESTLERİ (2 req/saniye) ==="

echo "IP 192.168.1.100:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "IP 192.168.1.101:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-Forwarded-For: 192.168.1.101" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "IP 10.0.0.50:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-Forwarded-For: 10.0.0.50" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "IP 172.16.0.25:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-Forwarded-For: 172.16.0.25" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done 

echo "=== DİĞER ROUTING TESTLERİ ==="

echo "JWT Bot User:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-User-Type: bot_user" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "Username Routing:"
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-Username: testuser" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "JWT Admin:"
for i in {1..12}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "X-User-Role: admin" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

echo "Normal User:"
for i in {1..12}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "User-Agent: Mozilla/5.0" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done
