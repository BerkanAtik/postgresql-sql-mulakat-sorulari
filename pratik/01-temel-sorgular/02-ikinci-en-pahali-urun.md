# İkinci en pahalı ürün

Zorluk: Kolay · Konu: `ORDER BY`, `LIMIT`, `OFFSET`

## Soru

Fiyatı en yüksek **ikinci** ürünün adını ve fiyatını bul.

Mülakatlarda bu genelde "ikinci en yüksek maaş" diye sorulur. Tablo değişir ama mantık aynı. Sonuç tek satır olmalı.

<details>
<summary>İpucu</summary>

Önce ürünleri pahalıdan ucuza sırala. Sonra ilk satırı atlayıp bir sonrakini almanın yolunu düşün.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ad, fiyat
FROM urunler
ORDER BY fiyat DESC
LIMIT 1 OFFSET 1;
```

</details>

## Açıklama

`ORDER BY fiyat DESC` en pahalıyı başa alır. `OFFSET 1` baştaki bir satırı atlar, `LIMIT 1` de ondan sonraki tek satırı alır. Üçüncü en pahalı için `OFFSET 2` yazarsın.

`ORDER BY` olmadan `LIMIT` ve `OFFSET` kullanma. PostgreSQL, sıra vermezsen satırları hangi sırayla döneceğini garanti etmez. O zaman "ikinci satır" dediğin şey rastgele bir satır olur.

## Alternatif çözüm

`LIMIT` kullanmadan, iç içe iki alt sorguyla da yapılır:

```sql
SELECT ad, fiyat
FROM urunler
WHERE fiyat = (
    SELECT MAX(fiyat)
    FROM urunler
    WHERE fiyat < (SELECT MAX(fiyat) FROM urunler)
);
```

En içteki sorgu en yüksek fiyatı buluyor. Ortadaki, ondan küçük fiyatların en büyüğünü yani ikinci en yüksek fiyatı. En dıştaki de o fiyattaki ürünü getiriyor.

## Mülakatta

Bunu cevapladıktan sonra büyük ihtimalle şunu soracaklar: "İki ürünün fiyatı aynı olsaydı ne olurdu?"

Bizim veride en yüksek fiyatlar farklı, o yüzden iki çözüm aynı sonucu veriyor ama aslında farklı şeyler yapıyorlar. `LIMIT 1 OFFSET 1` sıralamadaki ikinci ürünü getirir. En pahalı iki ürünün fiyatı aynıysa ikinci satır yine en yüksek fiyatlı ürün olur. Alt sorgulu çözüm ise gerçekten ikinci en yüksek fiyatı bulur ve o fiyattaki bütün ürünleri döndürür.

Önce "ikinci ürünü mü istiyorsunuz, ikinci en yüksek fiyatı mı?" diye sormak, direkt kod yazmaktan daha iyi izlenim bırakır. Window functions modülünde `DENSE_RANK` ile üçüncü bir yol göreceğiz.

<!-- beklenen-satir: 1 -->
