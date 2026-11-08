# Aylık ve kümülatif ciro

Zorluk: Orta · Konu: kümülatif toplam, `SUM() OVER (ORDER BY ...)`

## Soru

2024'ün her ayı için o ayın cirosunu ve yılbaşından o aya kadar biriken toplam ciroyu (kümülatif ciro) göster. İptal ve iade edilen siparişler hariç. Aylara göre sırala.

Doğru yaptıysan 12 satır gelir. Kendini kontrol etmek için: Aralık satırındaki kümülatif ciro 6.456.039,33 TL olmalı. Bu, JOIN modülünün 8. sorusundaki toplam ciroyla aynı.

<details>
<summary>İpucu</summary>

Önce aylık ciroyu hesapla. Sonra her ay için "bu aya kadar olan bütün ayların toplamı" lazım. `SUM`'ı window function olarak kullanırken `ORDER BY` vermek ne değiştiriyor, onu düşün.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH aylik AS (
    SELECT date_trunc('month', s.siparis_tarihi)::date AS ay,
           SUM(k.adet * k.birim_fiyat)                 AS ciro
    FROM siparisler AS s
    JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
    WHERE s.durum NOT IN ('iptal', 'iade')
    GROUP BY ay
)
SELECT ay, ciro,
       SUM(ciro) OVER (ORDER BY ay) AS kumulatif_ciro
FROM aylik
ORDER BY ay;
```

</details>

## Açıklama

`SUM(ciro) OVER (ORDER BY ay)` her satır için "baştan bu satıra kadar olan satırların toplamı" demek. Ocak'ta sadece Ocak'ın cirosu, Şubat'ta Ocak + Şubat, Mart'ta ilk üç ayın toplamı. Bu yüzden son satır yılın toplamına eşit.

Buradaki incelik `ORDER BY`. Window function'a `ORDER BY` verdiğinde, PostgreSQL varsayılan olarak "baştan bu satıra kadar" diye bir pencere (çerçeve, frame) kullanıyor. `ORDER BY` vermezsen pencere bütün satırlar oluyor ve her satırda yılın toplamını görürsün.

İlk adımı CTE'ye koyduk ki önce aylık ciro hesaplansın, sonra kümülatif toplam onun üstüne kurulsun.

## Alternatif çözüm

CTE olmadan tek sorguda da yazılabilir. `GROUP BY` ile hesaplanan `SUM`'ın üstüne bir window `SUM` daha koyuyoruz:

```sql
SELECT date_trunc('month', s.siparis_tarihi)::date AS ay,
       SUM(k.adet * k.birim_fiyat)                 AS ciro,
       SUM(SUM(k.adet * k.birim_fiyat)) OVER (
           ORDER BY date_trunc('month', s.siparis_tarihi)::date
       )                                           AS kumulatif_ciro
FROM siparisler AS s
JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
WHERE s.durum NOT IN ('iptal', 'iade')
GROUP BY ay
ORDER BY ay;
```

`SUM(SUM(...)) OVER (...)` ilk bakışta tuhaf görünüyor. İçteki `SUM` normal toplama fonksiyonu, her ay için ciroyu hesaplıyor. Dıştaki `SUM ... OVER` ise bu aylık sonuçlar üzerinde çalışan window function. Çalışıyor ama CTE'li hâli bence çok daha kolay okunuyor.

## Sık yapılan hatalar

**`OVER ()` içinde `ORDER BY`'ı unutmak.** `SUM(ciro) OVER ()` her satırda 6.456.039,33 TL gösterir, yani her satıra yılın toplamını yazar.

**`ORDER BY` kolonunda tekrar eden değerler olması.** Varsayılan pencere, `ORDER BY`'da aynı değere sahip bütün satırları birlikte sayıyor. Aylık veride her ay bir kez geçtiği için sorun yok. Ama aynı kümülatif hesabı sipariş bazında, `ORDER BY siparis_tarihi::date` ile yaparsan aynı güne düşen siparişler aynı değeri alır. Örneğin 1 Aralık'ta verilen 897, 898 ve 899 numaralı siparişlerin üçü de kümülatif sayıda 899 görünür, 897, 898, 899 diye artmaz. Satır satır artmasını istiyorsan çerçeveyi açıkça yaz ve eşitliği bozacak bir kolon ekle:

```text
COUNT(*) OVER (ORDER BY siparis_tarihi::date, siparis_id
               ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW)
```

<!-- beklenen-satir: 12 -->
