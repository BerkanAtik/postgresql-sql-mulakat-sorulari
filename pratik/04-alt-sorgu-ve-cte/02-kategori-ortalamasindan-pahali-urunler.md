# Kendi kategorisinin ortalamasından pahalı ürünler

Zorluk: Orta · Konu: correlated subquery, `JOIN` ile alt sorgu

## Soru

Fiyatı, **kendi kategorisindeki** ürünlerin ortalama fiyatından yüksek olan ürünleri bul. Ürünün adını, kategori numarasını ve fiyatını listele. Kategori numarasına, aynı kategoridekileri de fiyata göre pahalıdan ucuza sırala.

Doğru yaptıysan 17 satır gelir.

<details>
<summary>İpucu</summary>

Bir önceki sorudaki alt sorgu bütün ürünlerin ortalamasını alıyordu. Bu sefer her ürün için, sadece o ürünle aynı kategorideki ürünlerin ortalaması lazım. Alt sorgu, ana sorgudaki ürünün `kategori_id`'sine bakabilir.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT u.ad, u.kategori_id, u.fiyat
FROM urunler AS u
WHERE u.fiyat > (
    SELECT AVG(u2.fiyat)
    FROM urunler AS u2
    WHERE u2.kategori_id = u.kategori_id
)
ORDER BY u.kategori_id, u.fiyat DESC;
```

</details>

## Açıklama

Bu alt sorgu bir öncekinden farklı. İçindeki `WHERE u2.kategori_id = u.kategori_id` satırı, dıştaki sorgunun `u` tablosuna atıfta bulunuyor. Yani alt sorgu tek başına çalışamaz, her seferinde "dışarıdaki ürün hangisi?" bilgisine ihtiyaç duyar. Buna correlated (ilişkili) subquery deniyor.

Mantığı şöyle düşünebilirsin: ana sorgu ürünleri tek tek geziyor. Her ürün için alt sorgu, o ürünün kategorisindeki ortalamayı hesaplıyor ve karşılaştırma yapılıyor. Örneğin Telefon kategorisinin (6) ortalaması 6.986,95 TL. Bu kategoride sadece iki akıllı telefon bu değerin üstünde, kılıf ve şarj adaptörü altında kalıyor.

Aynı tabloyu iki kez kullandığımız için takma adlar (`u` ve `u2`) şart. Yoksa hangi `kategori_id`'nin hangisi olduğu anlaşılmaz.

## Alternatif çözüm

Kategori ortalamalarını önce bir alt sorguda hesaplayıp sonucu `JOIN` ile bağlayabilirsin:

```sql
SELECT u.ad, u.kategori_id, u.fiyat
FROM urunler AS u
JOIN (
    SELECT kategori_id, AVG(fiyat) AS ortalama
    FROM urunler
    GROUP BY kategori_id
) AS k ON k.kategori_id = u.kategori_id
WHERE u.fiyat > k.ortalama
ORDER BY u.kategori_id, u.fiyat DESC;
```

Bu sürümde her kategori için ortalama bir kez hesaplanıyor ve okuyunca ne yaptığı daha kolay anlaşılıyor. Ortalamayı sonuçta görmek istersen `k.ortalama`'yı `SELECT`'e eklemek de çok kolay. Window functions modülünde aynı işi `AVG(...) OVER (PARTITION BY ...)` ile yapan üçüncü bir yol göreceğiz.

## Sık yapılan hatalar

Alt sorgudaki bağlantıyı (`WHERE u2.kategori_id = u.kategori_id`) unutmak. O zaman alt sorgu her ürün için bütün ürünlerin ortalamasını hesaplar ve bir önceki sorunun cevabı gelir, 17 yerine 10 satır görürsün. Hata vermediği için fark etmesi zor.

<!-- beklenen-satir: 17 -->
