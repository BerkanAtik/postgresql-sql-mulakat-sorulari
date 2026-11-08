# Her kategorinin en pahalı ürünü

Zorluk: Orta · Konu: grup başına ilk N kayıt, CTE ile `ROW_NUMBER`

## Soru

Her kategorinin en pahalı ürününü bul. Kategori adını, ürün adını ve fiyatını göster. En pahalı ürün en üstte olsun.

Doğru yaptıysan 12 satır gelir. Bunlar ürünü olan 12 alt kategori.

<details>
<summary>İpucu</summary>

İlk sorudaki sıra numarasını hesapla, sonra sadece sırası 1 olanları al. Ama window function'ın sonucunu aynı sorgunun `WHERE`'inde kullanamazsın. Hesabı bir CTE'ye koyup dışarıdan süzmen gerekiyor.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH sirali AS (
    SELECT ad, kategori_id, fiyat,
           ROW_NUMBER() OVER (PARTITION BY kategori_id ORDER BY fiyat DESC) AS sira
    FROM urunler
)
SELECT k.ad AS kategori, s.ad AS urun, s.fiyat
FROM sirali AS s
JOIN kategoriler AS k ON k.kategori_id = s.kategori_id
WHERE s.sira = 1
ORDER BY s.fiyat DESC;
```

</details>

## Açıklama

"Her gruptan en iyi N tanesi" mülakatların en sevdiği kalıplardan biri: her kategorinin en pahalı ürünü, her müşterinin son siparişi, her departmanın en yüksek maaşlısı. Hepsi aynı şekilde çözülüyor:

1. Window function ile grup içinde sıra numarası ver.
2. Bunu bir CTE'ye (ya da `FROM` içinde bir alt sorguya) koy.
3. Dışarıda `WHERE sira = 1` (ya da `sira <= 3`) ile süz.

Neden ikinci adım gerekli? Sorgunun çalışma sırasını hatırla: `WHERE`, `SELECT`'ten önce çalışıyor. Window function'lar ise `SELECT` aşamasında hesaplanıyor. Yani `WHERE` çalışırken sıra numarası henüz yok. CTE'nin içinde hesaplayınca dıştaki sorgu için o artık sıradan bir kolon oluyor.

İlk N için `sira <= 3` yazman yeterli, her kategorinin en pahalı üç ürünü gelir.

## Alternatif çözüm

PostgreSQL'e özel `DISTINCT ON` ile çok kısa yazılabilir:

```sql
SELECT DISTINCT ON (u.kategori_id)
       k.ad AS kategori, u.ad AS urun, u.fiyat
FROM urunler AS u
JOIN kategoriler AS k ON k.kategori_id = u.kategori_id
ORDER BY u.kategori_id, u.fiyat DESC;
```

`DISTINCT ON (u.kategori_id)` her kategoriden sadece **ilk** satırı tutuyor. Hangisinin ilk olacağını `ORDER BY` belirliyor, burada fiyatı en yüksek olan. Kuralı şu: `ORDER BY` `DISTINCT ON`'daki kolonla başlamak zorunda. Bu yüzden sonuç kategori numarasına göre sıralı geliyor. Fiyata göre sıralamak istersen bu sorguyu bir alt sorgu içine alıp dışarıda yeniden sıralaman gerekiyor.

Kısa ve hızlı ama başka veritabanlarında yok. İlk N için (`<= 3` gibi) de işe yaramıyor, sadece ilk satırı veriyor. Mülakatta `ROW_NUMBER` çözümünü yazıp bunu "PostgreSQL'de böyle de yapılabilir" diye eklemek iyi olur.

## Sık yapılan hatalar

- Window function'ı doğrudan `WHERE`'e yazmak. `WHERE ROW_NUMBER() OVER (...) = 1` yazarsan `window functions are not allowed in WHERE` hatası alırsın.
- Takma adı `WHERE`'de kullanmaya çalışmak. `SELECT ..., ROW_NUMBER() OVER (...) AS sira FROM urunler WHERE sira = 1` de `column "sira" does not exist` hatası verir. Sebebi aynı: `WHERE` çalışırken `sira` henüz hesaplanmamış.

<!-- beklenen-satir: 12 -->
