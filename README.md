# ⚡ Adaptive Discord Bypass Engine

Windows 10-11 işletim sistemlerinde Discord erişim ve ses kanalı (**RTC Connecting / Voice Router**) sorunlarını sıfır ping ve sıfır sistem yüküyle çözmek amacıyla geliştirilmiş otomasyon aracıdır.

Sıradan araçların aksine tüm bilgisayarın internet trafiğini bozmaz; **sadece Discord trafiğini hedef alır** ve ağınız için çalışan **en hafif paket modunu** otomatik olarak tespit edip kilitler.

## ⚖️ Neden Bu Araç? (Karşılaştırma Tablosu)

Piyasadaki GoodbyeDPI betiklerinin birçoğu ezbere yazıldığı için bilgisayarınızdaki tüm internet trafiğini (`0.0.0.0/0`) manipüle eder. Bu proje ise **nokta atışı ağ mühendisliği** prensipleriyle çalışır:

| Özellik / Metrik | Sıradan Bypass Araçları | Adaptive Discord Engine |
| --- | --- | --- |
| **Trafik Kapsamı (Scope)** | 🌐 Tüm internet trafiğinizi (Oyunlar, YouTube, Web) işler. | 🎯 **Sadece Discord trafiğini** işler (`discord_hosts.txt`). |
| **Oyun İçi Ping & FPS** | ⚠️ Oyun paketlerini böldüğü için **ping yükseltir, oyundan atar.** | 🟢 **Sıfır Risk.** Oyun paketleri sürücüye hiç uğramaz. |
| **Sürücü / Temizlik** | ❌ Kapanışta `WinDivert` arka planda kalır, **klasör silinemez.** | 🛡️ **Kusursuz Bekçi:** Pencere kapandığı an sürücü silinir. |
| **Parametre Seçimi** | ❌ Statik/Ezbere. Genellikle ağır moda zorlanır. | ⚡ **Dinamik.** Saniyeler içinde **en hafif** tüneli kilitler. |
| **Çekirdek Motor** | ⚠️ Üçüncü taraf veya değiştirilmiş fork'lar kullanılır. | 🔒 **Official ValdikSS Core** (v0.2.3rc3 Upstream). |
| **DNS Optimizasyonu** | ❌ Yandex vb. uzak DNS'ler zorlanarak rota uzatılır. | 🔄 **Akıllı Sıralama:** Yerel peering sunan Cloudflare/Google önceliklidir. |
| **Test Metodolojisi** | ⏳ Yavaş. Discord'u elle açıp denemeniz gerekir. | 🚀 **Arka Planda Soket Testi:** 2-4 saniyede Discord'suz test eder. |

## 🎯 Çalışma Mantığı ve Mimari

Betik, kaba kuvvet çalıştırma yerine kademeli tarama ve dinamik kaynak yönetimi yapar:
```
[ Başlat.bat ] ──► (Yönetici Yetkisi Kontrolü)

│
▼
[ Sistem Temizliği ] ──► (Eski WinDivert & Process'ler Temizlenir)

│
▼
[ Official ValdikSS Core ] ──► (Resmi Repo & discord_hosts.txt Hazırlanır)

│
▼
[ Akıllı Tünel Taraması ] ──► (7 Metot x 4 DNS = Hızlı Soket Testi)

│
▼
[ Tünel Kilitlendi! ] ──► (Arka Planda Sessizce Çalıştırılır)

│
▼
[ Bağımsız Bekçi Süreci ] ──► (Pencere Kapanışını İzler -> Sürücüyü Siler)
```
### 1. Nokta Atışı Karaliste (`discord_hosts.txt`)

Betik tüm sistem internetinizi değil; sadece Discord alan adlarını (`discord.com`, `gateway.discord.gg`, `cdn.discordapp.com` vb.) kapsayan özel bir karaliste kullanır. Oyun paketleriniz veya genel gezintiniz GoodbyeDPI sürücüsüne takılmaz.

### 2. Kademeli Metot Taraması (En Hafif Mod Tercihi)

- **Paket Parçalamayan Modlar (Seviye 1 - 3):** Sadece TCP başlıklarını veya TTL değerlerini düzenler. Paket parçalanmadığı için işlemci yükü ve ek gecikme oluşmaz.
- **Paket Parçalayan Modlar (Seviye 4 - 7):** Sıkı engelli hatlarda zorunlu olarak devreye girer.
- **Adaptif Seçim:** Betik en ağır modla başlamak yerine, sırayla deneyerek erişimi sağlayan **EN HAFİF** modu bulur ve tüneli orada sabitler.

### 3. Kusursuz Bekçi (Guard Process Protocol)

Arka planda çalışan bağımsız Bekçi süreci, ana pencere kapatıldığı anda `goodbyedpi.exe` sürecini sonlandırır ve `WinDivert` sürücüsünü sistemden tamamen siler.

## 🛠️ Performans Hiyerarşisi

Betik aşağıdaki modları en az yük bindirenden en ağıra doğru sırayla dener:

| Seviye | Metot Adı | Teknik Açıklama |
| --- | --- | --- |
| **L1** | **Header Mix** | `-s -m` (SNI & HTTP Başlık Karma) - *Parçalama Yok* |
| **L2** | **TTL Limit** | `--set-ttl 3` (IP Paket Ömrü Ayarı) - *Parçalama Yok* |
| **L3** | **Pasif Koruma** | `-p -r -s` (Pasif DPI Yanıltma) - *Parçalama Yok* |
| **L4** | **Hafif Mod** | `-3` (GoodbyeDPI Preset -3 Paket Bölme) |
| **L5** | **Dengeli Mod** | `-5` (GoodbyeDPI Preset -5 Paket Bölme) |
| **L6** | **Agresif Mod** | `-9` (GoodbyeDPI Preset -9 Derin Bölme) |
| **L7** | **Extreme Force** | `-p -r -e 1 -f 1 -m --wrong-chksum` (Gelişmiş Tünelleme) |

## 📥 Kurulum ve Kullanım

1. Projeyi bilgisayarınıza indirin ve bir klasöre çıkartın.
2. Klasör içindeki **`start.bat`** dosyasına sağ tıklayıp **Yönetici Olarak Çalıştır**'a basın. Eğer akıllı kullanıcı denetimi uyarisi veriyorsa windows güvenliğinde uygulamalar bölümünde bu ayarı kapatıp tekrar çalıştırın.
3. Betik saniyeler içinde hattınız için çalışan en uygun konfigürasyonu bulacak ve kilitleyecektir.
4. **İşiniz bittiğinde pencereyi kapatmanız yeterlidir.** Bekçi protokolü arkadaki tüm sürücüleri ve dosyaları otomatik olarak temizleyecektir.

## 💡 İleri Düzey Notlar & Alternatifler

- **Diğer DPI Araçlarıyla Kullanım:** Bu araç kapandığı an sürücüleri tamamen temizlediği için sisteminizde başka bir VPN veya DPI aracı çalıştıracağınız zaman çakışma yaşamazsınız.
- **Zapret Yönlendirmesi:** Eğer servis sağlayıcınız (ISP) aşırı katı bir DPI/SNI kısıtlaması uyguluyorsa ve L7 seviyesinde bile bağlantı kurulamıyorsa, GoodbyeDPI mimarisi yetersiz kalıyor demektir. Bu durumda kernel seviyesinde paket manipülasyonu yapan **Zapret** gibi üst seviye çözümlere geçmeniz önerilir.

## ⚖️ Sorumluluk Reddi (Disclaimer)

Bu betik yalnızca eğitim, ağ analizi, sistem optimizasyonu ve kişisel kullanım amacıyla geliştirilmiştir. Yazılımın kullanımıyla ilgili tüm sorumluluk kullanıcıya aittir. Geliştirici, bu betiğin kullanımından doğabilecek doğrudan veya dolaylı hiçbir sorumluluğu kabul etmez.

## 🙏 Teşekkürler

Çekirdek engine için [ValdikSS/GoodbyeDPI](https://github.com/ValdikSS/GoodbyeDPI) projesine ve açık kaynak topluluğuna teşekkür ederiz.