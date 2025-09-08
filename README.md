# 🤖 APISIX Bot Routing System

Apache APISIX kullanarak bot trafiğini normal kullanıcı trafiğinden ayıran akıllı routing sistemi.

## 📋 İçindekiler

- [Özellikler](#-özellikler)
- [Mimari](#-mimari)
- [Kurulum](#-kurulum)
- [Kullanım](#-kullanım)
- [Routing Kuralları](#-routing-kuralları)
- [Test](#-test)
- [Troubleshooting](#-troubleshooting)

## ✨ Özellikler

- **🎯 Akıllı Bot Detection**: User-Agent, IP whitelist ve JWT tabanlı bot algılama
- **⚡ Yüksek Performans**: Apache APISIX ile düşük latency
- **🔐 JWT Authentication**: Token tabanlı kimlik doğrulama
- **📊 Rate Limiting**: Bot ve normal kullanıcılar için farklı rate limit'ler
- **🎨 Visual Feedback**: Bot'lar için kırmızı, normal kullanıcılar için yeşil sayfa
- **🐳 Kubernetes Native**: Tam Kubernetes entegrasyonu
- **📈 GitOps Ready**: ArgoCD ile otomatik deployment

## 🏗️ Mimari

```mermaid
graph TD
    A[İstek] --> B{APISIX Gateway}
    B -->|Priority: 1000| C[JWT Decode /jwt-decode]
    B -->|Priority: 200| D[IP Whitelist]
    B -->|Priority: 100| E[Bot User-Agent]
    B -->|Priority: 50| F[Normal Traffic]
    
    C --> G[JWT Response]
    D --> H[portal-svc-bot 🔴]
    E --> H
    F --> I[portal-svc 🟢]
    
    H --> J[Bot Sayfası<br/>Kırmızı Arka Plan<br/>2 req/min]
    I --> K[Normal Sayfa<br/>Yeşil Arka Plan<br/>100 req/min]
```

## 🚀 Kurulum

### Ön Gereksinimler

- Kubernetes cluster (v1.20+)
- kubectl CLI
- Apache APISIX (Helm ile kurulu)

### 1. Repository'yi Clone Edin

```bash
git clone <repository-url>
cd apisix-bot-routing
```

### 2. APISIX Kurulumu

```bash
# APISIX Helm chart'ını ekle
helm repo add apisix https://charts.apiseven.com
helm repo update

# APISIX'i kur
helm install apisix apisix/apisix -n apisix --create-namespace
```

### 3. Uygulamayı Deploy Edin

```bash
# Service'leri deploy et
kubectl apply -f k8s/portal-svc.yaml
kubectl apply -f k8s/portal-svc-bot.yaml

# Routing kurallarını deploy et
kubectl apply -f k8s/production-routing.yaml
```

### 4. Port Forward

```bash
# APISIX'e erişim için port forward
kubectl port-forward -n apisix svc/apisix-ingress-controller 8080:8080
```

## 🎮 Kullanım

### Normal Kullanıcı Testi

```bash
# Browser User-Agent ile test
curl -H "User-Agent: Mozilla/5.0 (Windows NT 10.0; Win64; x64)" http://localhost:8080

# Beklenen: Yeşil arka planlı normal sayfa
```

### Bot Testi

```bash
# Bot User-Agent ile test
curl -H "User-Agent: Bot" http://localhost:8080

# Beklenen: Kırmızı arka planlı bot sayfası
```

### JWT Token Testi

```bash
# JWT decode endpoint'ini test et
curl -H "Authorization: Bearer YOUR_JWT_TOKEN" http://localhost:8080/jwt-decode

# Beklenen: JWT decode response
```

### Otomatik Test

```bash
# Tüm testleri çalıştır
chmod +x scripts/jwt-token-test.sh
./scripts/jwt-token-test.sh
```

## 📋 Routing Kuralları

| Priority | Kural | Target Service | Rate Limit | Açıklama |
|----------|-------|----------------|------------|----------|
| 1000 | `/jwt-decode` | portal-svc | - | JWT token decode endpoint |
| 200 | IP Whitelist | portal-svc-bot | 2 req/min | Özel IP'ler için bot sayfası |
| 100 | User-Agent: "Bot" | portal-svc-bot | 2 req/min | Bot User-Agent detection |
| 50 | Diğer tüm trafik | portal-svc | 100 req/min | Normal kullanıcılar |

### Service'ler

- **portal-svc**: Normal kullanıcılar için yeşil sayfa
- **portal-svc-bot**: Bot'lar için kırmızı sayfa

## 🧪 Test

### Test Script'i Çalıştırma

```bash
./scripts/jwt-token-test.sh
```

Test script'i şunları kontrol eder:
- ✅ JWT decode endpoint'inin çalışması
- ✅ Normal routing (yeşil sayfa)
- ✅ Bot routing (kırmızı sayfa)
- ✅ Rate limiting

### Manuel Test

```bash
# 1. Normal kullanıcı testi
curl http://localhost:8080

# 2. Bot testi
curl -H "User-Agent: Bot" http://localhost:8080

# 3. JWT decode testi
curl -H "Authorization: Bearer eyJhbGciOiJIUzI1NiJ9..." http://localhost:8080/jwt-decode
```

## 🔧 Troubleshooting

### Port 8080'e Erişilemiyor

```bash
# APISIX pod'unu kontrol et
kubectl get pods -n apisix

# Port forward'u yeniden başlat
kubectl port-forward -n apisix svc/apisix-ingress-controller 8080:8080
```

### Route'lar Çalışmıyor

```bash
# Route'ları kontrol et
kubectl get apisixroute

# Route detaylarını gör
kubectl describe apisixroute portal-normal-route
```

### Service'ler Çalışmıyor

```bash
# Service'leri kontrol et
kubectl get svc

# Endpoint'leri kontrol et
kubectl get endpoints portal-svc
```

### 404 Hatası Alıyorum

```bash
# APISIX ingress controller log'larını kontrol et
kubectl logs -n apisix -l app.kubernetes.io/name=apisix-ingress-controller

# Route'ları yeniden deploy et
kubectl delete apisixroute --all
kubectl apply -f k8s/production-routing.yaml
```

## 📁 Dosya Yapısı

```
apisix-bot-routing/
├── k8s/                           # Kubernetes manifests
│   ├── production-routing.yaml    # Ana routing kuralları
│   ├── portal-svc.yaml           # Normal sayfa service
│   ├── portal-svc-bot.yaml       # Bot sayfa service
│   ├── jwt-decode-only.yaml      # JWT decode endpoint
│   └── jwt-lua-configmap.yaml    # JWT handler Lua script
├── scripts/                       # Test ve deployment script'leri
│   ├── jwt-token-test.sh         # Ana test script'i
│   ├── start.sh                  # Başlatma script'i
│   ├── stop.sh                   # Durdurma script'i
│   └── test-all-routes.sh        # Tüm route testleri
├── jwt-decode-handler.lua         # JWT decode Lua handler
└── README.md                      # Bu dosya
```

## 🚀 Production Deployment

### ArgoCD ile GitOps

```bash
# ArgoCD kurulumu
kubectl apply -f k8s/argocd-application.yaml
```

### Monitoring

```bash
# APISIX metrics
kubectl port-forward -n apisix svc/apisix-admin 9180:9180

# Prometheus metrics endpoint
curl http://localhost:9180/apisix/prometheus/metrics
```

## 🤝 Katkıda Bulunma

1. Fork edin
2. Feature branch oluşturun (`git checkout -b feature/amazing-feature`)
3. Commit edin (`git commit -m 'Add some amazing feature'`)
4. Push edin (`git push origin feature/amazing-feature`)
5. Pull Request oluşturun

## 📝 License

Bu proje MIT lisansı altında lisanslanmıştır.

## 📞 İletişim

- GitHub Issues: [Issues](https://github.com/your-repo/issues)
- Documentation: [Wiki](https://github.com/your-repo/wiki)

---

**🎯 Bu sistem ile bot trafiğinizi akıllıca yönlendirebilir, normal kullanıcılarınıza daha iyi bir deneyim sunabilirsiniz!**