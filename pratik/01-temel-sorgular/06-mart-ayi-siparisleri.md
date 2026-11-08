# Mart ayında verilen siparişler

Zorluk: Orta · Konu: tarih filtreleme, `TIMESTAMP`, `BETWEEN`

## Soru

2024 Mart ayında verilen bütün siparişlerin `siparis_id`, `musteri_id`, `siparis_tarihi` ve `durum` bilgisini listele. İptal ve iade olanlar da listede olsun.

Doğru yaptıysan 71 satır gelir.

<details>
<summary>İpucu</summary>

`siparis_tarihi` sadece gün değil, saat ve dakikayı da tutuyor (`TIMESTAMP`). Ayın son günü olan 31 Mart'ta verilen siparişleri kaçırmamaya dikkat et.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT siparis_id, musteri_id, siparis_tarihi, durum
FROM siparisler
WHERE siparis_tarihi >= '2024-03-01'
  AND siparis_tarihi <  '2024-04-01';
```

</details>

## Açıklama

Buna "yarı açık aralık" diyorlar: başlangıç dahil, bitiş hariç. Mart için `2024-03-01` dahil, `2024-04-01` hariç yazıyoruz. Yani 1 Mart saat 00:00'dan 31 Mart gece yarısına kadar her şey içeri giriyor.

Neden "31 Mart'a kadar" yazmıyoruz? Çünkü ayın kaç gün çektiğini ve günün son saniyesinin ne olduğunu düşünmek zorunda kalmak istemiyoruz. Şubat 28 mi 29 mu çeker, saniyenin kesirleri var mı gibi sorular ortadan kalkıyor. Bir sonraki ayın ilk gününü yazmak her zaman doğru çalışıyor.

Kolon `DATE`, `TIMESTAMP` ya da `TIMESTAMPTZ` olsa da aynı kalıp işe yarıyor.

## Alternatif çözüm

Tarihin parçalarına bakarak da yapabilirsin:

```sql
SELECT siparis_id, musteri_id, siparis_tarihi, durum
FROM siparisler
WHERE date_trunc('month', siparis_tarihi) = DATE '2024-03-01';
```

```sql
SELECT siparis_id, musteri_id, siparis_tarihi, durum
FROM siparisler
WHERE EXTRACT(YEAR FROM siparis_tarihi) = 2024
  AND EXTRACT(MONTH FROM siparis_tarihi) = 3;
```

İkisi de doğru sonucu veriyor, hatta okuması daha kolay. Ama bir bedeli var: kolonun üzerine fonksiyon uyguladığında veritabanı o kolondaki index'i genelde kullanamıyor. `siparis_tarihi` üzerinde index olsaydı yarı açık aralıkla yazdığın ilk çözüm onu kullanırdı, bu ikisi kullanamazdı. Tablo büyüdükçe bu fark çok hissedilir. Index'leri ilerleyen modüllerde göreceğiz.

## Sık yapılan hatalar

`BETWEEN '2024-03-01' AND '2024-03-31'` yazmak. Hata vermez ama 71 yerine 69 satır döndürür, iki sipariş kaybolur.

`'2024-03-31'`, PostgreSQL'de `2024-03-31 00:00:00` olarak okunuyor. `BETWEEN` iki ucu da dahil ediyor ama 31 Mart'ta saat 00:00'dan sonra verilen siparişler aralığın dışında kalıyor. Bizim veride o gün sabah 08:35 ve 09:28'de verilmiş iki sipariş var, kaybolanlar bunlar.

Bitişi `'2024-03-31 23:59:59'` yapmak da bizim veride doğru sonuç verir ama sağlam değil. Saniyenin kesri olan bir kayıt (`23:59:59.5` gibi) yine dışarıda kalır.

## Mülakatta

"Tarih aralığı sorgularında `BETWEEN` kullanırken nelere dikkat edersin?" diye sorulursa: kolon sadece tarih değil saat de tutuyorsa `BETWEEN` bitiş gününü yarım bırakır, o yüzden `>=` ve `<` ile yarı açık aralık kullanırım.

<!-- beklenen-satir: 71 -->
