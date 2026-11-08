# Güncellemeyi önce dene, sonra karar ver

Zorluk: Kolay · Konu: `ROLLBACK`, `UPDATE ... RETURNING`

## Soru

`Telefon` kategorisindeki (`kategori_id = 6`) ürünlere %10 zam yapacaksın. `WHERE` koşulunu doğru yazdığından emin olmak istiyorsun ve henüz kalıcı bir şey yapmak istemiyorsun.

Bir transaction aç, zammı yap, hangi ürünlerin yeni fiyatını aldığını `RETURNING` ile göster (`urun_id`, `ad`, `fiyat`), sonra `ROLLBACK` ile geri al. Yeni fiyatlar kuruşa yuvarlansın.

Sorgu 4 satır döndürmeli.

<details>
<summary>İpucu</summary>

`UPDATE ... RETURNING kolon1, kolon2` güncellenen satırların yeni hâlini sonuç olarak verir, ayrıca `SELECT` yazmana gerek kalmaz. Yuvarlamak için `ROUND(deger, 2)`.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
BEGIN;

UPDATE urunler
SET fiyat = ROUND(fiyat * 1.10, 2)
WHERE kategori_id = 6
RETURNING urun_id, ad, fiyat;

ROLLBACK;
```

</details>

## Açıklama

`RETURNING` ile güncellenen satırlar hemen ekrana geliyor:

```text
 urun_id |            ad             |  fiyat
---------+---------------------------+----------
       3 | Telefon Kılıfı Silikon    |   164.89
       4 | Hızlı Şarj Adaptörü 20W   |   328.90
       1 | Akıllı Telefon X12 128 GB | 20898.90
       2 | Akıllı Telefon Lite 64 GB |  9349.89
UPDATE 4
```

Dört telefon ürünü, beklediğin gibi. Gözle kontrol ettin, sonra `ROLLBACK` dedin. Geri aldığını doğrulamak için fiyatlara tekrar bakınca (`18999.00`, `8499.90`, `149.90`, `299.00`) eskisi gibi olduklarını görürsün.

Bu yöntemin işe yaradığı yer, `WHERE` koşulunu yanlış yazdığın durum. Mesela `WHERE` unutursan `psql` sonunda şunu yazar:

```text
UPDATE 50
```

50 ürünün hepsine zam yapılmış demek. Beklediğin 4 değildi, hemen `ROLLBACK` dersin, hiçbir şey olmamış gibi devam eder. Transaction açmadan aynı komutu çalıştırsaydın, 50 ürünün fiyatı kalıcı olarak değişmiş olurdu ve geri almak için yedekten dönmen gerekirdi.

Her `UPDATE` ve `DELETE` için aynı alışkanlığı edinebilirsin: `BEGIN`, komut, kontrol (`RETURNING` ya da `SELECT`), memnunsan `COMMIT`, değilsen `ROLLBACK`. Zam gerçekten yapılacaksa son satır `COMMIT` olur.

## Sık yapılan hatalar

`COMMIT` yazmayı unutup işin bittiğini sanmak. Başka bir oturumdan bakınca zam görünmez, çünkü yaptığın şey sadece senin transaction'ında duruyor.

Üretim veritabanında `BEGIN` yazmadan `UPDATE`/`DELETE` çalıştırmak. Hele `WHERE`'siz yazılan komut bir klasik.

`EXPLAIN ANALYZE` ile `UPDATE`/`DELETE` denemek. `EXPLAIN ANALYZE` komutu gerçekten çalıştırır, o yüzden Modül 6'daki gibi `BEGIN ... ROLLBACK` içine almadan kullanma.

## Mülakatta

"Bir `UPDATE`'i çalıştırmadan önce nasıl güvenceye alırsın?" sorusunda cevap: önce `SELECT` ile aynı `WHERE`'in kaç satır döndürdüğüne bakarım, sonra `BEGIN` içinde çalıştırıp `UPDATE <sayı>` çıktısına bakarım, beklediğim sayıysa `COMMIT` ederim.

<!-- beklenen-satir: 4 -->
