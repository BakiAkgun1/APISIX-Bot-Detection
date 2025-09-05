# 🤖 APISIX Gelişmiş Bot Routing Sistemi

IP listesi ve JWT token ile kullanıcıları bot servisine yönlendiren akıllı routing sistemi.

## 🎯 Özellikler

- **IP Whitelist Routing**: Belirli IP'lerden gelen istekler bot servisine
- **JWT Header Routing**: `X-User-Type: bot_user` ve `X-User-Role: admin` ile yönlendirme
- **Bot User-Agent Detection**: Otomatik bot tespiti
- **Priority System**: Yüksek priority'li route'lar önce kontrol edilir
- **Rate Limiting**: Her kullanıcı türü için farklı limitler

## 📋 Gereksinimler

- **Kubernetes Cluster** (4 nodeluk cluster ile test edildi)
- **kubectl** CLI tool
- **Helm 3.x**
- **WSL2 Ubuntu** (Windows kullanıcıları için)

## 🚀 Kurulum Adımları

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
Rate Limit: 50 req/saniye
```

### 2. Bot Kullanıcı Testi

```bash
curl -H "User-Agent: googlebot" http://localhost:8080
```

**Beklenen Çıktı:**
```html
🤖 Portal Bot Sayfası
Bot trafiği için özel sayfa
Rate Limit: 5 req/saniye (Bot için düşük)
```

### 3. JWT Header Testleri

```bash
# Bot User Test
curl -H "X-User-Type: bot_user" http://localhost:8080

# Admin User Test
curl -H "X-User-Role: admin" http://localhost:8080

# IP Whitelist Test
curl -H "X-Forwarded-For: 192.168.1.100" http://localhost:8080
```

## 📊 Priority Sıralaması

1. **Priority 200**: IP Whitelist → Bot servisi
2. **Priority 170**: JWT Bot Users → Bot servisi
3. **Priority 160**: JWT Admin Users → Normal servis
4. **Priority 100**: Bot User-Agent → Bot servisi
5. **Priority 50**: Normal Users → Normal servis

## 🔧 Manuel Route Ekleme

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
| IP Whitelist | 10 req/s | 20 | portal-svc-bot | 200 |
| JWT Bot Users | 15 req/s | 30 | portal-svc-bot | 170 |
| JWT Admin | 25 req/s | 50 | portal-svc | 160 |
| Bot User-Agent | 5 req/s | 10 | portal-svc-bot | 100 |
| Normal Traffic | 50 req/s | 100 | portal-svc | 50 |

## ⚠️ Priority Eşitse

Aynı priority değerine sahip route'lar varsa:
- **İlk eklenen route öncelik alır** (FIFO)
- Route'ların sırası önemli
- Daha spesifik match'ler önce kontrol edilir

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
│   └── bot-routing-fixed.yaml          # Eski routing (yedek)
└── scripts/
    ├── start.sh                        # Uygulamayı başlatma
    ├── stop.sh                         # Uygulamayı kapatma
    └── test-advanced-routing.sh        # Test script'i
```

## 🧪 Test Senaryoları

### Başarılı Testler:
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

### Beklenen Sonuçlar:
- **Bot Sayfası:** Kırmızı arka plan, "🤖 Portal Bot Sayfası"
- **Normal Sayfa:** Yeşil arka plan, "🌟 Portal Ana Sayfa"

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