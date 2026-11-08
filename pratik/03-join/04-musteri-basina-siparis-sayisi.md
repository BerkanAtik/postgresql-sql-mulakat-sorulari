# Müşteri başına sipariş sayısı

Zorluk: Orta · Konu: `LEFT JOIN` ile `COUNT`

## Soru

Bütün müşterileri, verdikleri sipariş sayısıyla birlikte listele: `musteri_id`, `ad`, `soyad` ve sipariş sayısı. Hiç sipariş vermemiş müşteriler de listede olsun ve sipariş sayıları 0 görünsün. En çok siparişi olan müşteri en üstte olsun.

Doğru yaptıysan 200 satır gelir.

<details>
<summary>İpucu</summary>

Önceki sorudaki gibi `LEFT JOIN` gerekiyor. Ama bu sefer sayma işi var. `COUNT`'a ne verdiğin, sipariş vermemiş müşterilerin 0 mı 1 mi görüneceğini belirliyor.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT m.musteri_id, m.ad, m.soyad,
       COUNT(s.siparis_id) AS siparis_sayisi
FROM musteriler AS m
LEFT JOIN siparisler AS s ON s.musteri_id = m.musteri_id
GROUP BY m.musteri_id, m.ad, m.soyad
ORDER BY siparis_sayisi DESC, m.musteri_id;
```

</details>

## Açıklama

`LEFT JOIN` sayesinde sipariş vermemiş 20 müşteri de sonuçta kalıyor. Bu müşterilerin her biri için bir satır var ve o satırda `siparisler`'den gelen bütün kolonlar `NULL`.

Burada kritik nokta `COUNT(s.siparis_id)`. `COUNT(kolon)`, `NULL` olmayan değerleri sayıyordu. Sipariş vermemiş bir müşterinin satırında `s.siparis_id` `NULL` olduğu için sayı 0 çıkıyor, istediğimiz de bu.

`COUNT(*)` yazsaydın ne olurdu? `COUNT(*)` satırı sayar, içine bakmaz. Sipariş vermemiş müşterinin de bir satırı var (`NULL`'larla dolu da olsa), o yüzden 1 sayılır. Sonuç: 20 müşteri sanki 1 sipariş vermiş gibi görünür.

## Alternatif çözüm

PostgreSQL'de bir tablonun primary key'ine göre grupladığında o tablonun diğer kolonlarını da `GROUP BY`'a yazmadan seçebilirsin:

```sql
SELECT m.musteri_id, m.ad, m.soyad,
       COUNT(s.siparis_id) AS siparis_sayisi
FROM musteriler AS m
LEFT JOIN siparisler AS s ON s.musteri_id = m.musteri_id
GROUP BY m.musteri_id
ORDER BY siparis_sayisi DESC, m.musteri_id;
```

Çalışıyor, çünkü `musteri_id` belli olunca o müşterinin adı ve soyadı da kesin olarak belli. Ama bu özellik her veritabanında yok, bazı veritabanları burada hata verir. Taşınabilir olsun istiyorsan ilk çözümdeki gibi hepsini yazmak daha güvenli.

## Sık yapılan hatalar

- `COUNT(*)` yazmak. Hata vermez, ama sipariş vermemiş müşterilerde 0 yerine 1 görünür. Gerçekte sadece 6 müşteri tek sipariş vermiş, `COUNT(*)` ile bu sayı 26'ya çıkar.
- `LEFT JOIN` yerine `JOIN` yazmak. Sipariş vermemiş müşteriler tamamen kaybolur, 200 yerine 180 satır gelir.

<!-- beklenen-satir: 200 -->
