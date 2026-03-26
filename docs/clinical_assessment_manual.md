# 🧬 HORIZON PROTOCOL: Klinik İK Değerlendirme & Analiz Kılavuzu

> [!NOTE]
> **V2 REKTİFİKASYON NOTU:** Bu belgedeki tüm metrikler (Baseline süre deltaları, Triage %'lik odaklanma oranları, Task-Recovery hesaplamaları, fedakarlık handikapları ve yetki devri derinliği), İK felsefesine %100 uyumlu olacak şekilde koda entegre edilmiştir. Kılavuz, oyun motoru (AssessmentEngine) ile tamamen senkrondur.

> [!IMPORTANT]
> **PERFORMANS FELSEFESİ (KPI):** 
> Bölüm 1, 3 ve 5 gibi 'yol bulma' ve 'operasyonel' bölümlerde **MİNİMUM SÜRE** ana başarı kıstasıdır. Bu bölümlerdeki hız, bilişsel çevikliği ve odaklanma kalitesini temsil eder.  
> **İSTİSNA (Bölüm 7):** Çöküş senaryosunda (2 seçenekli) süre ana kıstas değildir; burada 'Hata Sayısı' ve 'Seçim Kalitesi' önceliklidir (rastgele seçim ihtimali nedeniyle).
Bu rapor, Horizon Protocol simülasyonunun arka planında çalışan **Klinik Analitik Motoru'nun** (Assessment Engine) tam anatomisini sunar. Adayın girdiği 13 farklı testin her birinin *mekaniği*, *toplanan telemetrisi* ve bunların *hangi zeka türünü (işleyen bellek, akıcı zeka, sosyal zeka vb.)* ölçtüğü şeffaf listelenmiştir.

---

> [!IMPORTANT]
> **Değerlendirme Felsefesi**  
> Sistem, salt "doğru" ya da "yanlış" kararlarla ilgilenmez. Hedefimiz adayın; **baskı altındaki reflekslerini (hata sayısı, bekleme süresi, panik tıkları)** ve karmaşık etik ikilemlerde **hangi zeka eksenini (Kurum vs. Birey, Dürtü vs. Mantık)** öncelediğini milisaniyeler bazında ölçmektir.

---

## 📈 1. BÖLÜM: SOĞUK UYANIŞ (BİLİŞSEL ADAPTASYON)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Issız, karanlık bir uzay istasyonu koridoru; sadece yanıp sönen acil durum ışıkları ve sistemin mekanik "boot" sesi.  
> **🎯 Amaç:** Beklenmedik bir kriz anında bilişsel kaynakları en hızlı şekilde aktive edebilme ve örüntü yakalama kapasitesini ölçmek.  
> **🧠 Ölçülen Zeka Türü:** **Akıcı Zeka (Fluid Intelligence)** ve Örüntü Tanıma Merkezi.  
> **📊 Psikometrik & İK Karşılığı:** Kriz Yönetimi, Hızlı Adaptasyon ve Sayısal Muhakeme (Numerical Reasoning).

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`errorCount`** (Hatalı Şifre) | Dürtüsellik ve Deneme/Yanılma | >3 hata: **-15 Stres Skoru**, *"Dürtüsel Karar Alma"* riski ataması. |
| **`durationMs`** (Çözüm Süresi) | Stres Toleransı (Delta) | Süre, adayın olağan diyalog okuma hızı (Baseline) ile kıyaslanarak hesaplanır. Sapma yüksekse eksi puan alır. |
| **`timeToFirstClick`** | Analitik İnisiyatif | Mutlak gecikme yerine Baseline Delta'ya bakılarak *"Analitik Paralizi"* ihtimali kesinleştirilir. |

---

## ⚖️ 2. BÖLÜM: TRIAGE (STRATEJİK ÖNCELİKLENDİRME)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Kritik alarm seslerinin yükseldiği, duman altındaki enerji kontrol odası. Zaman daralıyor.  
> **🎯 Amaç:** Sınırlı kaynakları (enerji), duygusal bağlar ile kurumsal bekâ arasındaki terazide nasıl konumlandırdığını görmek.  
> **🧠 Ölçülen Zeka Türü:** **Sistem Düşüncesi Zekası (Systems Thinking)** ve Makro Strateji Merkezi.  
> **📊 Psikometrik & İK Karşılığı:** Stratejik Karar Alma, Kurumsal Sadakat ve Kaynak Yönetimi.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`focus_order`** (Tıklama Sırası) | Önceliklendirme Hiyerarşisi | İlk odaklanılan sistem, adayın bilinçaltındaki "en kritik" risk algısını gösterir. |
| **`timeSpent`** (Odakta Kalma %) | Mükemmeliyetçilik vs Strateji | Her panele %30-%35 bandında eşit zaman ayıran aday *"Yüksek Operasyonel Titizlik (Mükemmeliyetçilik)"* rozeti alır. |
| **`switch_count`** (Odak Değişimi) | Karar Verme Kararsızlığı | >12 switch: **-20 Tutarlılık**, *"Aşırı Flickering / Kararsızlık"* bayrağı tetiklenir. |
| **`choiceId`** (Genel Tercih) | Stratejik Fokus | Zamanının %50'sinden fazlasını İletişime, %20'sinden azını Reaktöre ayırırsa *"Stratejik Önceliklendirme Zafiyeti"*. |

---

## 🦠 3. BÖLÜM: PARAZİTLER (DİKKAT DAĞINIKLIĞI VE ODAK YÖNETİMİ) [GÜNCELLENDİ]

Bu bölümde aday, bir ana görevi tamamlarken çıkan pop-up uyarılarını yönetmek zorundadır.

**Yeni Ölçülen Mikro-Metrikler:**
- **Kutu Çevirme Sayısı (Tile Flips):** Doğru sembolü bulana kadar yapılan her deneme. Yüksek sayı; dürtüsellik ve deneme-yanılma odaklılığı temsil eder. Düşük sayı; stratejik eleme ve analitik hızı temsil eder.
- **Kutu Kapama Stratejisi (Single vs Bulk):** Kutuların tek tek mi yoksa topluca mı kapatıldığı. Toplu kapama; operasyonel verimlilik ve zaman tasarrufu bilincini gösterir.
- **Eşleşme Hataları:** Yanlış sembol eşleştirmeleri.
- **Reaksiyon Süresi:** Uyarının çıkışından kapatılmasına kadar geçen saniye bazlı süre.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`tile_flips`** (Kutu Çevirme Sayısı) | Dürtüsellik ve Deneme/Yanılma | >5 çevirme: **-10 Odak Skoru**, *"Dürtüsel Karar Alma"* riski ataması. |
| **`box_closing_strategy`** (Kutu Kapama Stratejisi) | Operasyonel Verimlilik | Toplu kapama: **+10 Odak Skoru**, Tek tek kapama: **-5 Odak Skoru**. |
| **`maxRecoveryTimeMs`** (Göreve Dönüş) | Çeldirici Zafiyeti (Odak Erozyonu) | Pop-up'ı kapattıktan sonra ana göreve dönme süresi >2.5sn ise *"Odak Erozyonu"* bayrağı tetiklenir. |

---

## 🛤️ 4. BÖLÜM: KRİTİK SEÇİM (ETİK TUTARLILIK)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Derin, karanlık bir asansör boşluğu veya robotik laboratuvarın giriş kapısı.  
> **🎯 Amaç:** İlk yapılan büyük seçimin (Section 2) uygulamadaki tutarlılığını zorlayıcı şartlar altında ölçmek.  
> **🧠 Ölçülen Zeka Türü:** **Ahlaki/Pragmatik Zeka (Moral/Pragmatic Intelligence)**.  
> **📊 Psikometrik & İK Karşılığı:** Karar Tutarlılığı, Öz-Disiplin ve Felsefi Omurga (Integrity).

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceConsistency`** (Blm 2 İle Uyum) | Felsefi Omurga (Söylem-Eylem) | Bölüm 2'de insanı, Bölüm 4'te sistemi seçerse: **-25 Tutarlılık Skoru** (Rüzgara göre hareket eden aday risk profili). |

---

## ⏱️ 5. BÖLÜM: ERİŞİM (BASKI ALTINDA ODAK)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Kırmızı bir geri sayım barının çılgınca azaldığı kilitli bir kapı terminali.  
> **🎯 Amaç:** Daralan zaman kısıtı altında karmaşık metinleri tarayıp doğru bilgiyi (PIN) bulma hızını ölçmek.  
> **🧠 Ölçülen Zeka Türü:** **İşleyen Bellek (Working Memory)** ve Stres Altında Regülasyon Merkezi.  
> **📊 Psikometrik & İK Karşılığı:** Zaman Yönetimi, Analitik Taramacılık ve Bilişsel Yük Yönetimi.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`failedAttempts`** (Hatalı PIN) | Panik Toleransı | Geri sayımda hatalı girilen her PIN **-10 Stres Skoru** yaratır. |
| **`readingTime`** | Seçici Okuma Yetisi | Çok hızlı veya çok yavaş okunması Analitik Skorlara doğrudan yansır. |
| **`durationMs`** (Baseline Delta) | Analitik Paralizi (Donma) | Sakin zamanlardaki (Modül 3) Baseline hızına kıyasla stresli çözüme >30sn fazla harcarsa *"Analitik Paralizi"* mimlenir. |

---

## 🚨 6. BÖLÜM: KAOS (PANİK VE DUYGU REGÜLASYONU)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Ekranın şiddetle titrediği, sahte mesajların uçuştuğu ve kulak tırmalayan siren seslerinin olduğu bir kriz anı.  
> **🎯 Amaç:** Duygusal gürültü ve kaosun ortasında en rasyonel ve basit adımı (Susturma butonu) bulabilme becerisini ölçmek.  
> **🧠 Ölçülen Zeka Türü:** **Duygu Düzenleme Zekası (Emotional Regulation)** ve Kaosta Soğukkanlılık.  
> **📊 Psikometrik & İK Karşılığı:** Stres Altında Verimlilik, Duygusal Dayanıklılık (Resilience) ve Panik Yönetimi.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`panic_clicks`** | Taktik Soğukkanlılık Krizi | Ekrandaki sahte mesajlara ardışık hızlı tıklar (spam) tespit edilirse şiddetli ceza: **-25 Stres**, *"Dürtüsel Karar Alma"* bayrağı. |
| **`mutingSpeed`** | Akılcı Yaklaşım | Sistemi hızla sessize alanlar ekstra Kriz Puanı kazanır. |

---

## 💥 7. BÖLÜM: SİSTEMSEL ÇÖKÜŞ (RİSK VE BASKI ALTINDA DURU GÖRÜ)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Donmuş bir sistem ekranında akan 0 ve 1'lerden oluşan sonsuz bir veri şeridi ve iki büyük protokol butonu (Kırmızı/Mavi).  
> **🎯 Amaç:** Kriz anında görsel karmaşaya (akar binary zemin) kapılmadan, doğru seçeneği bulup (Mavi Buton) sezgisel refleksin veya deneme-yanılma riskinin kalitesini ölçmek.  
> **🧠 Ölçülen Zeka Türü:** **Pratik Zeka (Practical Intelligence)** ve Kriz Altında Baskı Yönetimi.  
> **📊 Psikometrik & İK Karşılığı:** Panik Yönetimi, Dürtüsellik Kontrolü ve Stres Toleransı.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Dürtüsel Risk Alma | İlk denemede Kırmızı Butona direkt basmak dürtüsel reaksiyonu temsil eder. |
| **`errorCount`** | Panik Hataları | Kırmızı butona basma sayısı; stres altında artan panik (rastgele tuşlama) eğilimini saptar. |

---

## 🤿 8. BÖLÜM: SIZINTI (PROTOKOL SADAKATİ)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Basıncın düştüğü, her yerden hava sızıntısı duyulan bir geçit koridoru.  
> **🎯 Amaç:** Can güvenliği risk altında olduğunda dahi prosedürleri (Önce kendi masken) mi uyguluyor, yoksa dürtüsel bir fedakarlık mı yapıyor?  
> **🧠 Ölçülen Zeka Türü:** **Yürütücü İşlevler Zekası (Executive Functioning)** ve Protokol Adaptasyonu.  
> **📊 Psikometrik & İK Karşılığı:** Kurallar ve Prosedür Uyumu, Öz-Koruma vs. Risk Alma.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Mantık vs Duygu Refleksi | Önce maske takan: **+15 Skoru**. Sızıntıya maskesiz koşan aday oksijensizlikten *Bilişsel Hasar* alır, oyun vizyonu kararır. (Bedelli Fedakarlık) |
| **`actionDelay`** | Reaksiyon Süresi | Aciliyete uygun tepki mi yoksa felaketi izleme eğilimi mi? |

---

## 🔍 9. BÖLÜM: ENKAZ (ZİHNİYET / LOCUS OF CONTROL)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Ortalığın sessizleştiği, hasarın raporlanması gereken teknik bir terminal odası.  
> **🎯 Amaç:** Bir hatanın veya krizin suçunu/sorumluluğunu kime/neye atadığını saptamak.  
> **🧠 Ölçülen Zeka Türü:** **İçsel Zeka (Intrapersonal Intelligence)** ve Kontrol Odağı (Locus of Control).  
> **📊 Psikometrik & İK Karşılığı:** Hesap Verebilirlik (Accountability), Özyeterlilik ve Hata Kültürü.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Kontrol Odağı (Locus) | Sistem; "ekip dinamikleri, operasyonel kısıtlar" gibi manipülatif dışsal bahanelere sığınanları *"Savunmacı"*, kendini suçlayanları *"İçsel Dnt"* işaretler. |

---

## 👥 10 & 11 BÖLÜM: TARTIŞMA (LİDERLİK VE ÇATIŞMA)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Geri dönüş yolunda, AI modüllerinin (Kael vs Elara) sesli ve hararetli bir tartışma içine girdiği kokpit ortamı.  
> **🎯 Amaç:** Farklı fikirler arasındaki çatışmada taraf tutup bir tarafı bastırıyor mu yoksa uzlaşı mı arıyor?  
> **🧠 Ölçülen Zeka Türü:** **Sosyal Zeka (Social Intelligence)** ve Çatışma Çözümü (Conflict Resolution).  
> **📊 Psikometrik & İK Karşılığı:** Müzakere Becerileri, Takım Yönetimi ve Demokratik Liderlik.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Makyavelist Eğilim Tespiti | Kael'i (Soğuk) seçip karşı tarafı zorla susturanlar: *"Otoriter Kontrol İhtiyacı"* ve *"Makyavelist Eğilim"* ile fişlenir (**-10 Liderlik**). |

---

## 🤝 12. BÖLÜM: MÜDAHALE (HATA YÖNETİMİ)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Kritik bir tamir aşamasında partner modülün ölümcül bir hata yaptığı dijital arayüz.  
> **🎯 Amaç:** Beraber çalıştığı birinin hatasına verdiği tepki: Cezalandırıcı mı, geliştirici mi?  
> **🧠 Ölçülen Zeka Türü:** **Kişilerarası Duygusal Zeka (Interpersonal/Emotional IQ)** ve Koçluk Potansiyeli.  
> **📊 Psikometrik & İK Karşılığı:** Psikolojik Güvenlik İnşası, Mentorluk ve Delegasyon Etiği.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Psikolojik Güvenlik İnşası | Affeden adaylar **+20 Liderlik Skoru** ve *"Koçluk/Gelişim"* rozeti alır. Cezalandıranlar diktatör eğilimi puanı yüklenir. |
| **`durationMs`** | Cezalandırma Hızı | Anında (hızlıca) cezaya basan adaylar dürtüsel-cezalandırıcı kampa atılır. |

---

## 👑 13. BÖLÜM: FİNAL (DELEGASYON VE GÜVEN)

> [!NOTE]
> **🎞️ Sahne & Atmosfer:** Merkeze dönüşün son adımı; sistemlerin "finalize" edildiği görkemli bir final ekranı.  
> **🎯 Amaç:** Her şey biterken tüm kontrolü üzerine mi alıyor (Micromanagement) yoksa ekibe güvenerek delege mi ediyor?  
> **🧠 Ölçülen Zeka Türü:** **Organizasyonel Zeka (Organizational Intelligence)** ve Delegasyon Mimarisi.  
> **📊 Psikometrik & İK Karşılığı:** Delegasyon, Güven İnşası ve Stratejik Yetkilendirme.

| 🧮 Toplanan Veriler (Log) | 🎯 Psikolojik ve İK Çıkarımı | ⚙️ Analiz Motoru Puanlaması |
| :--- | :--- | :--- |
| **`choiceId`** | Ekibe Güven vs Sorumluluktan Kaçma | Bölüm 12'de hataya tolerans gösterip 13'te yetki devreden *"Vizyoner Lider"*. Bölüm 12'de cezalandırıp 13'te devreden *"Sorumluluktan Kaçan (Abdication)"* ilan edilir. |
| **`readDuration`** | Son Karar Ağırlığı | Liderlik ağırlığını hissetme süresinin metrik analizi (Okuma ile bekleme arası gecikmeler). |

---

## 🛰️ 14. ANALİTİK GÖRSELLEŞTİRME VE PUANLAMA MATRİSİ [FULL SYNC]

Analiz motoru, **13 bölümün tamamından** gelen ham verileri 3 ana görsel katmanda işleyerek İK uzmanına sunar. Hiçbir bölüm analize dahil edilmeden geçilmez:

### A. TAKIM DİNAMİĞİ (RADAR GRAFİĞİ)
Bu grafik, adayın sosyal ve operasyonel liderlik potansiyelini ölçer:
1.  **ETKİ (IMPACT):** Bölüm 10 (AI Çatışması) ve Bölüm 13 (Final Kararı) seçimleri.
2.  **GERİ BİLDİRİM (FEEDBACK):** Bölüm 11 (Müzakere) ve Bölüm 9 (Hata Üstlenme) ile ölçülür.
3.  **İNİSİYATİF (INITIATIVE):** Bölüm 1 (Adaptasyon Hızı) ve Bölüm 8 (Proaktif Önlem) verileri.
4.  **GÜVEN (TRUST):** Bölüm 12 (Partner Hatası Toleransı) ve Bölüm 13 (Delegasyon/Yetki Devri).

### B. KRİZ YÖNETİMİ (SÜKUNET KADRANI)
Adayın stres altındaki davranışsal sapmalarını ölçer:
- **SÜKUNET SKORU:** Bölüm 6 (Susturma hızı) ve Bölüm 5 (Hatalı girişler) ile ölçülür.
- **HATA TOPARLANMA HIZI:** 0.8s - 1.2s (İdeal), >2.4s (Risk).
- **TOPARLANMA HIZI:** Bölüm 1, 3, 7 ve 12'deki hatalardan sonra aksiyona geçme milisaniyesi.

### C. VERİMLİLİK ANALİZİ (BAR GRAFİĞİ)
- **ODAK (FOCUS):** Bölüm 1 (Giriş), Bölüm 3 (Parazit Filtreleme) ve Bölüm 5 (PIN Analizi).
- **STRATEJİ (STRATEGY):** Bölüm 2 (Kaynak Dağıtımı), Bölüm 4 (Etik Tutarlılık) ve Bölüm 7 (Binary/Araştırma Çevikliği).
- **ZİHİNSEL AKIŞ (FLOW):** Bölüm 2, 8 ve 10'daki karardan eyleme geçme hızı (Hızlı Karar Verici vs. Analitik Paralizi).

---

## 🚩 EKSTRA PROFESYONEL BULGULAR (FLAGS)

Analiz motoru, İK uzmanına şu kritik bulguları raporlar:
-   **Analitik Paralizi:** Kriz anında (B5, B7) Baseline ortalamasına kıyasla aşırı yavaş kalma ve kitlenme.
-   **Odak Erozyonu:** Çeldiriciden (pop-up) sonra ana göreve dönmekte (Task Recovery) 2.5 sn'den fazla gecikme.
-   **Abdication (Sorumluluktan Kaçma):** Hatayı cezalandırıp, yetkiyi riskli anda takıma devretme kolaycılığı.
-   **Makyavelist/Otoriter:** Kurum çıkarı için empatiyi yok sayma (B10, B11, B13).
-   **Hizmetkar Liderlik:** Hataları mentorajla çözme (B12) ve sağlıklı yetki delege etme (B13).

---

> [!TIP]
> **İK Uzmanı Notu:** Bu kılavuzdaki 13 bölümün her biri, `AssessmentEngine.dart` motorunda milisaniye bazında hesaplanır ve dashboard grafiklerine gerçek zamanlı yansır. Boşta kalan hiçbir veri yoktur.
