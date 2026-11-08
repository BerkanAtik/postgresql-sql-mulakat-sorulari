# Yönetim zinciri

Zorluk: Zor · Konu: `WITH RECURSIVE`

## Soru

Her çalışanın organizasyondaki seviyesini bul: genel müdür 1. seviye, ona bağlı çalışanlar 2. seviye ve böyle devam ediyor. Bir de genel müdürden o çalışana kadar olan yönetim zincirini tek bir metin olarak göster (`Murat > Hakan > Ceren > Kaan` gibi). Sonuç seviyeye, aynı seviyedekiler de çalışan numarasına göre sıralı olsun.

Doğru yaptıysan 15 satır gelir.

<details>
<summary>İpucu</summary>

Kaç seviye olduğunu bilmiyorsun, yani kaç kez self join yapacağını önceden yazamazsın. Kendini tekrar eden bir CTE kurman gerekiyor: başlangıç noktası genel müdür, sonra her adımda bir önceki adımda bulunanların altındaki çalışanlar.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH RECURSIVE hiyerarsi AS (
    -- Başlangıç: yöneticisi olmayan genel müdür
    SELECT calisan_id, ad, soyad,
           1  AS seviye,
           ad AS zincir
    FROM calisanlar
    WHERE yonetici_id IS NULL

    UNION ALL

    -- Tekrar eden kısım: bir önceki adımda bulunanların altındakiler
    SELECT c.calisan_id, c.ad, c.soyad,
           h.seviye + 1,
           h.zincir || ' > ' || c.ad
    FROM calisanlar AS c
    JOIN hiyerarsi AS h ON c.yonetici_id = h.calisan_id
)
SELECT calisan_id, ad, soyad, seviye, zincir
FROM hiyerarsi
ORDER BY seviye, calisan_id;
```

</details>

## Açıklama

`WITH RECURSIVE`, kendine atıfta bulunabilen bir CTE. İki parçası var ve aralarında `UNION ALL` duruyor:

1. **Başlangıç kısmı** bir kez çalışır. Burada genel müdürü buluyoruz: seviye 1, zincir de sadece kendi adı.
2. **Tekrar eden kısım** `hiyerarsi`'nın kendisine `JOIN` yapıyor. İlk turda "genel müdüre bağlı olanları" bulur (seviye 2). İkinci turda "o bulunanlara bağlı olanları" bulur (seviye 3). Her turda bir alt kademeye iniyor ve seviyeyi bir artırıp zincire yeni adı ekliyor.

Tekrar eden kısım yeni satır bulamadığında, yani en alttaki çalışanlara ulaşınca sorgu kendiliğinden duruyor. Bizim şirkette dört seviye var: 1 genel müdür, 3 müdür, 6 kişi 3. seviyede, 5 kişi 4. seviyede.

Bu yapı ağaç gibi her veride işe yarıyor: kategori ve alt kategoriler, yorumlara verilen cevaplar, ürünün parçaları gibi.

## Sık yapılan hatalar

- Başlangıç kısmındaki `WHERE yonetici_id IS NULL` koşulunu unutmak. O zaman her çalışan ayrı bir başlangıç noktası olur ve herkesin alt ağacı ayrı ayrı gezilir. 15 yerine 45 satır gelir, aynı çalışan birden fazla seviyede görünür.
- Veride döngü olması. Örneğin A'nın yöneticisi B, B'nin yöneticisi de A olsaydı sorgu hiç durmazdı. Gerçek veride bu risk varsa seviyeye bir sınır koyabilirsin (`WHERE h.seviye < 20` gibi). PostgreSQL 14'ten beri döngüleri yakalamak için `CYCLE` ifadesi de var.

## Mülakatta

Recursive CTE junior mülakatlarında her zaman sorulmaz, ama sorulduğunda adayı öne çıkarır. "Kaç seviye olduğunu bilmediğin bir hiyerarşiyi nasıl sorgularsın?" sorusuna cevabın `WITH RECURSIVE`: bir başlangıç kısmı, bir de kendine `JOIN` yapan tekrar eden kısım.

<!-- beklenen-satir: 15 -->
