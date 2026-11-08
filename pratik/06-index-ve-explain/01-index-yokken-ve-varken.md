# Index yokken ve varken

Zorluk: Kolay · Konu: `CREATE INDEX`, Seq Scan, `EXPLAIN ANALYZE`

## Soru

`ziyaretler` tablosunda 42 numaralı müşterinin bütün ziyaretlerini getiren sorguyu yaz. Önce `EXPLAIN ANALYZE` ile planına ve süresine bak. Sonra `musteri_id` kolonuna bir index oluştur ve aynı planı tekrar al. Plan ve süre nasıl değişti?

Sorgu 2500 satır döndürmeli.

<details>
<summary>İpucu</summary>

`EXPLAIN ANALYZE`'ı sorgunun başına yazıyorsun, sorguyu değiştirmen gerekmiyor. Index için `CREATE INDEX isim ON tablo (kolon)` yeter.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
-- önce index yokken planı gör:
-- EXPLAIN ANALYZE SELECT * FROM ziyaretler WHERE musteri_id = 42;

CREATE INDEX idx_ziyaretler_musteri ON ziyaretler (musteri_id);

SELECT *
FROM ziyaretler
WHERE musteri_id = 42;
```

Plan için sorgunun başına `EXPLAIN ANALYZE` yaz, index'i oluşturmadan önce bir kere, sonra bir kere.

</details>

## Açıklama

Index yokken plan şöyle (kısaltılmış):

```text
Gather
  ->  Parallel Seq Scan on ziyaretler
        Filter: (musteri_id = 42)
        Rows Removed by Filter: 165833
Execution Time: 30.6 ms
```

PostgreSQL 42 numaralı müşteriyi bulmak için bütün tabloyu okudu. Her işçi yaklaşık 166 bin satırı filtreleyip attı, geriye 2500 satır kaldı (`Parallel` olduğu için tabloyu 3 kişi bölüşüyor). Benim makinemde 25 ile 35 ms arası.

Index'ten sonra:

```text
Bitmap Heap Scan on ziyaretler
  Recheck Cond: (musteri_id = 42)
  ->  Bitmap Index Scan on idx_ziyaretler_musteri
        Index Cond: (musteri_id = 42)
Execution Time: 1.5 ms
```

Artık tabloyu baştan sona okumuyor. Önce index'ten 42 numaralı müşterinin satırlarının hangi sayfalarda olduğunu topluyor (`Bitmap Index Scan`), sonra sadece o sayfaları okuyor (`Bitmap Heap Scan`). Yaklaşık 1,5 ile 2 ms, yani 15-20 kat daha hızlı.

Neden `Index Scan` değil de `Bitmap`? 2500 satır tabloda dağınık duruyor. Her birine tek tek gitmek yerine, önce hangi sayfalarda olduklarını toplayıp sayfaları sırayla okumak daha ucuz. Tek bir satır arasan `Index Scan` görürsün. Birincil anahtar zaten otomatik index'li, o yüzden şu sorgu hemen cevap veriyor:

```text
EXPLAIN ANALYZE SELECT * FROM ziyaretler WHERE ziyaret_id = 250000;

Index Scan using ziyaretler_pkey on ziyaretler
Execution Time: 0.02 ms
```

Index'in bedeli de var. Bu index diskte 3,4 MB yer tutuyor (tablo 30 MB), ayrıca her `INSERT`, `UPDATE` ve `DELETE` index'i de güncellemek zorunda. Her kolona index koymak bu yüzden iyi fikir değil. Sorgularda gerçekten `WHERE`, `JOIN` ya da `ORDER BY` ile kullandığın kolonlara koyuyorsun.

## Sık yapılan hatalar

`EXPLAIN` ile `EXPLAIN ANALYZE`'ı karıştırmak. Sadece `EXPLAIN` sorguyu çalıştırmaz, planlayıcının tahminini gösterir. Gerçek süre ve satır sayısı için `ANALYZE` lazım. Ama `ANALYZE` sorguyu gerçekten çalıştırdığı için `DELETE` ya da `UPDATE` ile kullanırsan değişiklik yapılır, `BEGIN` ... `ROLLBACK` içine almayı unutma.

Tek bir ölçüme bakıp karar vermek. İlk çalıştırma genelde daha yavaş çıkar (veri henüz bellekte değil). İki üç kez çalıştırıp bak.

## Mülakatta

"Yavaş bir sorguyla karşılaştın, ne yaparsın?" sorusunun ilk adımı `EXPLAIN ANALYZE` çalıştırıp planı okumak. "Önce index ekleyeyim" demek yerine "önce planına bakarım, Seq Scan ve çok sayıda atılan satır görürsem filtrelenen kolona index düşünürüm" demek çok daha iyi duyuluyor.

<!-- beklenen-satir: 2500 -->
