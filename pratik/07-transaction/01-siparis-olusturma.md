# Sipariş oluşturmak: ya hep ya hiç

Zorluk: Kolay · Konu: `BEGIN`, `COMMIT`, atomicity

## Soru

7 numaralı müşteri 5 numaralı ürüne (Dizüstü Bilgisayar, 32.999,00 TL) 2 adet sipariş veriyor. Bunun için üç şey yapılması gerekiyor:

1. `siparisler` tablosuna yeni bir sipariş eklemek (tarih `2024-12-20 10:30`, durum `beklemede`),
2. `siparis_kalemleri` tablosuna bu siparişin kalemini eklemek,
3. `urunler` tablosunda stoğu 2 adet düşürmek.

Üçünü tek transaction içinde yaz. Sonunda ürünün kalan stoğunu göster.

Sorgu 1 satır döndürmeli: kalan stok.

<details>
<summary>İpucu</summary>

Kalemi eklerken yeni siparişin numarasını bilmen lazım. `INSERT ... RETURNING siparis_id` bunu verir, onu bir `WITH` bloğuyla kalem ekleyen ifadeye taşıyabilirsin.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
BEGIN;

WITH yeni_siparis AS (
    INSERT INTO siparisler (musteri_id, siparis_tarihi, durum)
    VALUES (7, TIMESTAMP '2024-12-20 10:30', 'beklemede')
    RETURNING siparis_id
)
INSERT INTO siparis_kalemleri (siparis_id, urun_id, adet, birim_fiyat)
SELECT siparis_id, 5, 2, 32999.00
FROM yeni_siparis;

UPDATE urunler
SET stok = stok - 2
WHERE urun_id = 5;

SELECT stok
FROM urunler
WHERE urun_id = 5;

COMMIT;
```

</details>

## Açıklama

Stok 25 idi, 2 düşünce 23 kalıyor. Asıl mesele bunun neden tek transaction içinde olması gerektiği.

`BEGIN` yazmazsan her ifade ayrı ayrı kalıcı olur. Aynı siparişi 30 adet verdiğini düşün, ama stok sadece 25. İlk iki ifade çalışır, üçüncüsü `CHECK (stok >= 0)` kuralına takılır:

```text
INSERT 0 1
ERROR:  new row for relation "urunler" violates check constraint "urunler_stok_check"
```

Sonuç: sipariş ve kalem kaydı tabloda duruyor (benim denememde `siparisler` 1000'den 1001'e, `siparis_kalemleri` 2500'den 2501'e çıktı), stok ise düşmedi. Elinde stoğu karşılanmamış, ortada kalmış bir sipariş var.

Aynısını `BEGIN` ile yazınca:

```text
BEGIN
INSERT 0 1
ERROR:  new row for relation "urunler" violates check constraint "urunler_stok_check"
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK
```

Üçüncü ifade hata verince transaction bozuldu, sonraki her şey reddedildi. `COMMIT` yazmama rağmen PostgreSQL `ROLLBACK` yaptı, yani ilk iki eklemeyi de geri aldı. Tablolarda sayılar eskisi gibi (1000 ve 2500) kaldı. Buna **atomicity** deniyor: transaction ya tamamen olur ya hiç olmaz.

Küçük bir ayrıntı: geri alınan `INSERT` sequence'i harcamış oluyor. Benim iki denememde ilki 1001 numarasını aldı ve kayıt kaldı, ikincisi 1002'yi aldı ve geri alındı. Yani bir sonraki sipariş 1003 olur, 1002 numaralı sipariş hiç var olmadı. Numaralardaki boşluklar normaldir, bir sorun değil.

## Sık yapılan hatalar

`BEGIN` açıp `COMMIT` ya da `ROLLBACK` yazmayı unutmak. Oturum açık kalıyor, değiştirdiğin satırlar kilitli, başkaları bekliyor. Uzun süre açık duran transaction'lar gerçek sistemlerde sık görülen bir sorun.

Hata yakalayıp devam etmeye çalışmak. Uygulama kodunda `try/catch` ile hatayı yutup sonraki ifadeyi çalıştırırsan yukarıdaki `current transaction is aborted` hatasını alırsın. Hata aldıysan `ROLLBACK` yapıp baştan başlaman gerekiyor (ya da SAVEPOINT, sonraki soruya bak).

Stoğu kontrol edip sonra düşmek için ayrı bir `SELECT` yazmak. "Stok yeterli mi?" diye okuyup sonra güncelleyince arada başkası araya girebilir. Bunu 4. soruda ayrıca göreceğiz.

## Mülakatta

"Transaction nedir, neden gerekir?" sorusuna soyut ACID tanımından önce bu sipariş örneğini anlatmak çok daha iyi duyuluyor: "sipariş kaydı, kalem ve stok düşümü ya hep birlikte olmalı, aksi hâlde ortada yarım sipariş kalır."

<!-- beklenen-satir: 1 -->
