# Ana kategorilere göre ciro

Zorluk: Zor · Konu: çok tablolu `JOIN`, aynı tabloyu iki kez kullanmak, `GROUP BY`

## Soru

Yönetim, cironun ana kategorilere (Elektronik, Giyim, Kitap gibi) göre dağılımını görmek istiyor. Her ana kategori için toplam ciroyu hesapla. İptal edilen ve iade olan siparişler ciroya dahil olmasın. En yüksek ciro en üstte olsun.

Doğru yaptıysan 5 satır gelir. Kendini kontrol etmek için: beş satırın toplamı 6.456.039,33 TL olmalı.

<details>
<summary>İpucu</summary>

Ciroyu `siparis_kalemleri`'nden hesaplıyorsun (`adet * birim_fiyat`). Ürünler alt kategorilere bağlı (Telefon, Roman gibi), ana kategoriye ulaşmak için alt kategorinin `ust_kategori_id`'sini takip etmen gerekiyor. Yani `kategoriler` tablosuna iki kez ihtiyacın var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT ana.ad                        AS ana_kategori,
       SUM(k.adet * k.birim_fiyat)   AS ciro
FROM siparis_kalemleri AS k
JOIN siparisler   AS s   ON s.siparis_id   = k.siparis_id
JOIN urunler      AS u   ON u.urun_id      = k.urun_id
JOIN kategoriler  AS alt ON alt.kategori_id = u.kategori_id
JOIN kategoriler  AS ana ON ana.kategori_id = alt.ust_kategori_id
WHERE s.durum NOT IN ('iptal', 'iade')
GROUP BY ana.ad
ORDER BY ciro DESC;
```

</details>

## Açıklama

Sorguyu parça parça okuyalım:

- `siparis_kalemleri` ile başlıyoruz, çünkü ciro bilgisi orada.
- `siparisler`'i durumu kontrol etmek için ekliyoruz, iptal ve iadeleri `WHERE` ile eleyeceğiz.
- `urunler` bize kalemin hangi kategoride olduğunu söylüyor, ama bu bir alt kategori.
- `kategoriler`'i ilk kez `alt` adıyla ekliyoruz. Bu, ürünün alt kategorisi.
- `kategoriler`'i ikinci kez `ana` adıyla ekliyoruz. `alt.ust_kategori_id` bizi ana kategoriye götürüyor.

Aynı tabloyu iki kez kullanmak self join'in bir başka hâli. Önceki sorularda çalışan-yönetici ilişkisi vardı, burada alt kategori-ana kategori ilişkisi var.

Bir ayrıntı: burada `JOIN` kullanmak güvenli, çünkü bizim veride bütün ürünler bir alt kategoriye bağlı. Eğer doğrudan ana kategoriye bağlı bir ürün olsaydı, onun alt kategorisinin `ust_kategori_id`'si `NULL` olurdu ve `JOIN` o ürünün cirosunu sessizce kaybederdi. Gerçek bir veride bunu kontrol etmeden varsaymamak lazım.

## Sık yapılan hatalar

- Ciroyu `u.fiyat` ile hesaplamak. `urunler.fiyat` ürünün **şu anki** fiyatı, `siparis_kalemleri.birim_fiyat` ise **satıldığı andaki** fiyat. Bazı ürünler indirimli satılmış, `u.fiyat` ile hesaplarsan toplam 6.488.254,20 TL çıkar, yani olmayan bir ciroyu raporlamış olursun.
- Sadece `durum <> 'iptal'` yazmak. Soruda iadeler de hariç diyor, iadeleri de katarsan toplam 6.936.728,39 TL olur.
- `kategoriler`'i tek kez kullanıp `alt.ad`'a göre gruplamak. O zaman ana kategoriler değil alt kategoriler gelir ve 5 yerine 11 satır görürsün.

<!-- beklenen-satir: 5 -->
