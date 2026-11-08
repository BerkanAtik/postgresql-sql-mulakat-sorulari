# Bir önceki aya göre değişim

Zorluk: Orta · Konu: `LAG`, yüzde hesabı, tam sayı bölmesi

## Soru

Her ay için o aydaki sipariş sayısını, bir önceki ayın sipariş sayısını ve önceki aya göre yüzde değişimi göster. Yüzde, virgülden sonra 1 hane olsun. Aylara göre sırala. Bu soruda bütün siparişleri say, iptaller dahil.

Doğru yaptıysan 12 satır gelir. Ocak'ın öncesi olmadığı için o satırda önceki ay ve değişim boş olmalı. Şubat'ta değişim %28,3 çıkmalı.

<details>
<summary>İpucu</summary>

Bir satırdan önceki satırın değerini getiren bir window function var. Yüzdeyi hesaplarken sonuç 0 çıkıyorsa, `COUNT`'un döndürdüğü sayının tipine bak.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH aylik AS (
    SELECT date_trunc('month', siparis_tarihi)::date AS ay,
           COUNT(*)                                  AS siparis_sayisi
    FROM siparisler
    GROUP BY ay
)
SELECT ay, siparis_sayisi,
       LAG(siparis_sayisi) OVER (ORDER BY ay) AS onceki_ay,
       ROUND(
           100.0 * (siparis_sayisi - LAG(siparis_sayisi) OVER (ORDER BY ay))
                 / LAG(siparis_sayisi) OVER (ORDER BY ay),
           1
       ) AS degisim_yuzde
FROM aylik
ORDER BY ay;
```

</details>

## Açıklama

`LAG(siparis_sayisi) OVER (ORDER BY ay)`, aylar sıralandığında bir önceki satırın `siparis_sayisi` değerini getiriyor. Şubat satırında Ocak'ın değeri (46), Mart satırında Şubat'ın değeri (59) geliyor. Ocak'tan önce satır olmadığı için Ocak'ta `NULL` dönüyor. `NULL` ile yapılan her hesap da `NULL` olduğu için Ocak'ın değişimi de boş kalıyor, bu doğru davranış.

Tersini yapan bir de `LEAD` var, bir **sonraki** satırın değerini getiriyor. İkisine de ikinci bir parametre verebilirsin: `LAG(siparis_sayisi, 12)` on iki satır önceyi, yani aylık veride geçen yılın aynı ayını getirir.

Yüzde hesabındaki `100.0` gereksiz bir detay gibi duruyor ama değil, aşağıdaki hataya bak.

## Alternatif çözüm

`LAG`'i üç kez yazmak yerine önce ayrı bir CTE'de hesaplayıp sonra kullanabilirsin:

```sql
WITH aylik AS (
    SELECT date_trunc('month', siparis_tarihi)::date AS ay,
           COUNT(*)                                  AS siparis_sayisi
    FROM siparisler
    GROUP BY ay
),
karsilastirma AS (
    SELECT ay, siparis_sayisi,
           LAG(siparis_sayisi) OVER (ORDER BY ay) AS onceki_ay
    FROM aylik
)
SELECT ay, siparis_sayisi, onceki_ay,
       ROUND(100.0 * (siparis_sayisi - onceki_ay) / onceki_ay, 1) AS degisim_yuzde
FROM karsilastirma
ORDER BY ay;
```

Uzun ama formül çok daha okunaklı. Gerçek işte ben bunu tercih ederim.

## Sık yapılan hatalar

**Tam sayı bölmesi.** `COUNT` bir `bigint`, yani tam sayı döndürüyor. İki tam sayıyı böldüğünde PostgreSQL sonucu da tam sayı yapıyor ve küsuratı atıyor. `(siparis_sayisi - onceki_ay) / onceki_ay * 100` yazarsan Şubat için `(59 - 46) / 46` = `13 / 46` = 0 olur, 0 × 100 de 0. Bütün aylar 0 görünür. `100.0` ile başlamak hesabı ondalıklı sayıya çeviriyor. `::numeric` ile dönüştürmek de aynı işi görür.

**Sıfıra bölme.** Bizim veride hiçbir ay 0 sipariş almıyor, ama gerçek veride önceki ay 0 olursa `division by zero` hatası alırsın. Bölen kısmı `NULLIF(onceki_ay, 0)` ile yazarsan 0 yerine `NULL` olur ve sonuç hata vermeden boş döner.

## Mülakatta

"Bu ay geçen aya göre ne kadar arttı?" tarzı sorular veri analisti mülakatlarında neredeyse her zaman gelir. `LAG` ile cevap verip, tam sayı bölmesi ve sıfıra bölme risklerinden de bahsedersen detaylara dikkat ettiğini göstermiş olursun.

<!-- beklenen-satir: 12 -->
