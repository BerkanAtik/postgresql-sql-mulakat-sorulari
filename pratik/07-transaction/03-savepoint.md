# Bir kısmını geri almak

Zorluk: Orta · Konu: `SAVEPOINT`, `ROLLBACK TO SAVEPOINT`

## Soru

Beklemede olan 972, 975 ve 978 numaralı siparişleri iptal ediyorsun. Hepsini tek transaction içinde yapıyorsun ama 975'i iptal ettikten sonra müşteri ödemeyi yaptığını söylüyor. 975'in iptalini geri almak istiyorsun, 972 ve 978 iptal olarak kalacak. Transaction'ı baştan başlatmadan çöz.

Sonda üç siparişin `siparis_id` ve `durum` değerini göster ve `COMMIT` et.

Sorgu 3 satır döndürmeli.

<details>
<summary>İpucu</summary>

975'i iptal etmeden hemen önce transaction içinde bir `SAVEPOINT` koy. Sonra `ROLLBACK TO SAVEPOINT` ile sadece o noktadan sonrasını geri al.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
BEGIN;

UPDATE siparisler SET durum = 'iptal' WHERE siparis_id = 972;

SAVEPOINT iptal_975;
UPDATE siparisler SET durum = 'iptal' WHERE siparis_id = 975;

-- müşteri ödeme yaptı, 975'in iptalini geri al
ROLLBACK TO SAVEPOINT iptal_975;

UPDATE siparisler SET durum = 'iptal' WHERE siparis_id = 978;

SELECT siparis_id, durum
FROM siparisler
WHERE siparis_id IN (972, 975, 978)
ORDER BY siparis_id;

COMMIT;
```

</details>

## Açıklama

Sonuç:

```text
 siparis_id |   durum
------------+-----------
        972 | iptal
        975 | beklemede
        978 | iptal
```

972'nin iptali savepoint'ten önce yapıldığı için durdu, 975 geri alındı, 978 savepoint'ten sonra yapılıp kaldı. `ROLLBACK TO SAVEPOINT` transaction'ı bitirmiyor, sadece o noktaya dönüyor. Transaction açık, `COMMIT` ile devam edebilirsin.

Asıl işe yaradığı yer, hata sonrası toparlanmak. Transaction'da bir ifade hata verirse bütün transaction bozulur (1. soruya bak). Savepoint koyduysan hatadan sonra o noktaya dönüp devam edebilirsin:

```text
BEGIN
UPDATE siparisler SET durum = 'iptal' WHERE siparis_id = 972;    -- UPDATE 1
SAVEPOINT iptal_975;
UPDATE urunler SET stok = -1 WHERE urun_id = 5;
ERROR:  new row for relation "urunler" violates check constraint "urunler_stok_check"
SELECT 1;
ERROR:  current transaction is aborted, commands ignored until end of transaction block
ROLLBACK TO SAVEPOINT iptal_975;
SELECT siparis_id, durum FROM siparisler WHERE siparis_id = 972;   -- iptal (hâlâ duruyor)
COMMIT;
```

Savepoint olmasaydı hata sonrası tek çıkış `ROLLBACK` olurdu ve 972'nin iptali de giderdi. Savepoint'e dönünce 972'nin iptali durdu, transaction yeniden kullanılabilir hâle geldi.

Uygulama kodunda bunu genelde sen yazmıyorsun. ORM'lerin "iç içe transaction" özelliği ve Python'daki `psycopg` ya da JDBC'de "savepoint" desteği arka planda bunu kullanıyor.

## Sık yapılan hatalar

Savepoint'i `COMMIT`'in alternatifi sanmak. Savepoint kalıcı yapmaz, sadece transaction içinde bir işaret koyar. Kalıcı olması için sonunda yine `COMMIT` gerekiyor.

Savepoint'ten önceki işlemleri de geri alacağını düşünmek. `ROLLBACK TO SAVEPOINT` sadece o noktadan **sonrasını** geri alır. Tamamını geri almak için düz `ROLLBACK`.

Her ifadeden önce savepoint koymak. Hata yönetimi için yararlı ama gereksiz yere çok kullanmak performansı düşürür. Sadece "bu kısım başarısız olabilir ve devam etmek istiyorum" diyebildiğin yerlere koy.

## Mülakatta

"Transaction'ın bir kısmını nasıl geri alırsın?" sorusunun cevabı `SAVEPOINT`. Üzerine "PostgreSQL'de bir ifade hata verince bütün transaction bozulur, savepoint ile bu noktaya dönüp devam edebilirim" demek ayırt edici bir ayrıntı.

<!-- beklenen-satir: 3 -->
