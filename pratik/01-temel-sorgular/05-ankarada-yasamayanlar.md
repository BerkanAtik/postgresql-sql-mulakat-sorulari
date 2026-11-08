# Ankara'da yaşamayan müşteriler

Zorluk: Orta · Konu: `NULL`, `<>`, `IS DISTINCT FROM`

## Soru

Ankara'da yaşamayan bütün müşterilerin `ad`, `soyad` ve `sehir` bilgisini listele.

Doğru yaptıysan 168 satır gelir. Tabloda 200 müşteri var, 32'si Ankara'da.

<details>
<summary>İpucu</summary>

`<>` ile yazınca 160 satır geliyorsa, kayıp 8 müşterinin ortak bir özelliği var. Bir önceki soruyu hatırla.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, soyad, sehir
FROM musteriler
WHERE sehir <> 'Ankara' OR sehir IS NULL;
```

</details>

## Açıklama

Aklına ilk gelen büyük ihtimalle `WHERE sehir <> 'Ankara'`. Hata vermeden çalışıyor ve 160 satır döndürüyor ama 8 müşteri eksik.

Sebebi yine `NULL`. Şehri boş bir müşteri için `sehir <> 'Ankara'` ifadesi "bilinmeyen bir şey Ankara'dan farklı mı?" diye soruyor, cevap da `TRUE` ya da `FALSE` değil `NULL` oluyor. `WHERE` sadece `TRUE` olanı aldığı için bu müşteriler sessizce elenir.

Oysa "Ankara'da yaşamıyor" dediğimizde şehri bilinmeyenleri de kastediyoruz. Bunu sorguya senin yazman gerekiyor: `OR sehir IS NULL`.

Bu yüzden sonuç sayısına bakıp "bu kadar mı olmalıydı?" diye sormak çok işe yarıyor. Burada 200 - 32 = 168 olması gerektiğini bildiğin için farkı yakalayabildin. Gerçek bir tabloda bunu hesaplamak için `COUNT` ile ayrıca kontrol etmek gerekir.

## Alternatif çözüm

PostgreSQL'de `NULL`'ı da hesaba katan bir karşılaştırma var:

```sql
SELECT ad, soyad, sehir
FROM musteriler
WHERE sehir IS DISTINCT FROM 'Ankara';
```

`IS DISTINCT FROM`, `NULL`'ı sıradan bir değer gibi karşılaştırır. İki `NULL` birbirine eşit sayılır, `NULL` ile `'Ankara'` ise farklı. Standart SQL'de var ama her veritabanında yok. MySQL'de karşılığı `<=>` operatörü.

## Sık yapılan hatalar

`WHERE sehir NOT IN ('Ankara')` de 160 satır döndürür, `<>` ile aynı tuzağa düşer. `NOT IN`'in ayrıca başka bir sorunu da var: listede ya da alt sorgunun sonucunda tek bir `NULL` bile varsa hiç satır dönmeyebilir. Alt sorgular modülünde buna tekrar bakacağız.

Mülakatta "`NULL` yüzünden hiç sorun yaşadın mı?" diye sorulursa bu örnek güzel bir cevap. Kolon `NULL` olabiliyorsa `<>`, `NOT IN` ve `NOT LIKE` gibi olumsuz koşullarda o satırların kaybolabileceğini söylemen yeterli.

<!-- beklenen-satir: 168 -->
