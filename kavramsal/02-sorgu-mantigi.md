# Sorgu mantığı

`SELECT` yazarken hep karıştırılan kavramlar. Pratik tarafı [pratik/](../pratik/) altındaki modüllerde, burada nasıl anlatacağına bakıyoruz.

## 7. Bir SQL sorgusu hangi sırayla çalışır?

**Kısa cevap:** Yazış sırası ile çalışma sırası aynı değil. Mantıksal sıra: `FROM` (ve `JOIN`), `WHERE`, `GROUP BY`, `HAVING`, `SELECT`, `DISTINCT`, `ORDER BY`, `LIMIT`.

```sql
SELECT kategori_id, COUNT(*) AS adet      -- 5. kolonlar ve alias'lar hesaplanır
FROM urunler                              -- 1. tablo
WHERE aktif                               -- 2. satırlar süzülür
GROUP BY kategori_id                      -- 3. gruplanır
HAVING COUNT(*) > 3                       -- 4. gruplar süzülür
ORDER BY adet DESC                        -- 6. sıralanır
LIMIT 5;                                  -- 7. ilk 5
```

Bu sıranın sonuçları:

- `SELECT`'te verdiğin alias `WHERE`'de ve `HAVING`'de kullanılamaz, çünkü `SELECT` daha sonra çalışıyor. Denedim: `WHERE cift > 100` ve `HAVING n > 3` ikisi de `column does not exist` verdi.
- Alias `ORDER BY`'da kullanılabilir (aynı sorguda `ORDER BY cift DESC` çalıştı).
- Window function'lar `SELECT` aşamasında hesaplandığı için `WHERE`'de kullanılamaz, CTE ya da alt sorgu gerekir ([Modül 5](../pratik/05-window-functions/README.md)).

Yukarıdaki tablodaki sıra mantıksal. Veritabanı sonucu aynı verdiği sürece daha farklı bir sırayla çalıştırabilir (örneğin filtreyi `JOIN`'den önce uygulayabilir).

## 8. WHERE ile HAVING arasındaki fark nedir?

**Kısa cevap:** `WHERE` gruplamadan **önce** satırları süzer, `HAVING` gruplamadan **sonra** grupları süzer. Toplama fonksiyonu içeren koşul sadece `HAVING`'e yazılabilir.

```sql
-- iptal edilmemiş siparişleri say (satır süzme, WHERE)
-- ve 10'dan fazla siparişi olan müşterileri bırak (grup süzme, HAVING)
SELECT musteri_id, COUNT(*) AS siparis_sayisi
FROM siparisler
WHERE durum <> 'iptal'
GROUP BY musteri_id
HAVING COUNT(*) > 10;
```

Ne zaman hangisi? Gruplamaya girmesini istemediğin satırları `WHERE` ile erkenden ele, çünkü hem daha az veri işlenir hem daha okunur olur. `HAVING`'i sadece grup sonucuna bağlı koşullar için kullan (`COUNT(*) > 10`, `SUM(...) > 5000`).

**Devamında:** "GROUP BY olmadan HAVING kullanılır mı?" Evet, bütün tablo tek grup sayılır. Ama pek anlamlı değil.

## 9. JOIN türleri arasındaki fark nedir?

**Kısa cevap:** `INNER JOIN` iki tarafta da eşleşen satırları getirir. `LEFT JOIN` soldaki tablonun hepsini, eşleşme yoksa sağ taraf `NULL` olarak getirir. `RIGHT JOIN` tersi. `FULL JOIN` iki tarafın hepsini. `CROSS JOIN` her satırı her satırla eşleştirir.

200 müşteri, 1000 sipariş olan örnek veritabanında:

| Sorgu | Satır sayısı | Neden |
|---|---|---|
| `musteriler INNER JOIN siparisler` | 1000 | Her siparişin müşterisi var |
| `musteriler LEFT JOIN siparisler` | 1020 | + hiç siparişi olmayan 20 müşteri |
| `musteriler FULL JOIN siparisler` | 1020 | Siparişsiz müşteri var, müşterisiz sipariş yok |
| 18 kategori `CROSS JOIN` 3 satır | 54 | 18 × 3 |

İpuçları:

- Pratikte en çok `INNER` ve `LEFT` kullanılır. `RIGHT JOIN`, tabloların yerini değiştirip `LEFT JOIN` yazarak hep ifade edilebilir, çoğu kod tabanında görmezsin.
- "Hiç siparişi olmayan müşteriler" tipi sorular `LEFT JOIN ... WHERE sag.kolon IS NULL` (ya da `NOT EXISTS`) ile çözülür: 20 satır.
- `LEFT JOIN`'de sağ tabloya ait koşulu `WHERE`'e yazarsan `INNER JOIN`'e dönüşür, çünkü `NULL` satırlar elenir. Koşul `ON` içinde olmalı. İstisnası eşi olmayan satırları bulmak için yazılan `WHERE sag.id IS NULL` kontrolü, o bilerek `WHERE`'de durur. Bunun detayı [Modül 3'te](../pratik/03-join/README.md).
- `CROSS JOIN` istemeden de olur: `JOIN` yazıp `ON` koşulunu unutursan satır sayısı çarpılır.

## 10. UNION ile UNION ALL arasındaki fark nedir?

**Kısa cevap:** İkisi de iki sorgunun sonucunu alt alta birleştirir. `UNION` tekrar eden satırları eler, `UNION ALL` hepsini olduğu gibi bırakır. `UNION ALL` daha hızlıdır çünkü tekrar arayıp elemekle uğraşmaz.

`musteriler.sehir` kolonunu kendisiyle birleştirince:

| | Satır sayısı |
|---|---|
| `UNION ALL` | 400 (200 + 200) |
| `UNION` | 9 (8 farklı şehir + `NULL`) |

Tekrarın olmayacağını biliyorsan (ya da olmasını istiyorsan) `UNION ALL` yaz, varsayılan olarak `UNION` yazma. Aksi hâlde veritabanı gereksiz yere sıralama ya da hash işlemi yapar.

Kurallar: iki sorgunun kolon sayısı aynı olmalı, kolon tipleri uyumlu olmalı, kolon adları ilk sorgudan gelir.

Benzer işleyen ama farklı işi yapan iki tane daha var: `INTERSECT` (ikisinde de olanlar), `EXCEPT` (ilkinde olup ikincisinde olmayanlar).

## 11. IN ile EXISTS arasındaki fark nedir? NOT IN neden tehlikeli?

**Kısa cevap:** Sonuç olarak çoğu zaman aynı satırları getirirler. `IN` bir değerin listede olup olmadığına, `EXISTS` bir alt sorgunun en az bir satır döndürüp döndürmediğine bakar. Asıl fark `NOT IN` ile `NOT EXISTS` arasında, `NULL` yüzünden.

Siparişi olan müşterileri bulmak için iki yol da aynı sonucu verdi: 180 satır.

```sql
WHERE musteri_id IN (SELECT musteri_id FROM siparisler)
WHERE EXISTS (SELECT 1 FROM siparisler s WHERE s.musteri_id = m.musteri_id)
```

Performans için de ikisi arasında fark yok: `EXPLAIN` ile baktığımda PostgreSQL 17 ikisi için de birebir aynı planı çıkardı (`Hash Join`, alt sorgu tarafında `HashAggregate`). "EXISTS her zaman daha hızlı" diye bir kural yok, yine de kendi sorgunda `EXPLAIN` ile bak.

`NOT IN` tuzağı: alt sorgunun sonucunda **tek bir `NULL`** varsa, `NOT IN` hiçbir satır döndürmez, çünkü `x NOT IN (1, 2, NULL)` bilinmeyen bir sonuç veriyor. Denedim: `musteri_id NOT IN (SELECT NULL::int)` 0 satır döndürdü.

Bu yüzden "hiç siparişi olmayan müşteriler" için `NOT EXISTS` kullanmak daha güvenli (20 satır). `NOT IN` ancak alt sorgunun kolonunun `NOT NULL` olduğundan eminsen güvenli. Planlar da farklı: `NOT EXISTS` için `Hash Anti Join` çıkıyor, `NOT IN` için ise her satırda alt sorgu sonucuna bakan bir `SubPlan`.

## 12. COUNT(\*), COUNT(kolon) ve COUNT(DISTINCT kolon) farkı nedir?

**Kısa cevap:** `COUNT(*)` bütün satırları sayar. `COUNT(kolon)` o kolonun `NULL` olmadığı satırları sayar. `COUNT(DISTINCT kolon)` `NULL` olmayan farklı değerleri sayar.

`siparisler` tablosunda `kupon_kodu` kolonu için:

| İfade | Sonuç | Anlamı |
|---|---|---|
| `COUNT(*)` | 1000 | Toplam sipariş |
| `COUNT(kupon_kodu)` | 241 | Kupon kullanılan sipariş |
| `COUNT(DISTINCT kupon_kodu)` | 2 | Kullanılan farklı kupon sayısı |

`COUNT(1)` ile `COUNT(*)` aynı şeydir, birbirinden hızlı değil. `COUNT(*)` yazmak daha okunur.

**Devamında:** "Tablodaki satır sayısını en hızlı nasıl alırsın?" PostgreSQL'de `COUNT(*)` büyük tabloda tam tarama gerektirebilir (MVCC yüzünden satır sayısını hazır tutmuyor). Yaklaşık bir sayı yetiyorsa `pg_class.reltuples` kullanılabilir.
