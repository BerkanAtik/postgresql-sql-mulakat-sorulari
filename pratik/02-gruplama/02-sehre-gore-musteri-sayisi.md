# Şehre göre müşteri sayısı

Zorluk: Kolay · Konu: `GROUP BY`, `NULL`, `COALESCE`

## Soru

Her şehirde kaç müşterimiz olduğunu listele. En kalabalık şehir en üstte olsun. Şehri girilmemiş müşteriler de listede görünsün ve şehir adı yerine `Belirtilmemiş` yazsın.

Doğru yaptıysan 9 satır gelir.

<details>
<summary>İpucu</summary>

`NULL` olan değerleri başka bir metinle değiştiren bir fonksiyon var. `GROUP BY` boş şehirleri ne yapar, onu da bir dene.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT COALESCE(sehir, 'Belirtilmemiş') AS sehir,
       COUNT(*) AS musteri_sayisi
FROM musteriler
GROUP BY sehir
ORDER BY musteri_sayisi DESC, sehir;
```

</details>

## Açıklama

`GROUP BY` için bütün `NULL` değerler aynı grupta toplanır. `DISTINCT` de öyle davranıyordu. Yani şehri boş olan 8 müşteri tek bir grup oluşturuyor ve sonuçta `NULL` yazan bir satırda görünüyor.

`COALESCE(sehir, 'Belirtilmemiş')` ilk boş olmayan değeri döndürür. `sehir` doluysa `sehir`'i, `NULL` ise `'Belirtilmemiş'` metnini verir. Böylece boş görünen satır anlamlı bir etikete dönüşüyor.

Gruplamayı ham kolona (`sehir`) göre yapıyoruz, `COALESCE`'li hâline göre değil. Zaten `NULL` hepsi aynı grupta olduğu için sonuç aynı.

Üçüncü bir ayrıntı, sıralama. İstanbul 48, Ankara ve İzmir 32 müşteriyle geliyor. Beş şehirde 16'şar müşteri var, bu eşitlikte sıra rastgele olmasın diye ikinci kolon olarak `sehir`'i ekledim.

## Alternatif çözüm

Gruplamayı `COALESCE`'li ifadeye göre de yapabilirsin. Sütun numarası da yazabilirsin, `1` ilk seçilen kolon demek:

```sql
SELECT COALESCE(sehir, 'Belirtilmemiş') AS sehir,
       COUNT(*) AS musteri_sayisi
FROM musteriler
GROUP BY 1
ORDER BY musteri_sayisi DESC, sehir;
```

Sonuç aynı. Sütun numarasıyla yazmak kısa ama sorgu uzadıkça okunması zorlaşır, ben net olması için isim yazmayı tercih ediyorum.

## Sık yapılan hatalar

`COUNT(*)` yerine `COUNT(sehir)` yazmak. `COUNT(sehir)`, o kolonu boş olmayan satırları sayar. Şehri boş olan grup için sonuç `0` çıkar, yani listede `Belirtilmemiş | 0` görürsün. Satır var ama sayacak bir şehir değeri yok. Grup içindeki satırları saymak istiyorsan `COUNT(*)` kullan.

<!-- beklenen-satir: 9 -->
