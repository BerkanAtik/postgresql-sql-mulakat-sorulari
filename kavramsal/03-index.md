# Index

Uygulamalı tarafı [Modül 6'da](../pratik/06-index-ve-explain/README.md). Buradaki ölçümlerin çoğu o modüldeki 500.000 satırlık `ziyaretler` tablosundan, süreleri kendi makinemde aldım. Senin makinende rakamlar değişir, oranlar benzer çıkar.

## 13. Index nedir, sorguyu nasıl hızlandırır, bedeli nedir?

**Kısa cevap:** Index, bir kolonun sıralı bir kopyası gibi. Veritabanı aradığı değeri bütün tabloyu okumadan bulabiliyor. Karşılığında index diskte yer tutuyor ve her `INSERT`, `UPDATE`, `DELETE` index'i de güncellemek zorunda.

Kitabın arkasındaki dizin gibi düşünebilirsin: bir kelimeyi bulmak için bütün kitabı okumuyorsun, dizine bakıp sayfasına gidiyorsun. Ama kitaba yeni bir bölüm eklenince dizini de güncellemen gerekir.

500.000 satırlık tabloda `musteri_id = 42` araması: index yokken `Seq Scan` (tablonun tamamı), yaklaşık 30 ms. `musteri_id` üzerine index açınca `Bitmap Index Scan`, 1,5 ile 2 ms.

Bedeli: aynı tabloda bu index 3,4 MB yer tutuyor (tablo 30 MB). Çok sayıda index'in olduğu bir tabloya yazmak yavaşlıyor, çünkü her yazma hepsini güncelliyor.

**Ne zaman index açarsın?** Sorgularda `WHERE`, `JOIN` ya da `ORDER BY` içinde sık kullanılan ve seçici (az sayıda satır getiren) kolonlara. Kendiliğinden açılan tek şey primary key ve unique kısıtlarının index'i. Foreign key kolonlarına PostgreSQL **otomatik index açmıyor**.

## 14. Hangi index türleri var?

**Kısa cevap:** Varsayılan ve en yaygın olan B-tree. Onun dışında hash, GIN, GiST, BRIN gibi özel amaçlı türler var.

| Tür | Ne için |
|---|---|
| B-tree (varsayılan) | `=`, `<`, `>`, `BETWEEN`, sıralama. Çoğu iş için bu |
| Hash | Sadece `=`. Pratikte B-tree genelde yeterli |
| GIN | Bir değerin içinde birden çok şey olan kolonlar: `jsonb`, diziler, tam metin arama, `pg_trgm` ile `LIKE '%..%'` |
| GiST | Coğrafi veri, aralık tipleri, benzerlik aramaları |
| BRIN | Çok büyük ve fiziksel olarak sıralı tablolar (zaman damgalı log gibi). Çok küçük ama kaba |

İki ölçüm:

- **Hash:** `musteri_id` üzerinde hash index'i `=` aramasında kullanıldı ama `musteri_id > 190` için kullanılmadı. Bu tabloda hash index 22 MB, aynı kolondaki B-tree 3,4 MB çıktı (çok sayıda aynı değer tekrarlandığı için). Yani hash her zaman daha küçük ya da hızlı değil.
- **BRIN:** `ziyaret_zamani` kolonu zamanla artarak eklendiği için BRIN çok uygun. BRIN index'i 24 kB, aynı kolondaki B-tree 11 MB. Bedeli kabalık: tek bir güne ait 1372 satırı ararken BRIN 15.000 gereksiz satırı daha okuyup eledi (1,3 ms). B-tree aynı aramayı 0,25 ms'de yaptı.

**Devamında sorulabilir:** "`LIKE '%kelime%'` için index olur mu?" Normal B-tree olmaz. `pg_trgm` + GIN denenebilir ama her tabloda kazandırmıyor, [Modül 6'nın son sorusunda](../pratik/06-index-ve-explain/04-index-var-ama-kullanilmiyor.md) denemesi var.

## 15. Index olduğu hâlde sorgu index'i kullanmıyorsa nedenleri neler olabilir?

**Kısa cevap:** Genelde kolona fonksiyon ya da dönüşüm uygulanmıştır, aramanın başında joker vardır, ya da zaten tablonun büyük kısmı isteniyordur ve planlayıcı tamamını okumayı daha ucuz buluyordur.

Ölçtüğüm örnekler (hepsi `Seq Scan` çıktı):

- `WHERE ziyaret_zamani::date = '2024-03-15'`: kolon dönüştürülmüş. Çözüm yarı açık aralık ya da expression index ([Modül 6, soru 2](../pratik/06-index-ve-explain/02-tarih-kolonuna-fonksiyon.md)).
- `WHERE upper(sayfa) = 'SEPET'`, `WHERE musteri_id::text = '42'`: aynı sebep.
- `WHERE sayfa LIKE '%ep%'`: başta joker var.
- `WHERE sayfa <> 'anasayfa'`: B-tree "eşit değil" aramasını yapamaz.
- Satırların %70'ini isteyen sorgu: planlayıcı baştan sona okumayı seçti.
- 200 satırlık küçük tablo: Seq Scan 0,04 ms sürüyor, index'e bakmanın anlamı yok.
- Bileşik index'in ikinci kolonuna tek başına filtre ([Modül 6, soru 3](../pratik/06-index-ve-explain/03-birlesik-index-kolon-sirasi.md)).

Planlayıcının her Seq Scan kararı hata değil. Yalnız %70'lik örnekte index'i zorlayınca benim makinemde biraz daha hızlı çıktı (38 ms, Seq Scan 55 ms). O yüzden "neden kullanılmadı"ya bakarken `EXPLAIN ANALYZE` ile hem planlayıcının seçtiğini hem de zorlanmış hâli karşılaştırmak mantıklı. `SET enable_seqscan = off` sadece bu deney için, kalıcı çözüm değil.

## 16. Covering index ve index-only scan nedir?

**Kısa cevap:** Sorgunun ihtiyaç duyduğu bütün kolonlar index'in içinde varsa, PostgreSQL tabloya hiç gitmeden cevabı index'ten verebilir. Buna `Index Only Scan` deniyor. Index'e `INCLUDE` ile ek kolon eklemek de buna yarıyor.

`ziyaretler` tablosunda `musteri_id` index'i varken:

```sql
SELECT musteri_id FROM ziyaretler WHERE musteri_id = 42;
-- Index Only Scan, Heap Fetches: 0, 0,15 ms

SELECT musteri_id, sure_saniye FROM ziyaretler WHERE musteri_id = 42;
-- Bitmap Heap Scan (sure_saniye index'te yok, tabloya gidilmeli), 2 ms
```

Index'i `(musteri_id) INCLUDE (sure_saniye)` olarak kurunca ikinci sorgu da `Index Only Scan` oldu ve 0,4 ms'ye indi.

Dikkat edilecek iki şey:

- `INCLUDE` ile eklenen kolon aramada kullanılmıyor, sadece değeri taşıyor. Index'in büyümesi pahasına.
- Index-only scan, tablonun "görünürlük haritası"nın güncel olmasına (yani yakın zamanda `VACUUM` çalışmış olmasına) bağlı. Güncel değilse plan `Index Only Scan` yazsa da tabloya bakmak zorunda kalır (`Heap Fetches` artar). Ben denemeden önce `VACUUM` çalıştırdım.

## 17. EXPLAIN ile EXPLAIN ANALYZE arasındaki fark nedir? Yavaş sorguda ne yaparsın?

**Kısa cevap:** `EXPLAIN` sorguyu çalıştırmadan planlayıcının tahminini gösterir. `EXPLAIN ANALYZE` sorguyu **gerçekten çalıştırır**, gerçek süreyi ve satır sayısını da yazar. Bu yüzden `INSERT`/`UPDATE`/`DELETE` için `BEGIN ... ROLLBACK` içinde kullanılır.

**"Bu sorgu yavaş, ne yaparsın?"** sorusuna şu sırayla cevap verebilirsin:

1. `EXPLAIN ANALYZE` ile planı al, tahmin ve gerçek satır sayılarına, `Seq Scan` ve çok sayıda `Rows Removed by Filter`'a bak.
2. Filtrelenen ya da `JOIN` edilen kolonda index var mı, kullanılıyor mu kontrol et.
3. Kolona fonksiyon uygulanmış mı, `LIKE '%..'` gibi index'i bozan bir şey var mı?
4. Gereğinden fazla satır ya da kolon mu getiriyorsun (`SELECT *`, `LIMIT` yok)?
5. Tablo istatistikleri güncel mi (`ANALYZE`), tablo şişmiş mi (`VACUUM`)?
6. Hepsi iyiyse sorguyu yeniden yazmayı ya da veri modelini değiştirmeyi (özet tablo, materialized view) düşün.

İlk adımı atlayıp "hemen index ekleyeyim" demek mülakatta en kötü cevap. Önce ölç, sonra karar ver.
