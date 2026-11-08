# Tarih kolonuna fonksiyon uygulamak

Zorluk: Orta · Konu: index'i bozan filtre, yarı açık aralık, expression index

## Soru

`ziyaretler` tablosunda `ziyaret_zamani` kolonunda index var. 15 Mart 2024 günü yapılan bütün ziyaretleri getirmen isteniyor. İlk aklına gelen `ziyaret_zamani::date = '2024-03-15'` yazmak. Bunu `EXPLAIN ANALYZE` ile çalıştır, index'in kullanılıp kullanılmadığına bak. Kullanılmıyorsa sorguyu index'i kullanacak şekilde yeniden yaz.

Sorgu 1372 satır döndürmeli.

Önce index'i oluştur:

```sql
CREATE INDEX idx_ziyaretler_zaman ON ziyaretler (ziyaret_zamani);
```

<details>
<summary>İpucu</summary>

Index kolonun kendisine göre sıralı. Kolonu bir fonksiyondan geçirince PostgreSQL index'i kullanamıyor. Kolonu olduğu gibi bırakıp karşı tarafı değiştirmen gerekiyor: gün başlangıcından ertesi günün başlangıcına kadar bir aralık.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
CREATE INDEX idx_ziyaretler_zaman ON ziyaretler (ziyaret_zamani);

SELECT *
FROM ziyaretler
WHERE ziyaret_zamani >= TIMESTAMP '2024-03-15'
  AND ziyaret_zamani <  TIMESTAMP '2024-03-16';
```

</details>

## Açıklama

Önce ilk akla gelen yazım:

```text
EXPLAIN ANALYZE
SELECT * FROM ziyaretler WHERE ziyaret_zamani::date = DATE '2024-03-15';

Gather
  ->  Parallel Seq Scan on ziyaretler
        Filter: ((ziyaret_zamani)::date = '2024-03-15'::date)
        Rows Removed by Filter: 166209
Execution Time: 35.3 ms
```

Index var ama kullanılmadı, bütün tablo okundu. Index `ziyaret_zamani` değerlerine göre sıralı. `ziyaret_zamani::date` ise başka bir değer. PostgreSQL bu dönüşümün sıralamayı bozmadığını bilemiyor, o yüzden index'e bakmıyor. Aynı durum `EXTRACT(MONTH FROM ziyaret_zamani) = 3`, `to_char(ziyaret_zamani, ...)` ya da `DATE_TRUNC(...)` için de geçerli.

Kolonu olduğu gibi bırakıp aralık yazınca:

```text
Index Scan using idx_ziyaretler_zaman on ziyaretler
  Index Cond: ((ziyaret_zamani >= '2024-03-15 00:00:00') AND (ziyaret_zamani < '2024-03-16 00:00:00'))
Execution Time: 0.25 ms
```

35 ms'den 0,25 ms'ye indi, yaklaşık 140 kat. İki sorgu da aynı 1372 satırı veriyor, sadece yazış biçimi farklı.

Aralığın **yarı açık** olduğuna dikkat et: başlangıç dahil (`>=`), bitiş hariç (`<`). Bitişi `<= '2024-03-15 23:59:59'` diye yazarsan 23:59:59 ile gece yarısı arasındaki kısım kaybolur. `BETWEEN` de iki ucu dahil ettiği için tarih-saat kolonlarında aynı tuzağa düşürür. Gün, ay ya da yıl, hangisi olursa olsun kalıp aynı: ilk anı dahil et, sonraki dönemin ilk anını hariç tut.

## Alternatif çözüm

Sorguyu değiştiremiyorsan (örneğin bir ORM hep `::date` üretiyorsa) index'i fonksiyonun kendisi için kurabilirsin. Buna **expression index** deniyor:

<details>
<summary>Çözümü göster</summary>

```sql
CREATE INDEX idx_ziyaretler_gun ON ziyaretler ((ziyaret_zamani::date));

SELECT *
FROM ziyaretler
WHERE ziyaret_zamani::date = DATE '2024-03-15';
```

</details>

Plan:

```text
Index Scan using idx_ziyaretler_gun on ziyaretler
  Index Cond: ((ziyaret_zamani)::date = '2024-03-15'::date)
Execution Time: 0.2 ms
```

Bu index sadece birebir aynı ifade için çalışır. `::date` için kurduysan, `EXTRACT(MONTH ...)` filtresine yaramaz. Ayrıca ek bir index daha demek, yani yazma maliyeti ve disk. Sorguyu kendin yazabiliyorsan aralık yöntemi daha ucuz, çünkü zaten var olan index'i kullanıyor.

## Sık yapılan hatalar

Index'i oluşturup "artık hızlıdır" diye planına bakmamak. Index var diye kullanıldığı anlamına gelmiyor, `EXPLAIN`'de `Index Scan` ya da `Bitmap Index Scan` görmen lazım.

Bitişi `<= '2024-03-15 23:59:59'` yazmak. `23:59:59.5` gibi bir kayıt dışarıda kalır. `ziyaret_zamani` saniyenin altını da tutabildiği için bu sadece teorik bir risk değil.

`WHERE ziyaret_zamani::date BETWEEN ... AND ...` yazmak. Hem fonksiyon yüzünden index gitmiş olur, hem de iki ucu dahil olur.

## Mülakatta

"Kolonda index var ama sorgu yavaş, neden?" sorusunun en tipik cevabı bu: `WHERE` içinde kolona fonksiyon uygulanmış. Cevabı iki parçada ver: kolonu çıplak bırakacak şekilde sorguyu yeniden yazarım, bu mümkün değilse expression index kurarım.

<!-- beklenen-satir: 1372 -->
