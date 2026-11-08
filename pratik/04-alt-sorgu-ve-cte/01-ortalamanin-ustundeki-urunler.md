# Ortalamanın üzerindeki ürünler

Zorluk: Kolay · Konu: alt sorgu (subquery), `AVG`

## Soru

Fiyatı, bütün ürünlerin ortalama fiyatından yüksek olan ürünlerin adını ve fiyatını listele. Pahalıdan ucuza sırala.

Doğru yaptıysan 10 satır gelir.

<details>
<summary>İpucu</summary>

Önce ortalama fiyatı tek başına bulan sorguyu yaz. Sonra bu sorguyu, ana sorgunun `WHERE`'inde bir sayı yerine kullanmayı dene.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, fiyat
FROM urunler
WHERE fiyat > (SELECT AVG(fiyat) FROM urunler)
ORDER BY fiyat DESC;
```

</details>

## Açıklama

Parantez içindeki `SELECT AVG(fiyat) FROM urunler` kendi başına çalışan ayrı bir sorgu. Tek satır ve tek kolon döndürüyor: 2315.562. Bu tür alt sorgulara skaler alt sorgu deniyor, çünkü sonucu tek bir değer ve bir sayı nerede kullanılabiliyorsa orada kullanılabiliyor. PostgreSQL önce alt sorguyu çalıştırıyor, sonra ana sorgu `WHERE fiyat > 2315.562` yazmışsın gibi devam ediyor.

Neden doğrudan `WHERE fiyat > AVG(fiyat)` yazamıyoruz? Gruplama modülünden hatırlarsan, `WHERE` tek tek satırlara bakarken ortalama henüz hesaplanmamış oluyor. Ortalamayı önce ayrı bir sorguda hesaplatıp sonucu kullanmak gerekiyor.

Sonuçta ilginç bir şey de var: 50 ürünün sadece 10'u ortalamanın üstünde. Birkaç pahalı ürün (bilgisayar, telefon) ortalamayı yukarı çekiyor. Ortadaki değer olan medyan fiyat sadece 849 TL. Raporlarda "ortalama" görünce bunu aklında tut.

## Sık yapılan hatalar

- `WHERE fiyat > AVG(fiyat)` yazmak. PostgreSQL `aggregate functions are not allowed in WHERE` hatası verir.
- Skaler olması gereken alt sorgudan birden fazla satır döndürmek. Örneğin `WHERE fiyat = (SELECT fiyat FROM urunler WHERE kategori_id = 6)` yazarsan alt sorgu 4 satır döner ve `more than one row returned by a subquery used as an expression` hatası alırsın. Birden fazla değerle karşılaştırman gerekiyorsa `=` yerine `IN` kullan.

<!-- beklenen-satir: 10 -->
