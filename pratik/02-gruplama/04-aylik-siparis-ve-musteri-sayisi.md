# Aylık sipariş sayısı ve farklı müşteri sayısı

Zorluk: Orta · Konu: `COUNT(DISTINCT)`, `date_trunc`, `GROUP BY`

## Soru

2024'ün her ayı için kaç sipariş verildiğini ve bu siparişleri kaç farklı müşterinin verdiğini listele. Sonuç aylara göre, ocaktan aralığa doğru sıralı olsun. Ay bilgisi, ayın ilk günü olarak (`2024-01-01` gibi) görünsün.

Doğru yaptıysan 12 satır gelir.

<details>
<summary>İpucu</summary>

Siparişleri aya göre gruplamak için tarihi ayın başına yuvarlayan bir fonksiyon kullanabilirsin (`date_trunc`). Aynı müşterinin bir ay içinde birden fazla sipariş vermesi mümkün, bunu sayarken hesaba katman gerekiyor.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT date_trunc('month', siparis_tarihi)::date AS ay,
       COUNT(*)                                  AS siparis_sayisi,
       COUNT(DISTINCT musteri_id)                AS musteri_sayisi
FROM siparisler
GROUP BY ay
ORDER BY ay;
```

</details>

## Açıklama

`date_trunc('month', siparis_tarihi)`, tarihi ayın başına yuvarlar: `2024-03-17 14:25` olan bir sipariş `2024-03-01 00:00` olur. Aynı aydaki bütün siparişler aynı değeri aldığı için tarihi bu şekilde gruplayabiliyoruz. `::date` ise saat kısmını atıp sadece tarihi gösteriyor.

Burada asıl konu `COUNT(*)` ile `COUNT(DISTINCT musteri_id)` farkı. `COUNT(*)` o aydaki sipariş sayısı. `COUNT(DISTINCT musteri_id)` ise o ay en az bir sipariş veren müşteri sayısı, aynı müşteri bir ayda üç sipariş verse bile bir kez sayılır. Ocak ayında 46 sipariş, ama bunları 43 farklı müşteri vermiş.

Bir tuzak da şu: aylık farklı müşteri sayılarını toplarsan 767 çıkar. Oysa yıl boyunca sipariş veren farklı müşteri sayısı sadece 180. Çünkü aynı müşteri farklı aylarda tekrar sayılıyor. Yani `COUNT(DISTINCT)` değerlerini gruplar arasında toplayamazsın, "yıl için toplam" lazımsa onu ayrı bir sorguda hesaplamak gerekir.

`GROUP BY ay` yazabilmemizin sebebi PostgreSQL'in `GROUP BY` ve `ORDER BY`'da `SELECT`'teki takma adı kabul etmesi. Bu her veritabanında böyle değil, mesela SQL Server'da `GROUP BY` içinde takma ad kullanamazsın.

## Alternatif çözüm

Ayı metin olarak (`2024-03` gibi) istersen `to_char` ile de gruplayabilirsin:

```sql
SELECT to_char(siparis_tarihi, 'YYYY-MM') AS ay,
       COUNT(*)                           AS siparis_sayisi,
       COUNT(DISTINCT musteri_id)         AS musteri_sayisi
FROM siparisler
GROUP BY ay
ORDER BY ay;
```

Çıktının görünümü farklı ama gruplar ve sayılar aynı. Bu sürümde `ay` bir tarih değil metin, tarih fonksiyonlarını sonradan kullanmak istiyorsan ilk çözümdeki gibi tarih olarak bırakmak daha rahat.

## Sık yapılan hatalar

`COUNT(musteri_id)` yazmak. Bu, "farklı" değil "boş olmayan" müşteri sayısını verir, yani `COUNT(*)` ile aynı sonucu döndürür. Tekrarları elemek için `DISTINCT` yazman şart.

## Mülakatta

"Bu ay kaç farklı kullanıcı aktifti?" tarzı sorular mülakatlarda sık gelir. Cevabın `COUNT(DISTINCT kullanici_id)` ve ardından uyarı: büyük tablolarda `DISTINCT` hesabı pahalıdır, çünkü veritabanı değerleri ayrıca tekilleştirmek zorunda.

<!-- beklenen-satir: 12 -->
<!-- alternatif-cikti-farkli -->
<!-- to_char alternatifi ayı '2024-01' metni olarak gösteriyor; değerlerin aynı olduğu ayrıca kontrol edildi. -->

