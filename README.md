#  APISIX Gelişmiş Bot Routing Sistemi

IP listesi, JWT token ve username ile kullanıcıları bot servisine yönlendiren akıllı routing sistemi.

##  Özellikler

- **IP Whitelist Routing**: 4 farklı IP'den gelen istekler bot servisine
- **JWT Header Routing**: `X-User-Type: bot_user` ve `X-User-Role: admin` ile yönlendirme
- **Username Routing**: `X-Username: testuser` ile bot servisine yönlendirme
- **Bot User-Agent Detection**: `User-Agent: Bot` ile otomatik bot tespiti
- **Priority System**: Yüksek priority'li route'lar önce kontrol edilir
- **Rate Limiting**: Bot kullanıcıları 2 req/min, Normal kullanıcılar 10 req/min

##  Gereksinimler

- **Kubernetes Cluster** (4 nodeluk cluster ile test edildi)
- **kubectl** CLI tool
- **Helm 3.x**
- **WSL2 Ubuntu** (Windows kullanıcıları için)

##  Kurulum Adımları

### 1. WSL Ubuntu Kurulumu (Windows için)

```bash
# WSL Ubuntu kurulumu
wsl --install -d Ubuntu

# Ubuntu'yu başlat ve güncelle
sudo apt update && sudo apt upgrade -y

# Gerekli paketleri kur
sudo apt install -y curl wget git
```

### 2. Kubernetes Cluster Kontrolü

```bash
# Cluster bilgilerini kontrol et
kubectl cluster-info

# Node'ları listele (4 nodeluk cluster)
kubectl get nodes

# Node detaylarını gör
kubectl describe nodes
```

### 3. Helm Kurulumu

```bash
# Helm indirme (WSL Ubuntu için)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# APISIX Helm repository ekleme
helm repo add apisix https://charts.apiseven.com
helm repo update
```

### 4. APISIX Namespace Oluşturma

```bash
kubectl create namespace apisix
```

### 5. APISIX Kurulumu

```bash
helm install apisix apisix/apisix \
  --namespace apisix \
  --values apisix-working-values.yaml \
  --wait \
  --timeout 10m
```

### 6. Portal Servislerini Deploy Etme

```bash
# Normal kullanıcılar için portal
kubectl apply -f k8s/portal-svc.yaml

# Bot kullanıcılar için portal
kubectl apply -f k8s/portal-svc-bot.yaml
```

### 7. APISIX Route Konfigürasyonu

```bash
# Route'ları uygula
kubectl apply -f k8s/advanced-bot-routing.yaml
kubectl apply -f k8s/simple-jwt-routing.yaml
```

### 8. Port Forward ile Test

```bash
# APISIX Gateway port forward
kubectl port-forward -n apisix service/apisix-gateway 8080:80 &

# APISIX Admin API port forward
kubectl port-forward -n apisix service/apisix-admin 9180:9180 &
```

## 🧪 Test Etme

### 1. Normal Kullanıcı Testi

```bash
curl http://localhost:8080
```

**Beklenen Çıktı:**
```html
🌟 Portal Ana Sayfa
Hoşgeldiniz! Bu normal kullanıcılar için portal sayfası.
Rate Limit: 10 req/saniye (Normal kullanıcılar için yüksek)
```

### 2. Bot Kullanıcı Testi

```bash
curl -H "User-Agent: Bot" http://localhost:8080
```

**Beklenen Çıktı:**
```html
🤖 Portal Bot Sayfası
Bot trafiği için özel sayfa
Rate Limit: 2 req/saniye (Bot için düşük)
```

### 3. JWT Header Testleri

```bash
# Bot User Test
curl -H "X-User-Type: bot_user" http://localhost:8080

# Admin User Test
curl -H "X-User-Role: admin" http://localhost:8080

# Username Routing Test
curl -H "X-Username: testuser" http://localhost:8080
```

### 4. IP Whitelist Testleri

```bash
# 4 farklı IP testi
curl -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080
curl -H "X-Forwarded-For: 192.168.1.101" http://localhost:8080
curl -H "X-Forwarded-For: 10.0.0.50" http://localhost:8080
curl -H "X-Forwarded-For: 172.16.0.25" http://localhost:8080
```

##  Priority Sıralaması

1. **Priority 200**: IP Whitelist (4 IP) → Bot servisi
2. **Priority 170**: JWT Bot Users → Bot servisi
3. **Priority 100**: Bot User-Agent → Bot servisi
4. **Priority 80**: JWT Admin Users → Normal servis
5. **Priority 70**: Username Routing → Bot servisi
6. **Priority 50**: Normal Users → Normal servis

##  Manuel Route Ekleme

Eğer otomatik route'lar çalışmazsa manuel olarak ekleyebilirsin:

```bash
# Bot User Route
curl -X PUT -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{"uri": "/*", "priority": 170, "vars": [["http_x_user_type", "==", "bot_user"]], "upstream": {"type": "roundrobin", "nodes": {"portal-svc-bot.default.svc.cluster.local:80": 1}}, "plugins": {"limit-req": {"rate": 15, "burst": 30, "key": "remote_addr", "rejected_code": 429}}}' \
  http://localhost:9180/apisix/admin/routes/1

# Admin User Route
curl -X PUT -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{"uri": "/*", "priority": 160, "vars": [["http_x_user_role", "==", "admin"]], "upstream": {"type": "roundrobin", "nodes": {"portal-svc.default.svc.cluster.local:80": 1}}, "plugins": {"limit-req": {"rate": 25, "burst": 50, "key": "remote_addr", "rejected_code": 429}}}' \
  http://localhost:9180/apisix/admin/routes/3

# IP Whitelist Route
curl -X PUT -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{"uri": "/*", "priority": 200, "vars": [["http_x_forwarded_for", "~~", "192\\.168\\.1\\.(100|101)|10\\.0\\.0\\.50|172\\.16\\.0\\.25"]], "upstream": {"type": "roundrobin", "nodes": {"portal-svc-bot.default.svc.cluster.local:80": 1}}, "plugins": {"limit-req": {"rate": 10, "burst": 20, "key": "remote_addr", "rejected_code": 429}}}' \
  http://localhost:9180/apisix/admin/routes/4

# Normal User Route
curl -X PUT -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  -H "Content-Type: application/json" \
  -d '{"uri": "/*", "priority": 50, "upstream": {"type": "roundrobin", "nodes": {"portal-svc.default.svc.cluster.local:80": 1}}, "plugins": {"limit-req": {"rate": 50, "burst": 100, "key": "remote_addr", "rejected_code": 429}}}' \
  http://localhost:9180/apisix/admin/routes/2
```

## 📈 Rate Limits

| Traffic Type | Rate Limit | Burst | Target Service | Priority |
|--------------|------------|-------|----------------|----------|
| IP Whitelist (4 IP) | 2 req/min | 4 | portal-svc-bot | 200 |
| JWT Bot Users | 2 req/min | 4 | portal-svc-bot | 170 |
| Bot User-Agent | 2 req/min | 4 | portal-svc-bot | 100 |
| Username Routing | 2 req/min | 4 | portal-svc-bot | 70 |
| JWT Admin | 10 req/min | 20 | portal-svc | 80 |
| Normal Traffic | 10 req/min | 20 | portal-svc | 50 |

## ⚠️ Priority Eşitse

Aynı priority değerine sahip route'lar varsa:
- **İlk eklenen route öncelik alır** (FIFO)
- Route'ların sırası önemli
- Daha spesifik match'ler önce kontrol edilir

## 🚀 Hızlı Başlangıç

### 1. Sistemi Başlat
```bash
# Tüm sistemi otomatik başlat
./scripts/start.sh
```

### 2. Port Forward'ları Başlat
```bash
# Terminal 1'de (Gateway)
kubectl port-forward -n apisix service/apisix-gateway 8080:80 &

# Terminal 2'de (Admin API)
kubectl port-forward -n apisix service/apisix-admin 9180:9180 &
```

### 3. Test Et
```bash
# Hızlı test
curl http://localhost:8080
curl -H "User-Agent: Bot" http://localhost:8080
curl -H "X-User-Role: admin" http://localhost:8080
curl -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080

# Tüm route'ları test et (WSL'de çalıştır)
./scripts/test-all-routes.sh

# Rate limit test komutlarını kopyala-yapıştır
cat scripts/rate-limit-test-commands.sh
```

### 4. Sistemi Kapat
```bash
./scripts/stop.sh
```

## 🚪 Otomatik Script'ler

### start.sh - Uygulamayı Başlatma
```bash
./scripts/start.sh
```
- ✅ APISIX namespace kontrolü
- ✅ Portal servislerini başlatma
- ✅ Pod'ların hazır olmasını bekleme
- ✅ APISIX route'larını otomatik kurma

### stop.sh - Uygulamayı Kapatma
```bash
./scripts/stop.sh
```
- ✅ Port forward'ları kapatma
- ✅ Portal servislerini silme
- ✅ APISIX route'larını temizleme

### test-advanced-routing.sh - Test
```bash
./scripts/test-advanced-routing.sh
```
- ✅ Tüm routing senaryolarını test etme

## 🔧 Troubleshooting

### 1. Pod'lar Başlamıyor
```bash
kubectl get pods -n apisix
kubectl describe pod <pod-name> -n apisix
kubectl logs <pod-name> -n apisix
```

### 2. APISIX Route'lar Çalışmıyor
```bash
# Route'ları kontrol et
kubectl get apisixroute

# Route detaylarını gör
kubectl describe apisixroute portal-bot-route
```

### 3. Port Forward Sorunları
```bash
# Port forward'ları temizle
pkill -f port-forward

# Yeniden başlat
kubectl port-forward -n apisix service/apisix-gateway 8080:80
```

## 📁 Proje Yapısı

```
apisix-bot-routing/
├── README.md                           # Bu dosya
├── apisix-working-values.yaml          # APISIX Helm values
├── k8s/
│   ├── portal-svc.yaml                 # Normal kullanıcılar için portal
│   ├── portal-svc-bot.yaml             # Bot kullanıcılar için portal
│   ├── advanced-bot-routing.yaml       # Gelişmiş routing konfigürasyonu
│   ├── simple-jwt-routing.yaml         # JWT routing konfigürasyonu
│   └── bot-routing-fixed.yaml          # Eski routing (silindi)
└── scripts/
    ├── start.sh                        # Uygulamayı başlatma
    ├── stop.sh                         # Uygulamayı kapatma
    ├── test-advanced-routing.sh        # Test script'i
    ├── test-all-routes.sh              # Tüm route testleri
    └── rate-limit-test-commands.sh     # Rate limit test komutları (kopyala-yapıştır)
```

## 🧪 Test Senaryoları

### Temel Testler:
```bash
# IP Whitelist
curl -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080
# ✅ Bot Sayfası

# Admin User
curl -H "X-User-Role: admin" http://localhost:8080  
# ✅ Normal Sayfa

# Normal User
curl http://localhost:8080
# ✅ Normal Sayfa
```

### Rate Limit Testleri:
```bash
# Bot Rate Limit Test (2 req/min)
echo "=== BOT RATE LIMIT TEST ==="
for i in {1..5}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" -H "User-Agent: Bot" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

# Normal Rate Limit Test (10 req/min)
echo "=== NORMAL RATE LIMIT TEST ==="
for i in {1..12}; do
  echo -n "Request $i: "
  response=$(curl -s -w "%{http_code}" http://localhost:8080 2>/dev/null)
  status_code=$(echo $response | tail -c 4)
  echo "HTTP $status_code"
  if [ "$status_code" = "429" ]; then
    echo "  🚫 RATE LIMITED!"
  elif [ "$status_code" = "200" ]; then
    echo "  ✅ SUCCESS"
  fi
  sleep 0.5
done

# JWT Bot User Rate Limit Test (2 req/min)
echo "=== JWT BOT USER RATE LIMIT TEST ==="
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

# JWT Admin Rate Limit Test (10 req/min)
echo "=== JWT ADMIN RATE LIMIT TEST ==="
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

# Username Routing Rate Limit Test (2 req/min)
echo "=== USERNAME ROUTING RATE LIMIT TEST ==="
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

# IP Whitelist Rate Limit Test (2 req/min)
echo "=== IP WHITELIST RATE LIMIT TEST ==="
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
```

### Beklenen Sonuçlar:
- **Bot Sayfası:** Kırmızı arka plan, "🤖 Portal Bot Sayfası", Rate Limit: 2 req/saniye
- **Normal Sayfa:** Yeşil arka plan, "🌟 Portal Ana Sayfa", Rate Limit: 10 req/saniye

## 📋 Özet

### ✅ Çalışan Özellikler:
- **IP Whitelist Routing**: 4 farklı IP (192.168.1.100, 192.168.1.101, 10.0.0.50, 172.16.0.25)
- **JWT Header Routing**: X-User-Type: bot_user, X-User-Role: admin
- **Username Routing**: X-Username: testuser
- **Bot User-Agent Detection**: User-Agent: Bot
- **Rate Limiting**: Bot 2 req/min, Normal 10 req/min
- **Priority System**: 200 → 170 → 100 → 80 → 70 → 50

### 🚀 Kullanım:
1. `./scripts/start.sh` - Sistemi başlat
2. Port forward'ları başlat
3. Test et
4. `./scripts/stop.sh` - Sistemi kapat

## 🧹 Temizleme

```bash
# APISIX'i kaldır
helm uninstall apisix -n apisix

# Portal servislerini sil
kubectl delete -f k8s/portal-svc.yaml
kubectl delete -f k8s/portal-svc-bot.yaml

# Route'ları sil
kubectl delete -f k8s/advanced-bot-routing.yaml
kubectl delete -f k8s/simple-jwt-routing.yaml

# Namespace'i sil
kubectl delete namespace apisix
```

## 🎉 Sonuç

Bu kurulum ile aşağıdaki özellikleri elde ettik:

✅ **IP Whitelist Routing**: Belirli IP'lerden gelen istekler bot servisine  
✅ **JWT Header Routing**: Header tabanlı kullanıcı yönlendirme  
✅ **Bot Detection**: User-Agent tabanlı bot tespiti  
✅ **Intelligent Routing**: Bot ve normal kullanıcılar için farklı servisler  
✅ **Rate Limiting**: Dinamik rate limiting  
✅ **High Availability**: Kubernetes üzerinde ölçeklenebilir mimari  

## 🔗 Faydalı Linkler

- [APISIX Documentation](https://apisix.apache.org/docs/)
- [APISIX Helm Charts](https://github.com/apache/apisix-helm-chart)
- [Kubernetes Documentation](https://kubernetes.io/docs/)

---

**Not**: Bu proje WSL Ubuntu üzerinde 4 nodeluk Kubernetes cluster ile test edilmiştir. Production ortamında kullanmadan önce güvenlik ve performans testleri yapılması önerilir.