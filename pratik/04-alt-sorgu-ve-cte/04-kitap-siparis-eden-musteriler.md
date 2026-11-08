# Kitap sipariş eden müşteriler

Zorluk: Orta · Konu: `EXISTS`, `IN`

## Soru

Yayınevi ile ortak bir kampanya yapılacak. En az bir kez **Kitap** ana kategorisinden (Roman ya da Yazılım Kitapları) ürün sipariş etmiş müşterilerin `musteri_id`, `ad` ve `soyad` bilgisini listele. Her müşteri bir kez görünsün, müşteri numarasına göre sırala.

Doğru yaptıysan 159 satır gelir.

<details>
<summary>İpucu</summary>

Müşteriden kategoriye giden yol uzun: sipariş, kalem, ürün, alt kategori, ana kategori. Bu yolu `JOIN`'lerle kurup sonucu müşteri başına teke indirebilirsin. Ama "en az bir tane var mı?" sorusu için daha doğrudan bir ifade var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT m.musteri_id, m.ad, m.soyad
FROM musteriler AS m
WHERE EXISTS (
    SELECT 1
    FROM siparisler        AS s
    JOIN siparis_kalemleri AS k   ON k.siparis_id    = s.siparis_id
    JOIN urunler           AS u   ON u.urun_id       = k.urun_id
    JOIN kategoriler       AS alt ON alt.kategori_id = u.kategori_id
    JOIN kategoriler       AS ana ON ana.kategori_id = alt.ust_kategori_id
    WHERE s.musteri_id = m.musteri_id
      AND ana.ad = 'Kitap'
)
ORDER BY m.musteri_id;
```

</details>

## Açıklama

`EXISTS`, alt sorgu en az bir satır bulursa `TRUE` döner. Alt sorgunun ne seçtiği önemli değil, sadece satır olup olmadığına bakılıyor. O yüzden `SELECT 1` yazıyoruz.

Bu sorunun özü şu: müşteri listesi istiyoruz, ama koşul başka tablolarda. `JOIN` ile yazsaydık her kitap kalemi için müşteri bir kez daha tekrar ederdi. `EXISTS` ise müşteriyi tekrarlamıyor, sadece "bu müşteri için böyle bir kayıt var mı?" diye bakıyor. Bir tane bulduğunda aramayı bırakabiliyor.

Alt sorgudaki `WHERE s.musteri_id = m.musteri_id`, onu dıştaki müşteriye bağlıyor. Bu da önceki sorulardaki gibi bir correlated subquery.

Sipariş vermiş 180 müşterinin 159'u en az bir kez kitap almış. Geriye kalan 21 müşteri hiç kitap sipariş etmemiş.

## Alternatif çözüm

`IN` ile de yazılabilir. Alt sorgu kitap alan müşterilerin numaralarını getiriyor, dıştaki sorgu da bu listede olanları seçiyor:

```sql
SELECT m.musteri_id, m.ad, m.soyad
FROM musteriler AS m
WHERE m.musteri_id IN (
    SELECT s.musteri_id
    FROM siparisler        AS s
    JOIN siparis_kalemleri AS k   ON k.siparis_id    = s.siparis_id
    JOIN urunler           AS u   ON u.urun_id       = k.urun_id
    JOIN kategoriler       AS alt ON alt.kategori_id = u.kategori_id
    JOIN kategoriler       AS ana ON ana.kategori_id = alt.ust_kategori_id
    WHERE ana.ad = 'Kitap'
)
ORDER BY m.musteri_id;
```

Alt sorgu aynı müşteri numarasını yüzlerce kez döndürse bile `IN` sonucu tekrarlamıyor, her müşteri bir kez geliyor.

## Sık yapılan hatalar

`EXISTS` ya da `IN` yerine bütün tabloları doğrudan `JOIN` edip `DISTINCT`'i unutmak. Her kitap kalemi ayrı bir satır olduğu için 159 yerine 524 satır gelir. `DISTINCT` eklersen doğru sonuca ulaşırsın, ama önce bütün eşleşmeleri üretip sonra temizlemiş olursun. "Var mı yok mu" sorusunda `EXISTS` niyeti daha açık gösteriyor.

<!-- beklenen-satir: 159 -->
