# Modül 4: Alt sorgular ve CTE

Bir sorgunun içine başka bir sorgu yazmak. "Ortalamanın üstündekiler", "hiç şunu yapmamış olanlar", "önce şunu hesapla, sonra ona göre süz" gibi iki adımlı soruların hepsi buraya çıkıyor. CTE (`WITH`) ile de bu adımları okunur hâle getiriyoruz.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Kısa konu özeti

Alt sorgunun nerede kullanıldığına göre farklı adları var:

| Nerede | Örnek | Ne döndürmeli |
|---|---|---|
| `WHERE` içinde tek değer olarak | `fiyat > (SELECT AVG(fiyat) FROM urunler)` | Tek satır, tek kolon |
| `IN` / `NOT IN` ile | `musteri_id IN (SELECT musteri_id FROM siparisler)` | Tek kolon, çok satır olabilir |
| `EXISTS` / `NOT EXISTS` ile | `EXISTS (SELECT 1 FROM ... WHERE ...)` | Ne döndürdüğü önemsiz, satır var mı yok mu |
| `FROM` içinde tablo gibi | `FROM (SELECT ...) AS t` | Takma ad vermek şart |

Alt sorgu dıştaki sorgunun bir kolonuna atıfta bulunuyorsa (`WHERE u2.kategori_id = u.kategori_id` gibi) buna correlated subquery denir. Dıştaki her satır için yeniden değerlendirilir.

CTE, bir alt sorguya isim vermenin yolu:

```sql
WITH ara_sonuc AS (
    SELECT ...
)
SELECT ... FROM ara_sonuc;
```

Virgülle birden fazla CTE tanımlayabilirsin, sonrakiler öncekileri kullanabilir. `WITH RECURSIVE` ise kendine atıfta bulunan, hiyerarşik veriyi gezmeye yarayan özel bir CTE.

Akılda tutman gereken en önemli şey: alt sorgu `NULL` döndürebiliyorsa `NOT IN` hiç satır döndürmeyebilir. "Olmayanları" ararken `NOT EXISTS` daha güvenli.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Ortalamanın üzerindeki ürünler](01-ortalamanin-ustundeki-urunler.md) | Kolay | skaler alt sorgu |
| 2 | [Kendi kategorisinin ortalamasından pahalı ürünler](02-kategori-ortalamasindan-pahali-urunler.md) | Orta | correlated subquery |
| 3 | [Kimseyi yönetmeyen çalışanlar](03-kimseyi-yonetmeyen-calisanlar.md) | Orta | `NOT IN` ve `NULL` tuzağı |
| 4 | [Kitap sipariş eden müşteriler](04-kitap-siparis-eden-musteriler.md) | Orta | `EXISTS` |
| 5 | [Ortalamanın üzerindeki siparişler](05-ortalamanin-ustundeki-siparisler.md) | Orta | CTE |
| 6 | [Müşteri segmentleri](06-musteri-segmentleri.md) | Zor | birden fazla CTE, `CASE` |
| 7 | [Yönetim zinciri](07-yonetim-zinciri.md) | Zor | `WITH RECURSIVE` |

3. soru bu modülün en önemli tuzağı. 6. soru da önceki modüllerde gördüğün neredeyse her şeyi bir araya getiriyor.
