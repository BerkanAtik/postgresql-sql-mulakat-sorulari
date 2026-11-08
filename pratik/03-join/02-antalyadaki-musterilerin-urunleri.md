# Antalya'daki müşterilerin aldığı ürünler

Zorluk: Kolay · Konu: birden fazla tabloyu `JOIN` etmek, `DISTINCT`

## Soru

Antalya'da yaşayan müşterilerin sipariş verdiği ürünlerin adlarını listele. Her ürün listede bir kez geçsin, sonuç alfabetik sıralı olsun.

Doğru yaptıysan 38 satır gelir.

<details>
<summary>İpucu</summary>

Şehir bilgisi `musteriler`'de, ürün adı `urunler`'de. Arada iki tablo daha var. Müşteriden ürüne giden yolu adım adım düşün: müşteri, sipariş verir. Siparişin içinde kalemler olur. Her kalem bir ürüne bağlıdır.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT DISTINCT u.ad
FROM musteriler AS m
JOIN siparisler        AS s ON s.musteri_id = m.musteri_id
JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
JOIN urunler           AS u ON u.urun_id    = k.urun_id
WHERE m.sehir = 'Antalya'
ORDER BY u.ad;
```

</details>

## Açıklama

Her `JOIN` bir adım ilerliyor: müşteriden siparişe, siparişten kalemlere, kalemlerden ürüne. Tablolar arasında doğrudan bir bağ yoksa aradaki tabloları da sorguya katman gerekiyor. Bu zinciri kurarken [veritabanı sayfasındaki](../../db/README.md) şemaya bakmak çok işe yarar.

`DISTINCT` neden lazım? Antalya'da 16 müşteri var, 14'ü sipariş vermiş. Aynı ürünü birden fazla kişi, hatta aynı kişi birden fazla kez almış. `DISTINCT` olmadan sorgu her sipariş kalemini ayrı bir satır olarak döndürür, 177 satır gelir.

## Sık yapılan hatalar

- `DISTINCT`'i unutmak. 38 yerine 177 satır gelir, aynı ürün defalarca tekrar eder.
- `DISTINCT` kullanıp seçmediğin bir kolona göre sıralamak. `SELECT DISTINCT u.ad ... ORDER BY u.fiyat` yazarsan PostgreSQL `for SELECT DISTINCT, ORDER BY expressions must appear in select list` hatası verir. Aynı ada sahip satırlar teke indirildiği için hangi fiyata göre sıralanacağı belli değil. Fiyata göre sıralamak istiyorsan `u.fiyat`'ı da seçmen gerekiyor.

<!-- beklenen-satir: 38 -->
