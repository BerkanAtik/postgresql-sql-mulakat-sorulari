# ROW_NUMBER, RANK ve DENSE_RANK farkı

Zorluk: Orta · Konu: `ROW_NUMBER`, `RANK`, `DENSE_RANK`

## Soru

Çalışanları maaşa göre yüksekten düşüğe sırala ve her çalışan için üç farklı sıra numarası göster: `ROW_NUMBER`, `RANK` ve `DENSE_RANK`. Ad, soyad ve maaşı da yaz. Eşit maaşlı çalışanlarda `ROW_NUMBER` her seferinde aynı sonucu versin diye, eşitlik durumunda çalışan numarası küçük olan önce gelsin.

Doğru yaptıysan 15 satır gelir.

<details>
<summary>İpucu</summary>

Aynı sorguda üç ayrı window function yazabilirsin. Eşitlik kuralı sadece `ROW_NUMBER` için gerekli. Diğer ikisine aynı kuralı verirsen eşitlikleri göremezsin.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, soyad, maas,
       ROW_NUMBER() OVER (ORDER BY maas DESC, calisan_id) AS row_number,
       RANK()       OVER (ORDER BY maas DESC)             AS rank,
       DENSE_RANK() OVER (ORDER BY maas DESC)             AS dense_rank
FROM calisanlar
ORDER BY maas DESC, calisan_id;
```

</details>

## Açıklama

Aslı ve Gökhan'ın maaşı aynı (24.000 TL). Sonucun son üç satırına bakınca farkı net görürsün:

| Çalışan | Maaş | `ROW_NUMBER` | `RANK` | `DENSE_RANK` |
|---|---|---|---|---|
| Aslı | 24.000 | 13 | 13 | 13 |
| Gökhan | 24.000 | 14 | 13 | 13 |
| Berk | 22.000 | 15 | 15 | 14 |

- `ROW_NUMBER` eşitliğe bakmaz, herkese farklı bir numara verir. Aslı 13, Gökhan 14.
- `RANK` eşitlere aynı sırayı verir, sonra eşit sayısı kadar numara atlar. İkisi de 13, Berk 15 (14 atlandı). Spor müsabakalarındaki sıralama gibi: iki kişi ikinci olursa üçüncü olmaz, sonraki dördüncüdür.
- `DENSE_RANK` eşitlere aynı sırayı verir ama numara atlamaz. İkisi de 13, Berk 14.

`ROW_NUMBER`'ın `ORDER BY`'ına `calisan_id` ekledik, çünkü yoksa Aslı ile Gökhan'dan hangisinin 13 hangisinin 14 olacağı belli değil, her çalıştırmada değişebilir. `RANK` ve `DENSE_RANK`'e bunu eklemedik. Ekleseydik ikisinin sıralaması artık eşit sayılmazdı ve fark kaybolurdu.

## Birinci modüle dönüş

Birinci modülün 2. sorusunda "ikinci en pahalı ürün"ü `LIMIT 1 OFFSET 1` ve alt sorguyla bulmuştuk, üçüncü bir yol da `DENSE_RANK` demiştik. İşte o yol:

```text
SELECT ad, fiyat
FROM (
    SELECT ad, fiyat, DENSE_RANK() OVER (ORDER BY fiyat DESC) AS sira
    FROM urunler
) AS t
WHERE sira = 2;
```

`DENSE_RANK` aynı fiyatlı ürünlere aynı sırayı verdiği için bu sorgu gerçekten "ikinci en yüksek fiyattaki bütün ürünleri" getiriyor. En pahalı iki ürün aynı fiyatta olsaydı bile doğru cevabı verirdi. Bizim veride sonuç Akıllı Telefon X12.

## Mülakatta

"`RANK` ile `DENSE_RANK` arasındaki fark ne?" en sık sorulan window function sorularından biri. Yukarıdaki tabloyu anlatabilmen yeterli. Arkasından genelde "ikinci en yüksek maaşı bul" gelir. `DENSE_RANK() ... = 2` diye cevap verip neden `ROW_NUMBER` değil de `DENSE_RANK` kullandığını açıklayabilirsen soru tamamdır.

<!-- beklenen-satir: 15 -->
