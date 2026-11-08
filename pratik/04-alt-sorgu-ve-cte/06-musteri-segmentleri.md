# Müşteri segmentleri

Zorluk: Zor · Konu: birden fazla CTE, `LEFT JOIN`, `CASE`

## Soru

Pazarlama ekibi müşterileri toplam harcamalarına göre gruplamak istiyor. İptal ve iade edilen siparişler harcamaya dahil değil. Segmentler şöyle:

| Segment | Toplam harcama |
|---|---|
| Yüksek | 50.000 TL ve üzeri |
| Orta | 20.000 TL ile 50.000 TL arası |
| Düşük | 0'dan büyük, 20.000 TL'nin altı |
| Alışveriş yok | 0 (hiç geçerli siparişi yok) |

Her segmentte kaç müşteri olduğunu göster. En kalabalık segment en üstte olsun.

Doğru yaptıysan 4 satır gelir ve müşteri sayılarının toplamı 200 olur.

<details>
<summary>İpucu</summary>

Önce her müşterinin toplam harcamasını hesapla. Hiç siparişi olmayanların da listede kalması gerekiyor, `JOIN` modülündeki 5. soruyu hatırla. Sonra her müşteriye segmentini ver. En son da segmentleri say. Her adımı ayrı bir CTE olarak yazmak işini kolaylaştırır.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH musteri_harcama AS (
    SELECT m.musteri_id,
           COALESCE(SUM(k.adet * k.birim_fiyat), 0) AS harcama
    FROM musteriler AS m
    LEFT JOIN siparisler AS s
           ON s.musteri_id = m.musteri_id
          AND s.durum NOT IN ('iptal', 'iade')
    LEFT JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
    GROUP BY m.musteri_id
),
segmentli AS (
    SELECT musteri_id,
           CASE
               WHEN harcama >= 50000 THEN 'Yüksek'
               WHEN harcama >= 20000 THEN 'Orta'
               WHEN harcama > 0      THEN 'Düşük'
               ELSE 'Alışveriş yok'
           END AS segment
    FROM musteri_harcama
)
SELECT segment, COUNT(*) AS musteri_sayisi
FROM segmentli
GROUP BY segment
ORDER BY musteri_sayisi DESC;
```

</details>

## Açıklama

Bu soru şimdiye kadar gördüğün birçok şeyi birleştiriyor, o yüzden CTE'lerle adım adım gittik.

**1. adım, `musteri_harcama`:** Her müşterinin toplam harcaması. Hiç siparişi olmayan müşteriler de kalsın diye `LEFT JOIN` kullanıyoruz. İptal ve iade filtresini `WHERE`'e değil `ON`'a yazdık, `JOIN` modülündeki 5. soruda gördüğümüz sebepten. `COALESCE(..., 0)` siparişi olmayan müşteriler için `NULL` yerine 0 yazıyor.

**2. adım, `segmentli`:** Her müşteriye segmentini veriyoruz. `CASE` burada ilk kez karşına çıkıyor: koşulları yukarıdan aşağıya sırayla kontrol ediyor ve **ilk doğru olanın** sonucunu döndürüyor. Hiçbiri tutmazsa `ELSE` çalışıyor. 30.000 TL harcayan bir müşteri için ilk koşul (`>= 50000`) tutmuyor, ikincisi (`>= 20000`) tutuyor ve `'Orta'` dönüyor. Üçüncü koşula hiç bakılmıyor.

**3. adım:** Segmentleri `GROUP BY` ile sayıyoruz.

Bunların hepsini tek bir iç içe sorguda yazmak mümkün ama okuması çok zor olurdu. CTE ile her adım bir isim taşıyor ve yukarıdan aşağıya bir hikâye gibi okunuyor.

## Sık yapılan hatalar

- `CASE`'te koşulların sırasını karıştırmak. `CASE WHEN harcama > 0 THEN 'Düşük' WHEN harcama >= 20000 THEN 'Orta' ...` yazarsan, harcaması olan herkes ilk koşulda `'Düşük'` olur ve diğer koşullara hiç bakılmaz. 4 yerine 2 satır gelir: 180 "Düşük" ve 20 "Alışveriş yok". Aralıklarla çalışırken en dar ya da en uç koşulu en üste yaz.
- İptal ve iade filtresini `WHERE`'e yazmak. Hiç siparişi olmayan 20 müşteri elenir ve "Alışveriş yok" segmenti tamamen kaybolur, 3 satır gelir.
- `LEFT JOIN` yerine `JOIN` kullanmak. Aynı sonuç: siparişi olmayan müşteriler kaybolur.

<!-- beklenen-satir: 4 -->
