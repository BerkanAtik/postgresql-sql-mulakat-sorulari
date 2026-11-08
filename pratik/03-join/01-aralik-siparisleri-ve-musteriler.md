# Aralık siparişleri ve müşteri adları

Zorluk: Kolay · Konu: `INNER JOIN`, takma ad

## Soru

2024 Aralık ayında verilen siparişlerin numarasını, tarihini ve siparişi veren müşterinin adını ve soyadını listele. Sonuç sipariş tarihine göre sıralı olsun.

Doğru yaptıysan 104 satır gelir.

<details>
<summary>İpucu</summary>

Sipariş bilgisi `siparisler` tablosunda, müşterinin adı `musteriler` tablosunda. İki tabloyu birbirine bağlayan ortak kolon `musteri_id`. Tarih aralığı için birinci modüldeki yarı açık aralık kalıbını kullanabilirsin.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT s.siparis_id, s.siparis_tarihi, m.ad, m.soyad
FROM siparisler AS s
JOIN musteriler AS m ON m.musteri_id = s.musteri_id
WHERE s.siparis_tarihi >= '2024-12-01'
  AND s.siparis_tarihi <  '2025-01-01'
ORDER BY s.siparis_tarihi;
```

</details>

## Açıklama

`JOIN`, iki tablonun satırlarını `ON`'da verdiğin koşula göre yan yana getirir. Burada her siparişin `musteri_id`'si, `musteriler` tablosunda aynı `musteri_id`'ye sahip satırla eşleşiyor. Sadece `JOIN` yazmak `INNER JOIN` ile aynı şey: iki tarafta da eşi olan satırlar gelir.

`AS s` ve `AS m` tablolara verdiğimiz kısa takma adlar. `s.siparis_id` "siparişler tablosundaki siparis_id" demek. Birden fazla tabloyla çalışırken her kolonun başına tablosunu yazmak hem okumayı kolaylaştırıyor hem de aşağıdaki hatayı önlüyor. `AS` kelimesini yazmasan da olur, `FROM siparisler s` de çalışır.

## Alternatif çözüm

İki tablodaki kolonun adı aynıysa `ON` yerine `USING` yazabilirsin:

```sql
SELECT s.siparis_id, s.siparis_tarihi, m.ad, m.soyad
FROM siparisler AS s
JOIN musteriler AS m USING (musteri_id)
WHERE s.siparis_tarihi >= '2024-12-01'
  AND s.siparis_tarihi <  '2025-01-01'
ORDER BY s.siparis_tarihi;
```

Kısa ama sadece kolon adları birebir aynıysa işe yarıyor. Gerçek projelerde `ON` daha sık kullanılıyor, çünkü her zaman çalışıyor ve ne ile neyin eşleştiği açıkça görünüyor.

## Sık yapılan hatalar

- Kolonun hangi tablodan geldiğini yazmamak. `SELECT siparis_id, musteri_id, ad ...` yazarsan `column reference "musteri_id" is ambiguous` hatası alırsın, çünkü `musteri_id` iki tabloda da var ve PostgreSQL hangisini istediğini bilemez.
- `ON` koşulunu unutmak. `FROM siparisler s, musteriler m` gibi eski yazımla iki tabloyu virgülle yan yana koyup eşleştirme koşulunu yazmazsan, her sipariş her müşteriyle eşleşir. 104 sipariş × 200 müşteri = 20.800 satır gelir. Buna kartezyen çarpım denir ve büyük tablolarda veritabanını kilitleyebilir.

<!-- beklenen-satir: 104 -->
