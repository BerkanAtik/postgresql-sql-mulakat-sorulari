# Duruma göre sipariş sayısı

Zorluk: Kolay · Konu: `COUNT`, `GROUP BY`, `ORDER BY`

## Soru

Siparişleri durumlarına göre grupla ve her durumda kaç sipariş olduğunu göster. En çok siparişi olan durum en üstte olsun.

Doğru yaptıysan 5 satır gelir.

<details>
<summary>İpucu</summary>

Sonuçta her durum bir kez görünmeli, yani siparişleri durum kolonuna göre gruplamak gerekiyor. Sayma işini de bir toplama fonksiyonu yapar. Sıralamayı o sayıya göre yapacağın için ona bir takma ad (alias) vermek işini kolaylaştırır.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT durum, COUNT(*) AS siparis_sayisi
FROM siparisler
GROUP BY durum
ORDER BY siparis_sayisi DESC, durum;
```

</details>

## Açıklama

`GROUP BY durum` aynı duruma sahip satırları tek bir grupta toplar. `COUNT(*)` de her grubun içindeki satırları sayar. Yani önce 1000 sipariş 5 gruba ayrılıyor, sonra her grup için bir sayı hesaplanıyor.

`SELECT` listesine yazdığın her kolon ya `GROUP BY`'da olmak zorunda ya da bir toplama fonksiyonunun içinde. Burada `durum` gruplandığı için serbest, `COUNT(*)` da toplama fonksiyonu olduğu için serbest.

`ORDER BY`'da takma adı kullanabilirsin, çünkü sıralama en son çalışıyor ve o noktada `siparis_sayisi` zaten hesaplanmış durumda. Sonuçta `kargoda` ile `beklemede` ikisi de 10 sipariş çıkıyor. Eşit olanların sırası her seferinde aynı olsun istersen ikinci bir sıralama kolonu eklemek iyi alışkanlık, ben `durum`'u ekledim.

## Sık yapılan hatalar

- `GROUP BY`'ı unutmak: `SELECT durum, COUNT(*) FROM siparisler;` yazarsan PostgreSQL hata verir. `durum` hem düz kolon hem de bir toplama fonksiyonuyla yan yana olamaz.
- Gruplanmayan bir kolonu seçmek: `SELECT durum, musteri_id, COUNT(*) FROM siparisler GROUP BY durum;` da hata verir. Mesaj şöyle: `column "siparisler.musteri_id" must appear in the GROUP BY clause or be used in an aggregate function`. Bir durumun içinde yüzlerce farklı `musteri_id` var, veritabanı hangisini göstereceğini bilemez.

<!-- beklenen-satir: 5 -->
