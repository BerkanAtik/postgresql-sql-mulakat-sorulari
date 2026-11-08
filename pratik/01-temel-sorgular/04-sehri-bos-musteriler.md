# Şehri boş olan müşteriler

Zorluk: Kolay · Konu: `NULL`, `IS NULL`

## Soru

Bazı müşteriler kayıt olurken şehir bilgisini girmemiş. Müşteri hizmetleri bu kişilere bilgilerini güncellemeleri için mail atacak. Şehri boş olan müşterilerin `ad`, `soyad` ve `email` bilgisini listele.

Doğru yaptıysan 8 satır gelir.

<details>
<summary>İpucu</summary>

Boşluğu kontrol ederken alıştığın `=` işaretini kullanamazsın. SQL'de bunun için ayrı bir ifade var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, soyad, email
FROM musteriler
WHERE sehir IS NULL;
```

</details>

## Açıklama

`NULL` "değer yok" ya da "bilinmiyor" demek. Boş metin (`''`) değil, sıfır da değil. Bilinmeyen bir şeyin neye eşit olduğunu da bilemezsin. O yüzden `sehir = NULL` ifadesi `TRUE` ya da `FALSE` değil, yine `NULL` döndürür. `WHERE` sadece `TRUE` çıkan satırları alır, `NULL` çıkanları sessizce eler. Sonuç: hiç satır gelmez, hata da çıkmadığı için neyin yanlış gittiğini anlamak zor olur.

Kendin görmek istersen `SELECT NULL = NULL;` çalıştır. `true` gelmez, boş görünen bir `NULL` gelir.

Kontrol için doğru ifade `IS NULL`, tersi de `IS NOT NULL`.

## Sık yapılan hatalar

- `WHERE sehir = NULL`: hata vermez, 0 satır döner.
- `WHERE sehir = ''`: boş metinle `NULL` farklı şeyler. Bizim veride şehri boş metin olan müşteri yok, hepsi gerçek `NULL`. Bu da 0 satır döner.

## Mülakatta

`NULL` ile ilgili en sevilen sorulardan biri: "`COUNT(*)` ile `COUNT(sehir)` aynı sonucu verir mi?"

Vermez. `COUNT(*)` satırları sayar, `NULL` olup olmadığına bakmaz. `COUNT(sehir)` ise sadece o kolonu dolu olan satırları sayar. Bizim `musteriler` tablosunda `COUNT(*)` 200, `COUNT(sehir)` 192 döner. Aradaki 8 fark, şehri boş olan müşteriler.

<!-- beklenen-satir: 8 -->
