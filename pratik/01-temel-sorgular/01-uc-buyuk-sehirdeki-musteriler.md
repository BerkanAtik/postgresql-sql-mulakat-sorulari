# Üç büyük şehirdeki müşteriler

Zorluk: Kolay · Konu: `WHERE`, `IN`, `ORDER BY`

## Soru

Pazarlama ekibi İstanbul, Ankara ve İzmir'deki müşterilere kampanya maili atacak. Bu üç şehirde yaşayan müşterilerin `ad`, `soyad` ve `sehir` bilgisini getir. Liste şehre göre sıralı olsun, aynı şehirdekiler de kendi içinde soyada göre.

Doğru yaptıysan 112 satır gelir.

<details>
<summary>İpucu</summary>

Aynı kolonu üç değerle karşılaştırmak için `OR`'u üç kere yazmana gerek yok, daha kısa bir yolu var. `ORDER BY`'a da birden fazla kolon verebilirsin, virgülle ayırman yeterli.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, soyad, sehir
FROM musteriler
WHERE sehir IN ('İstanbul', 'Ankara', 'İzmir')
ORDER BY sehir, soyad;
```

</details>

## Açıklama

`IN`, `sehir = 'İstanbul' OR sehir = 'Ankara' OR sehir = 'İzmir'` yazmanın kısası. Üç değerde pek fark etmez ama liste uzadıkça `OR` zinciri okunmaz hâle gelir, `IN` temiz kalır.

`ORDER BY sehir, soyad` önce şehre göre dizer, şehri aynı olanları da soyada göre. Kolonların yanına tek tek `ASC` ya da `DESC` yazabilirsin, yazmazsan `ASC` kabul edilir.

Bir de şunu bil: Türkçe harflerin (Ç, Ş, İ gibi) sıralaması veritabanının collation ayarına bağlı. Veritabanı Türkçe alfabeye göre kurulmadıysa bu harfler beklediğin yerde çıkmayabilir. Bunu sorgunun hatası sanma.

## Alternatif çözüm

İstersen `OR` ile de yazabilirsin, sonuç aynı:

```sql
SELECT ad, soyad, sehir
FROM musteriler
WHERE sehir = 'İstanbul' OR sehir = 'Ankara' OR sehir = 'İzmir'
ORDER BY sehir, soyad;
```

## Sık yapılan hatalar

- `WHERE sehir = 'İstanbul' OR 'Ankara' OR 'İzmir'` yazmak. Türkçe cümle gibi okununca doğru geliyor ama SQL'de `OR`'un iki yanı da tam bir koşul olmak zorunda. PostgreSQL hata verir.
- Çift tırnak kullanmak. PostgreSQL'de çift tırnak kolon ya da tablo adı demek, `"İstanbul"` yazarsan o adda bir kolon arar ve `column "İstanbul" does not exist` hatası alırsın. Metinler tek tırnakla yazılır.
- Büyük küçük harfi karıştırmak. `'istanbul'` yazarsan hiçbir satır gelmez, çünkü metin karşılaştırması büyük küçük harfe duyarlı.

<!-- beklenen-satir: 112 -->
