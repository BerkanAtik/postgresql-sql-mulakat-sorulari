# Modül 1: Temel sorgular

Tek bir tablodan veri çekmenin temelleri. Mülakatlar genelde buradan başlar ve en çok hata da burada, özellikle `NULL` ile tarihlerde yapılır.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Kısa konu özeti

Bir sorguyu şu sırayla yazarsın:

```sql
SELECT   ...   -- hangi kolonlar
FROM     ...   -- hangi tablo
WHERE    ...   -- hangi satırlar
ORDER BY ...   -- hangi sırayla
LIMIT    ...   -- kaç tane
```

Ama veritabanı bunları yazdığın sırayla çalıştırmaz. Önce `FROM` ile tabloyu bulur, `WHERE` ile satırları eler, sonra `SELECT` ile kolonları seçer, en son `ORDER BY` ve `LIMIT`'i uygular. `WHERE` içinde `SELECT`'te verdiğin takma adı (alias) kullanamamanın sebebi bu.

Bu modülde işine yarayacaklar:

| Ne için | Nasıl |
|---|---|
| Birkaç değerden biri | `sehir IN ('Ankara', 'İzmir')` |
| Aralık | `fiyat BETWEEN 100 AND 500` (iki ucu da dahil) |
| Metin içinde arama | `ad LIKE 'A%'` (A ile başlayanlar) |
| Boş mu? | `sehir IS NULL`, `sehir IS NOT NULL` |
| Tekrarları kaldırmak | `SELECT DISTINCT sehir` |
| Sıralama | `ORDER BY fiyat DESC` |
| İlk N satır | `LIMIT 5` |

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Üç büyük şehirdeki müşteriler](01-uc-buyuk-sehirdeki-musteriler.md) | Kolay | `IN`, `ORDER BY` |
| 2 | [İkinci en pahalı ürün](02-ikinci-en-pahali-urun.md) | Kolay | `LIMIT`, `OFFSET` |
| 3 | [Müşterilerin yaşadığı şehirler](03-musterilerin-sehirleri.md) | Kolay | `DISTINCT` |
| 4 | [Şehri boş olan müşteriler](04-sehri-bos-musteriler.md) | Kolay | `IS NULL` |
| 5 | [Ankara'da yaşamayan müşteriler](05-ankarada-yasamayanlar.md) | Orta | `NULL` tuzağı |
| 6 | [Mart ayında verilen siparişler](06-mart-ayi-siparisleri.md) | Orta | tarih aralığı |

Sırayla çözmeni öneririm, 5. ve 6. soru öncekilerde gördüklerinin üstüne kuruluyor.
