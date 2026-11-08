# Index var ama kullanılmıyor

Zorluk: Zor · Konu: `LIKE` ile arama, `text_pattern_ops`, index'in işe yaramadığı durumlar

## Soru

`ziyaretler` tablosunda `sayfa` kolonunda normal bir index var:

```sql
CREATE INDEX idx_ziyaretler_sayfa ON ziyaretler (sayfa);
```

Sayfa adı `sep` ile başlayan bütün ziyaretleri `LIKE 'sep%'` ile getirmek istiyorsun. Aynı sorguyu bir de adında `ep` geçenler için (`LIKE '%ep%'`) dene. İkisinin planına bak. Hangisi index kullanıyor, kullanmayan için ne yapılabilir?

İki sorgu da 50.000 satır döndürmeli.

<details>
<summary>İpucu</summary>

Önce iki sorgunun `EXPLAIN ANALYZE` çıktısını karşılaştır. Önek aramasında index'in kullanılması için ona özel bir operatör sınıfı vermen gerekebilir (`text_pattern_ops`).

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
CREATE INDEX idx_ziyaretler_sayfa_onek ON ziyaretler (sayfa text_pattern_ops);

SELECT *
FROM ziyaretler
WHERE sayfa LIKE 'sep%';
```

</details>

## Açıklama

Önce olanı görelim. Normal `idx_ziyaretler_sayfa` index'i varken `LIKE 'sep%'`:

```text
Seq Scan on ziyaretler
  Filter: (sayfa ~~ 'sep%'::text)
  Rows Removed by Filter: 450000
Execution Time: 28 ms
```

Önek araması B-tree'nin tam yapabileceği bir iş gibi görünüyor ama index kullanılmadı. Sebep **collation** (karşılaştırma kuralı). Veritabanı `C` dışında bir dil kuralıyla kurulmuşsa (`en_US.utf8`, Türkçe vb.) harfler dile göre sıralanıyor. Böyle bir sıralamada "`sep` ile başlayan her şey index'te yan yana durur" garantisi yok, o yüzden PostgreSQL normal index'e güvenmiyor. Docker imajı da varsayılan olarak `en_US.utf8` ile kuruluyor, yani senin ortamında da büyük ihtimalle böyle. Ben `en-US` ICU collation'lı bir veritabanında ölçtüm. `C` collation'lı bir veritabanında normal index de önek aramasında çalışır, sonuç farklı çıkabilir.

Çözüm index'i `text_pattern_ops` ile kurmak. Bu operatör sınıfı harfleri dile göre değil, düz karakter sırasına göre sıralıyor:

```text
Bitmap Heap Scan on ziyaretler
  Filter: (sayfa ~~ 'sep%'::text)
  ->  Bitmap Index Scan on idx_ziyaretler_sayfa_onek
        Index Cond: ((sayfa ~>=~ 'sep'::text) AND (sayfa ~<~ 'seq'::text))
Execution Time: 9 ms
```

PostgreSQL `LIKE 'sep%'` ifadesini `'sep' <= sayfa < 'seq'` aralığına çevirip index'te arıyor. 28 ms'den 9 ms'ye düştü. Bu kadar az fark çıkmasının sebebi, aranan değerin tablonun %10'unu oluşturması. Daha seçici bir kolonda fark çok daha büyük olur.

`text_pattern_ops` düz karakter sırasına göre çalıştığı için bu index dile göre sıralama gerektiren işlerde (`ORDER BY sayfa`, `<`, `>`) kullanılmıyor. Bunlar da lazımsa normal index'i de tutman gerekir.

### `LIKE '%ep%'` neden hâlâ yavaş?

İlk karakteri bilmiyorsan index'in sıralı yapısı işe yaramıyor. `text_pattern_ops` index'i varken bile plan:

```text
Seq Scan on ziyaretler
  Filter: (sayfa ~~ '%ep%'::text)
  Rows Removed by Filter: 450000
Execution Time: 30 ms
```

Kelimenin ortasında aramak için `pg_trgm` eklentisi ve GIN index'i var (aşağıdaki alternatif çözümde). Kelimeyi 3 harflik parçalara bölüp onları index'liyor. Ama her durumda kazandırmaz: benim denememde bu tabloda trigram index'i Seq Scan'den **yavaş** çıktı (67 ms, Seq Scan 30 ms). `sayfa` kolonunda sadece 5 farklı değer var ve aranan şey satırların %10'una uyuyor. Trigram index'i çok farklı değer içeren, aramanın dar kaldığı metin kolonlarında (ürün adı, e-posta gibi) işe yarar.

### Index'in kullanılmadığı başka durumlar

Benim denediklerim (`sayfa`, `musteri_id` ve bir de `musteriler.sehir` için normal index varken):

| Sorgu | Plan | Neden |
|---|---|---|
| `WHERE musteri_id::text = '42'` | Seq Scan | Kolon bir dönüşümden geçiyor, index kolonun kendisine göre sıralı |
| `WHERE upper(sayfa) = 'SEPET'` | Seq Scan | Aynı sebep, fonksiyon uygulanmış kolon |
| `WHERE sayfa <> 'anasayfa'` | Seq Scan | B-tree "eşit değil" aramasını yapamaz. Index'i zorla açsan bile plan değişmiyor |
| `WHERE sayfa IN ('anasayfa', 'urun')` | Seq Scan (%70 satır) | Tablonun çoğunu istiyorsun, planlayıcı baştan sona okumayı seçti |
| `WHERE sehir = 'Ankara'` (`musteriler`, 200 satır) | Seq Scan | Tablo tek sayfaya sığıyor, index'e bakmak daha pahalı |

Dördüncü satıra dikkat: planlayıcı Seq Scan seçti ama ben `enable_seqscan = off` ile index'i zorlayınca bu tabloda 38 ms ile Seq Scan'in 55 ms'sinden biraz **hızlı** çıktı. Tablo küçük ve tamamen bellekte olduğu için olabilir, diskte okunan büyük bir tabloda tersi çıkabilir. Yani planlayıcının Seq Scan seçmesi her zaman hata değil. Çoğu zaman haklıdır, onu zorlamak yerine neden öyle seçtiğine (satır tahmini, tablo büyüklüğü) bak.

## Alternatif çözüm

Aradaki aramayı da (`'%ep%'`) index'e bağlamak istersen `pg_trgm` ile GIN index'i kurabilirsin. Yukarıda gördüğün gibi bu tabloda kazandırmıyor, ama doğru kolonda kullanımı bu:

<details>
<summary>Çözümü göster</summary>

```sql
CREATE EXTENSION IF NOT EXISTS pg_trgm;
CREATE INDEX idx_ziyaretler_sayfa_trgm ON ziyaretler USING gin (sayfa gin_trgm_ops);

SELECT *
FROM ziyaretler
WHERE sayfa LIKE '%ep%';
```

</details>

## Sık yapılan hatalar

Index var diye sorgunun hızlı çalışacağını varsaymak. Her zaman `EXPLAIN ANALYZE` ile bak.

`LIKE '%kelime%'` aramasını normal index ile çözmeye çalışmak. Ortada arama için `pg_trgm` ya da tam metin arama (`tsvector`) gerekir.

`SET enable_seqscan = off` komutunu kalıcı çözüm gibi kullanmak. Bu sadece "index olsa ne olurdu" diye bakmak için bir deney aracı, uygulamada açık bırakılmaz.

## Mülakatta

"Index'in olduğu bir kolonda sorgu neden Seq Scan yapar?" sorusunun cevabı bir liste: kolon fonksiyondan geçiyor, `LIKE '%..'` ile başlıyor, `<>` kullanılıyor, tablonun büyük kısmı isteniyor ya da tablo çok küçük. Hepsini ezberlemene gerek yok, "index kolonun çıplak hâlini ve dar bir aramayı sever" demek, sonra `EXPLAIN`'e bakacağını söylemek yeterli.

<!-- beklenen-satir: 50000 -->
