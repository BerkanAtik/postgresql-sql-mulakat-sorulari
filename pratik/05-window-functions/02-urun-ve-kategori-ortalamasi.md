# Ürün fiyatı ve kategori ortalaması

Zorluk: Kolay · Konu: `AVG() OVER (PARTITION BY ...)`

## Soru

Her ürünün yanına kendi kategorisinin ortalama fiyatını ve ürünün bu ortalamadan farkını yaz. Ürün adı, `kategori_id`, fiyat, kategori ortalaması ve fark kolonlarını göster. Ortalama ve fark virgülden sonra 2 hane olsun. Kategoriye, aynı kategoridekiler de fiyata göre pahalıdan ucuza sırala.

Doğru yaptıysan 50 satır gelir.

<details>
<summary>İpucu</summary>

`AVG`'yi `GROUP BY` ile kullanırsan ürünler kaybolur, her kategori tek satıra iner. `AVG`'yi bir window function olarak kullanabilirsin.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, kategori_id, fiyat,
       ROUND(AVG(fiyat) OVER (PARTITION BY kategori_id), 2)         AS kategori_ortalamasi,
       ROUND(fiyat - AVG(fiyat) OVER (PARTITION BY kategori_id), 2) AS fark
FROM urunler
ORDER BY kategori_id, fiyat DESC;
```

</details>

## Açıklama

`AVG`, `SUM`, `COUNT`, `MIN`, `MAX` gibi bildiğin toplama fonksiyonlarının hepsi `OVER` ile birlikte window function olarak da çalışıyor. `AVG(fiyat) OVER (PARTITION BY kategori_id)` "bu ürünün kategorisindeki bütün ürünlerin ortalaması" demek. Satır kaybolmuyor, her ürünün yanına kendi kategorisinin ortalaması geliyor.

Telefon kategorisine (6) bakarsan: ortalama 6.986,95 TL. X12 bu ortalamanın 12.012,05 TL üstünde, kılıf ise 6.837,05 TL altında.

Önceki modülün 2. sorusunu hatırlıyorsan, orada "kendi kategorisinin ortalamasından pahalı ürünleri" önce alt sorguyla, sonra `JOIN` ile bulmuştuk. Bu sorgu üçüncü yol: `fark` kolonu 0'dan büyük olan ürünleri sayarsan yine o 17 ürünü bulursun.

## Alternatif çözüm

Kategori ortalamalarını ayrı bir alt sorguda hesaplayıp `JOIN` ile de bağlayabilirsin:

```sql
SELECT u.ad, u.kategori_id, u.fiyat,
       ROUND(k.ortalama, 2)           AS kategori_ortalamasi,
       ROUND(u.fiyat - k.ortalama, 2) AS fark
FROM urunler AS u
JOIN (
    SELECT kategori_id, AVG(fiyat) AS ortalama
    FROM urunler
    GROUP BY kategori_id
) AS k ON k.kategori_id = u.kategori_id
ORDER BY u.kategori_id, u.fiyat DESC;
```

Sonuç birebir aynı. Window function'lı sürüm hem daha kısa hem de tabloyu bir kez okuyor. `JOIN`'li sürüm ise `urunler` tablosunu iki kez okuyor: bir kez ortalamalar için, bir kez de ürünler için. `EXPLAIN` ile bakarsan farkı görürsün.

## Sık yapılan hatalar

`GROUP BY` ile ürün adını seçmeye çalışmak. `SELECT ad, AVG(fiyat) FROM urunler GROUP BY kategori_id` yazarsan `column "urunler.ad" must appear in the GROUP BY clause` hatası alırsın. Gruplama her kategoriyi tek satıra indirdiği için ürün adlarını gösteremezsin. "Satır başına bir sonuç ama grubun bilgisiyle" istiyorsan aradığın şey window function.

<!-- beklenen-satir: 50 -->
