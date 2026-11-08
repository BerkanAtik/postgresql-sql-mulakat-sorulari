# Transaction ve eşzamanlılık

Uygulamalı tarafı [Modül 7'de](../pratik/07-transaction/README.md). Eşzamanlılık örneklerini iki `psql` oturumuyla aynı anda çalıştırarak denedim.

## 18. ACID nedir?

**Kısa cevap:** Bir transaction'ın güvenilir olması için sağlaması gereken dört özellik: **A**tomicity (ya hep ya hiç), **C**onsistency (kurallar bozulmaz), **I**solation (aynı anda çalışanlar birbirini bozmaz), **D**urability (commit edilen veri kaybolmaz).

| Harf | Anlamı | Örnek veritabanından |
|---|---|---|
| Atomicity | Transaction ya tamamen olur ya hiç olmaz | Sipariş kaydı, kalem ve stok düşümü: üçüncü adım hata verirse ilk ikisi de geri alınır ([Modül 7, soru 1](../pratik/07-transaction/01-siparis-olusturma.md)) |
| Consistency | Transaction veriyi geçerli bir durumdan başka bir geçerli duruma getirir | `CHECK (stok >= 0)` ihlal edilirse işlem reddedilir |
| Isolation | Aynı anda çalışan transaction'lar birbirinin yarım işini görmez | Isolation level'larla ayarlanır ([soru 19](#19-isolation-levellar-ve-anomaliler-nelerdir)) |
| Durability | Commit edildiyse sunucu çökse bile veri kalır | Değişiklikler önce WAL (write-ahead log) denen günlüğe yazılır |

**Consistency** en kaygan olanı. Burada veritabanı kısıtları (primary key, foreign key, `CHECK`) kuralları koruyor. "İş kuralı" tutarlılığını (örneğin toplam bakiye sabit kalsın) uygulama ya da transaction mantığı sağlıyor.

## 19. Isolation level'lar ve anomaliler nelerdir?

**Kısa cevap:** Aynı anda çalışan transaction'ların birbirinin değişikliklerini ne kadar görebileceğini belirleyen seviyeler. Seviye yükseldikçe anomali azalıyor ama yeniden deneme ve kaynak maliyeti artıyor.

Üç klasik anomali:

- **Dirty read:** Başkasının henüz commit etmediği veriyi okumak.
- **Non-repeatable read:** Aynı satırı transaction içinde iki kez okuyunca farklı değer görmek.
- **Phantom read:** Aynı aramayı iki kez yapınca farklı sayıda satır görmek.

PostgreSQL'de durum:

| Seviye | Dirty read | Non-repeatable read | Phantom read |
|---|---|---|---|
| `READ UNCOMMITTED` | Yok (`READ COMMITTED` gibi davranır) | Olabilir | Olabilir |
| `READ COMMITTED` (varsayılan) | Yok | Olabilir | Olabilir |
| `REPEATABLE READ` | Yok | Yok | Yok |
| `SERIALIZABLE` | Yok | Yok | Yok |

Denediklerim: `READ COMMITTED`'ta iki sorgu arasında başka biri commit edince aynı toplama sorgusu 6880 sonra 6875 verdi. `REPEATABLE READ`'de iki sefer de 6880. `READ UNCOMMITTED` ile açılan oturum, başkasının commit etmediği 999 değerini okumadı, eski 25'i okudu.

Standart `REPEATABLE READ`'de phantom'a izin veriyor, PostgreSQL vermiyor (snapshot kullandığı için). `REPEATABLE READ` ve `SERIALIZABLE`'da çakışma olunca `could not serialize access due to concurrent update` hatası alırsın, uygulamanın transaction'ı yeniden denemesi bekleniyor.

Ayrıntılı örnek: [Modül 7, soru 5](../pratik/07-transaction/05-isolation-level.md).

## 20. MVCC nedir?

**Kısa cevap:** Multi-Version Concurrency Control. Bir satır güncellendiğinde eskisinin üzerine yazmak yerine yeni bir sürüm oluşturuluyor, her transaction kendi başladığı andaki sürümü görüyor. Böylece **okuyanlar yazanları, yazanlar okuyanları bekletmiyor**.

Gözle görmek mümkün. Tek satırlık bir tabloda `UPDATE` öncesi ve sonrası:

```text
SELECT ctid, xmin FROM m;   →  (0,1)  827      -- güncellemeden önce
UPDATE m SET v = 11;
SELECT ctid, xmin FROM m;   →  (0,2)  828      -- sonra
```

`ctid` satırın tablodaki fiziksel konumu. Güncelleyince satır aynı yere yazılmadı, yeni bir konuma (0,2) yeni bir sürüm olarak yazıldı. `xmin` ise o sürümü oluşturan transaction'ın numarası.

Bunun sonuçları:

- Uzun bir rapor sorgusu çalışırken başkaları aynı tabloya yazabiliyor, kimse kimseyi beklemiyor (Modül 7'deki iki oturumlu denemelerde bunu gördük).
- Eski sürümler (dead tuple) tabloda birikiyor ve temizlenmesi gerekiyor: `VACUUM` ([soru 21](#21-vacuum-ne-işe-yarar)).
- `COUNT(*)` hazır bir sayıyı okuyamıyor, çünkü "kaç satır" sorusunun cevabı transaction'a göre değişebiliyor.

Aynı satırı iki transaction **yazmak** isterse yine biri ötekini bekler (satır kilidi).

## 21. VACUUM ne işe yarar?

**Kısa cevap:** `UPDATE` ve `DELETE` eski satır sürümlerini hemen silmez, "ölü" bırakır. `VACUUM` bu ölü satırların yerini yeniden kullanılabilir hâle getirir. PostgreSQL bunu kendi `autovacuum` süreciyle otomatik yapar.

500.000 satırlık `ziyaretler` tablosunda denedim:

| Adım | Tablo boyutu |
|---|---|
| Başlangıç | 30 MB |
| Bütün satırlara `UPDATE` | 60 MB (500.000 canlı + 500.000 ölü satır) |
| `VACUUM` | 60 MB (dosya küçülmedi) |
| İkinci `UPDATE` | 60 MB (ölü yerler yeniden kullanıldı, şişme devam etmedi) |
| `VACUUM FULL` | 30 MB |

Yani sıradan `VACUUM` dosyayı küçültmüyor, yeri bir sonraki yazma için boşaltıyor. Dosyayı gerçekten küçültmek için `VACUUM FULL` lazım ama o tabloyu işlem sırasında kilitliyor, canlı sistemde dikkatli kullanılır.

`VACUUM`'un diğer işleri: istatistikleri güncel tutmak için `ANALYZE` ile birlikte çalışır (planlayıcı doğru karar versin), ayrıca index-only scan'in dayandığı görünürlük haritasını güncelliyor.

**Devamında sorulabilir:** "`autovacuum` kapatılırsa ne olur?" Tablolar şişer, sorgular yavaşlar, çok uzun süre bakılmazsa transaction numarası döngüsü (wraparound) yüzünden veritabanı yazmayı reddedebilir. Kapatılmaz.

## 22. Kilitler, kayıp güncelleme ve deadlock nedir?

**Kısa cevap:** Aynı satırı iki işlem birden değiştirmek isterse PostgreSQL ikincisini bekletiyor (satır kilidi). Kilitler çakışmayı önlüyor ama yanlış sırayla alınınca iki işlem birbirini bekleyip kilitlenebiliyor: deadlock.

**Kayıp güncelleme (lost update):** Uygulama stoğu okuyup hesaplayıp yazarsa iki eşzamanlı işlemden birinin değişikliği kayboluyor. İki oturumla denedim: stok 25 iken iki satıştan sonra 23 olması gerekirken 24 kaldı. Çözümler:

- Hesabı veritabanına yaptırmak: `UPDATE urunler SET stok = stok - 1 WHERE urun_id = 5 AND stok >= 1` (sonuç 23).
- Okurken kilitlemek: `SELECT ... FOR UPDATE` (sonuç 23).

**Deadlock:** A işlemi önce 1 sonra 2 numaralı ürünü, B işlemi önce 2 sonra 1 numaralı ürünü güncellerse ikisi birbirini bekler. PostgreSQL yaklaşık 1 saniye sonra bunu fark edip birini `deadlock detected` hatasıyla iptal ediyor. Önlemek için kilitler her yerde aynı sırada alınır, transaction'lar kısa tutulur, hata alınca yeniden denenir.

İkisinin de adım adım anlatımı: [Modül 7, soru 4](../pratik/07-transaction/04-ayni-anda-stok-dusmek.md) ve [soru 6](../pratik/07-transaction/06-deadlock.md).
