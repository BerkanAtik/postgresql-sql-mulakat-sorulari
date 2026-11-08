# Aralık ayı müşteri raporu

Zorluk: Zor · Konu: `LEFT JOIN`'de koşulu `ON`'a mı `WHERE`'e mi yazmak

## Soru

Pazarlama ekibi Aralık 2024 kampanyasının raporunu istiyor. **Bütün** müşterileri, Aralık 2024'te verdikleri sipariş sayısıyla birlikte listele (`musteri_id` ve sipariş sayısı). Aralık'ta sipariş vermemiş müşteriler de 0 ile listede görünsün. Müşteri numarasına göre sırala.

Doğru yaptıysan 200 satır gelir. Kendini kontrol etmek için: sipariş sayılarının toplamı 104 olmalı (Aralık'taki toplam sipariş), 123 müşteride de 0 görünmeli.

<details>
<summary>İpucu</summary>

Önceki soruyla neredeyse aynı, sadece bir tarih koşulu ekleniyor. Ama o koşulu nereye yazdığın her şeyi değiştiriyor. `WHERE`'e yazınca kaç satır geldiğine bak.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT m.musteri_id,
       COUNT(s.siparis_id) AS aralik_siparis_sayisi
FROM musteriler AS m
LEFT JOIN siparisler AS s
       ON s.musteri_id = m.musteri_id
      AND s.siparis_tarihi >= '2024-12-01'
      AND s.siparis_tarihi <  '2025-01-01'
GROUP BY m.musteri_id
ORDER BY m.musteri_id;
```

</details>

## Açıklama

Bu, `JOIN`'lerde en çok yapılan ve en zor fark edilen hata. Çoğu kişi tarih koşulunu alışkanlıkla `WHERE`'e yazar:

```text
LEFT JOIN siparisler AS s ON s.musteri_id = m.musteri_id
WHERE s.siparis_tarihi >= '2024-12-01' AND s.siparis_tarihi < '2025-01-01'
```

Hata vermiyor ama 200 yerine 77 satır döndürüyor. Neden?

Sorgunun çalışma sırasını hatırla: önce `JOIN`, sonra `WHERE`. `LEFT JOIN` sipariş vermemiş müşterileri `NULL` siparişlerle tutuyor. Sonra `WHERE` geliyor ve `s.siparis_tarihi >= '2024-12-01'` koşulunu kontrol ediyor. `NULL` bir tarih için bu koşul `NULL` döner, satır elenir. Aralık dışında sipariş vermiş müşterilerin satırları da tarih tutmadığı için elenir. Geriye sadece Aralık'ta sipariş vermiş 77 müşteri kalıyor. Yani `LEFT JOIN` yazmış olsan da sonuç `INNER JOIN` gibi davranıyor.

Koşulu `ON`'a yazınca anlamı değişiyor: "Müşterileri sadece Aralık siparişleriyle eşleştir. Eşleşen yoksa müşteriyi yine tut." Tarih kontrolü eşleştirme sırasında yapıldığı için hiçbir müşteri kaybolmuyor.

Kural şu: `LEFT JOIN`'de **sağdaki** tablonun koşullarını `ON`'a yaz. **Soldaki** tabloyu süzmek istiyorsan (örneğin sadece İstanbul'daki müşteriler) o koşul `WHERE`'e gider.

Bir istisna var: 3. sorudaki anti join. Orada `s.musteri_id IS NULL` bilerek `WHERE`'de duruyor, çünkü eşleşme olup olmadığına `JOIN` bittikten sonra bakıyorsun. Onu `ON`'a taşırsan hiçbir müşteri elenmez ve 200 müşterinin hepsi gelir.

## Alternatif çözüm

Birleştirmeyi tarih koşulu olmadan yapıp sadece Aralık siparişlerini saydırabilirsin. Önceki modülde gördüğün `FILTER` burada da işe yarıyor:

```sql
SELECT m.musteri_id,
       COUNT(s.siparis_id) FILTER (
           WHERE s.siparis_tarihi >= '2024-12-01'
             AND s.siparis_tarihi <  '2025-01-01'
       ) AS aralik_siparis_sayisi
FROM musteriler AS m
LEFT JOIN siparisler AS s ON s.musteri_id = m.musteri_id
GROUP BY m.musteri_id
ORDER BY m.musteri_id;
```

Sonuç aynı ama bu sürüm bütün siparişleri birleştirip sonra sayarken eliyor, büyük tablolarda ilk çözüm daha az iş yapar. Aynı sorguda hem Aralık'ı hem bütün yılı yan yana göstermek istersen bu yaklaşım daha kullanışlı.

## Mülakatta

"`LEFT JOIN`'de koşulu `ON`'a yazmakla `WHERE`'e yazmak arasında fark var mı?" sorusu, junior ile daha tecrübeli adayı ayırmak için sık kullanılıyor. Bu örneği anlatabiliyorsan cevabın hazır: `INNER JOIN`'de fark yok, `LEFT JOIN`'de sağ tablonun koşulu `WHERE`'e yazılırsa eşleşmeyen satırlar elenir ve sorgu `INNER JOIN`'e dönüşür.

<!-- beklenen-satir: 200 -->
