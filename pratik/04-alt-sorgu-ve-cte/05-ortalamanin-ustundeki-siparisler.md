# Ortalamanın üzerindeki siparişler

Zorluk: Orta · Konu: CTE (`WITH`)

## Soru

İptal ve iade edilenler hariç, tutarı ortalama sipariş tutarından yüksek olan siparişleri bul. Sipariş numarasını ve tutarını göster, en yüksek tutar en üstte olsun. Sipariş tutarı, o siparişin kalemlerinin `adet * birim_fiyat` toplamı.

Doğru yaptıysan 188 satır gelir.

<details>
<summary>İpucu</summary>

İki adım var: önce her siparişin tutarını hesapla, sonra bu tutarların ortalamasını bulup karşılaştır. İkinci adımda birinci adımın sonucunu iki kez kullanman gerekiyor. Aynı sorguyu iki kez yazmamanın bir yolu var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH siparis_tutarlari AS (
    SELECT s.siparis_id,
           SUM(k.adet * k.birim_fiyat) AS tutar
    FROM siparisler AS s
    JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
    WHERE s.durum NOT IN ('iptal', 'iade')
    GROUP BY s.siparis_id
)
SELECT siparis_id, tutar
FROM siparis_tutarlari
WHERE tutar > (SELECT AVG(tutar) FROM siparis_tutarlari)
ORDER BY tutar DESC;
```

</details>

## Açıklama

`WITH siparis_tutarlari AS (...)` bir sorgunun sonucuna isim veriyor. Buna CTE (Common Table Expression) deniyor. Sorgunun geri kalanında `siparis_tutarlari`'nı sanki gerçek bir tabloymuş gibi kullanabiliyorsun. Burada iki kez kullanıyoruz: bir kez satırları seçmek için, bir kez de ortalamayı hesaplamak için.

CTE'nin asıl faydası okunabilirlik. Uzun bir sorguyu adım adım, yukarıdan aşağıya okunacak parçalara bölüyorsun. "Önce sipariş tutarlarını hesapla, sonra ortalamanın üstündekileri seç" diye okunuyor.

Sonuçtaki tablo da öğretici: 854 siparişin ortalama tutarı 7.559,77 TL ama sadece 188'i bu değerin üstünde. Ortadaki değer olan medyan 2.697 TL. Az sayıdaki pahalı sipariş (bilgisayar, telefon) ortalamayı yukarı çekiyor.

## Alternatif çözüm

Aynı şey CTE olmadan, alt sorgularla da yazılabilir:

```sql
SELECT t.siparis_id, t.tutar
FROM (
    SELECT s.siparis_id, SUM(k.adet * k.birim_fiyat) AS tutar
    FROM siparisler AS s
    JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
    WHERE s.durum NOT IN ('iptal', 'iade')
    GROUP BY s.siparis_id
) AS t
WHERE t.tutar > (
    SELECT AVG(t2.tutar)
    FROM (
        SELECT SUM(k.adet * k.birim_fiyat) AS tutar
        FROM siparisler AS s
        JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
        WHERE s.durum NOT IN ('iptal', 'iade')
        GROUP BY s.siparis_id
    ) AS t2
)
ORDER BY t.tutar DESC;
```

Sonuç aynı, ama sipariş tutarını hesaplayan kısmı iki kez yazmak zorunda kaldık. Birini değiştirip diğerini unutursan sonuç bozulur. CTE'yi tercih etmenin sebebi tam olarak bu.

## Sık yapılan hatalar

Ortalamayı sipariş bazında değil kalem bazında almak. `AVG(k.adet * k.birim_fiyat)` yazarsan ortalama bir **kalemin** tutarını bulursun (2.925,26 TL), bir **siparişin** değil. Siparişler genelde birden fazla kalem içerdiği için bu sayı çok daha düşük çıkar ve 188 yerine 419 sipariş "ortalamanın üstünde" görünür. Ortalamayı neyin ortalaması olarak hesapladığına her zaman dikkat et.

## Mülakatta

"CTE ile alt sorgu arasındaki fark ne?" sorusuna: sonuç açısından genelde fark yok, CTE okunabilirliği artırır ve aynı ara sonucu birden fazla yerde kullanmayı kolaylaştırır.

Performans tarafında bilmen gereken bir ayrıntı var. PostgreSQL 12'den beri, sorguda **bir kez** kullanılan basit bir CTE'yi ana sorguyla birleştirip sanki hiç yazılmamış gibi optimize ediyor. **Birden fazla kez** kullanılan bir CTE ise (bu sorudaki gibi) varsayılan olarak bir kez hesaplanıp saklanıyor ve her kullanımda bu saklanan sonuç okunuyor. Bu sorgunun başına `EXPLAIN` yazarsan planda `CTE Scan on siparis_tutarlari` satırlarını görürsün. PostgreSQL 12'den önce bütün CTE'ler her zaman ayrı hesaplanıyordu, eski kaynaklarda "CTE yavaştır" denmesinin sebebi bu.

<!-- beklenen-satir: 188 -->
