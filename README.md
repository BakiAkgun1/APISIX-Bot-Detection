# APISIX Bot Detection & Rate Limiting Project

Bu proje, **APISIX API Gateway** kullanarak bot trafiğini tespit eden ve farklı rate limiting uygulayan bir **Kubernetes** kurulumudur.

## 🎯 Proje Özeti

- **Bot Detection**: User-Agent header'ına göre bot trafiği tespiti
- **Intelligent Routing**: Bot'lar ve normal kullanıcılar için farklı servisler
- **Rate Limiting**: Bot'lar için kısıtlı (5 req/s), normal kullanıcılar için yüksek (50 req/s) limit
- **Kubernetes Native**: Tamamen Kubernetes üzerinde çalışan çözüm
- **Production Ready**: APISIX enterprise-grade API Gateway

## Sistem Mimarisi

```
Internet → APISIX Gateway → Bot Detection → Route Decision
                              ↓
                  Bot Traffic ↙     ↘ Normal Traffic
                             ↓       ↓
                    portal-svc-bot  portal-svc
                    (Rate: 5/s)     (Rate: 50/s)
```

**Cluster Yapısı**: 4 nodeluk Kubernetes cluster (WSL Ubuntu üzerinde)

## 📋 Gereksinimler

- **Kubernetes Cluster** (4 nodeluk cluster ile test edildi)
- **kubectl** CLI tool
- **Helm 3.x**
- **WSL2 Ubuntu** (Windows kullanıcıları için)

## 🚀 Kurulum Adımları

### 0. WSL Ubuntu Kurulumu (Windows için)

```bash
# WSL Ubuntu kurulumu
wsl --install -d Ubuntu

# Ubuntu'yu başlat ve güncelle
sudo apt update && sudo apt upgrade -y

# Gerekli paketleri kur
sudo apt install -y curl wget git
```

### 1. Kubernetes Cluster Kontrolü

```bash
# Cluster bilgilerini kontrol et
kubectl cluster-info

# Node'ları listele (4 nodeluk cluster)
kubectl get nodes

# Node detaylarını gör
kubectl describe nodes
```

### 2. Helm Kurulumu

```bash
# Helm indirme (WSL Ubuntu için)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# APISIX Helm repository ekleme
helm repo add apisix https://charts.apiseven.com
helm repo update
```

### 3. APISIX Namespace Oluşturma

```bash
kubectl create namespace apisix
```

### 4. APISIX Kurulumu

```bash
helm install apisix apisix/apisix \
  --namespace apisix \
  --values apisix-working-values.yaml \
  --wait \
  --timeout 10m
```

### 5. Portal Servislerini Deploy Etme

```bash
# Normal kullanıcılar için portal
kubectl apply -f k8s/portal-svc.yaml

# Bot kullanıcılar için portal
kubectl apply -f k8s/portal-svc-bot.yaml
```

### 6. APISIX Route Konfigürasyonu

```bash
# Route'ları uygula
kubectl apply -f k8s/bot-routing-fixed.yaml
```

### 7. Port Forward ile Test

```bash
# APISIX Gateway port forward
kubectl port-forward -n apisix service/apisix-gateway 8080:80 &

# APISIX Admin API port forward (opsiyonel)
kubectl port-forward -n apisix service/apisix-admin 9180:9180 &
```

## 🧪 Test Etme

### 1. Normal Kullanıcı Testi

```bash
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://localhost:8080
```

**Beklenen Çıktı:**
```html
🌟 Portal Ana Sayfa
Hoşgeldiniz! Bu normal kullanıcılar için portal sayfası.
Rate Limit: 50 req/saniye
```

### 2. Bot Kullanıcı Testi

```bash
curl -H "User-Agent: googlebot/2.1" http://localhost:8080
```

**Beklenen Çıktı:**
```html
🤖 Portal Bot Sayfası
Bot trafiği için özel sayfa
Rate Limit: 5 req/saniye (Bot için düşük)
```

### 3. Rate Limit Testi

```bash
echo "=== Bot Rate Limit Test ==="
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
```

**Beklenen Çıktı:**
```
Request 1: HTTP 200
Request 2: HTTP 200
Request 3: HTTP 429
  RATE LIMITED!
Request 4: HTTP 429
  RATE LIMITED!
```

<img width="605" height="529" alt="image" src="https://github.com/user-attachments/assets/426eb0aa-8896-4415-85b9-40f22195e24e" />

## 📁 Proje Yapısı

```
apisix-bot-routing/
├── README.md                           # Bu dosya
├── apisix-working-values.yaml          # APISIX Helm values (çalışan versiyon)
└── k8s/
    ├── portal-svc.yaml                 # Normal kullanıcılar için portal servisi
    ├── portal-svc-bot.yaml             # Bot kullanıcılar için portal servisi
    └── bot-routing-fixed.yaml          # APISIX route konfigürasyonu
```

## ⚙️ Konfigürasyon Detayları

### Bot Detection Regex

```regex
.*(bot|crawler|spider|scraper|googlebot|bingbot).*
```

Bu regex aşağıdaki User-Agent'ları yakalar:
- `googlebot`
- `bingbot`
- `crawler`
- `spider`
- `scraper`
- `facebookexternalhit`
- `twitterbot`

### Rate Limiting Konfigürasyonu

| Traffic Type | Rate Limit | Burst | Target Service | Priority |
|--------------|------------|-------|----------------|----------|
| Bot Traffic  | 5 req/s    | 10    | portal-svc-bot | 100      |
| Normal Traffic | 50 req/s  | 100   | portal-svc     | 50       |

### APISIX Route Öncelikleri

- **Bot Route Priority**: 100 (yüksek öncelik)
- **Normal Route Priority**: 50 (düşük öncelik)

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
kubectl get apisixroute -n apisix

# Route detaylarını gör
kubectl describe apisixroute portal-bot-route -n apisix
kubectl describe apisixroute portal-normal-route -n apisix
```

### 3. Rate Limit Çalışmıyor

```bash
# Route konfigürasyonunu kontrol et
kubectl get apisixroute portal-bot-route -n apisix -o yaml
```

### 4. Servis Bağlantı Sorunları

```bash
# Endpoint'leri kontrol et
kubectl get endpoints -n default

# Servis detaylarını gör
kubectl describe service portal-svc
kubectl describe service portal-svc-bot
```

## 🚪 Uygulamayı Kapatma ve Tekrar Başlatma

### WSL Ubuntu'da Uygulamayı Kapatma

#### 1. Port Forward'ları Kapat

```bash
# Tüm port forward işlemlerini kapat
pkill -f port-forward

# Veya manuel olarak process ID'yi bul ve öldür
ps aux | grep port-forward
kill <process_id>
```

#### 2. Portal Servislerini Kapat

```bash
# Portal deploymentlarını sil
kubectl delete deployment portal-app portal-bot-app

# Portal servislerini sil
kubectl delete service portal-svc portal-svc-bot

# Veya YAML dosyalarıyla sil
kubectl delete -f k8s/portal-svc.yaml
kubectl delete -f k8s/portal-svc-bot.yaml
```

#### 3. APISIX Route'larını Temizle

```bash
# Admin API ile route'ları sil
kubectl port-forward -n apisix service/apisix-admin 9180:9180 &

curl -X DELETE \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  http://localhost:9180/apisix/admin/routes/1

curl -X DELETE \
  -H "X-API-KEY: edd1c9f034335f136f87ad84b625c8f1" \
  http://localhost:9180/apisix/admin/routes/2

pkill -f port-forward
```

#### 4. APISIX'i Tamamen Kapat (İsteğe Bağlı)

```bash
# APISIX Helm release'ini sil
helm uninstall apisix -n apisix

# APISIX namespace'ini sil
kubectl delete namespace apisix
```

### WSL Ubuntu'da Uygulamayı Tekrar Başlatma

#### 1. Hızlı Başlatma (APISIX Zaten Kuruluysa)

```bash
# Portal servislerini başlat
kubectl apply -f k8s/portal-svc.yaml
kubectl apply -f k8s/portal-svc-bot.yaml

# Pod'ların hazır olmasını bekle
kubectl wait --for=condition=ready pod --all --timeout=120s

# APISIX route'larını ekle
kubectl port-forward -n apisix service/apisix-admin 9180:9180 &

# Bot route
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

# Normal route
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

pkill -f port-forward
```

#### 2. Tam Kurulum (APISIX Silinmişse)

```bash
# APISIX namespace oluştur
kubectl create namespace apisix

# APISIX kur
helm install apisix apisix/apisix \
  --namespace apisix \
  --values apisix-working-values.yaml \
  --wait \
  --timeout 10m

# Yukarıdaki "Hızlı Başlatma" kısmını çalıştır
```

#### 3. WSL Kapatıldıktan Sonra Tekrar Açma

```bash
# WSL Ubuntu'yu yeniden başlat
wsl --shutdown
wsl -d Ubuntu

# Kubernetes cluster'ın çalıştığını kontrol et
kubectl cluster-info

# Eğer cluster çalışmıyorsa, Docker Desktop'ı başlat
# Windows'ta Docker Desktop uygulamasını aç

# Cluster hazır olduktan sonra yukarıdaki "Hızlı Başlatma" komutlarını çalıştır
```

## 🧹 Temizleme

```bash
# APISIX'i kaldır
helm uninstall apisix -n apisix

# Portal servislerini sil
kubectl delete -f k8s/portal-svc.yaml
kubectl delete -f k8s/portal-svc-bot.yaml

# Route'ları sil
kubectl delete -f k8s/bot-routing-fixed.yaml

# Namespace'i sil
kubectl delete namespace apisix
```

## 🎉 Sonuç

Bu kurulum ile aşağıdaki özellikleri elde ettik:

✅ **Bot Detection**: User-Agent tabanlı bot tespiti  
✅ **Intelligent Routing**: Bot ve normal kullanıcılar için farklı servisler  
✅ **Rate Limiting**: Dinamik rate limiting (Bot: 5 req/s, Normal: 50 req/s)  
✅ **High Availability**: Kubernetes üzerinde ölçeklenebilir mimari  
✅ **Production Ready**: APISIX enterprise-grade API Gateway  

## 🤝 Katkıda Bulunma

1. Fork yapın
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit yapın (`git commit -m 'Add amazing feature'`)
4. Push yapın (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📄 Lisans

Bu proje MIT lisansı altında lisanslanmıştır.

## 🔗 Faydalı Linkler

- [APISIX Documentation](https://apisix.apache.org/docs/)
- [APISIX Helm Charts](https://github.com/apache/apisix-helm-chart)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Not**: Bu proje WSL Ubuntu üzerinde 4 nodeluk Kubernetes cluster ile test edilmiştir. Production ortamında kullanmadan önce güvenlik ve performans testleri yapılması önerilir.
