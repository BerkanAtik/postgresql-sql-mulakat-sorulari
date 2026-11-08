# Kimseyi yönetmeyen çalışanlar

Zorluk: Orta · Konu: `NOT IN` ile `NULL` tuzağı, `NOT EXISTS`

## Soru

Altında hiç çalışan olmayan, yani kimsenin yöneticisi olmayan çalışanları bul. `calisan_id`, `ad` ve `soyad` bilgisini listele, çalışan numarasına göre sırala.

Doğru yaptıysan 7 satır gelir.

<details>
<summary>İpucu</summary>

Önce aklına gelen sorguyu yaz: yönetici olan herkesin numarası `yonetici_id` kolonunda, o listede olmayanları bulman gerekiyor. Sonuç 0 satır geliyorsa `yonetici_id` kolonunda ne olduğuna bir bak.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT c.calisan_id, c.ad, c.soyad
FROM calisanlar AS c
WHERE NOT EXISTS (
    SELECT 1
    FROM calisanlar AS alt
    WHERE alt.yonetici_id = c.calisan_id
)
ORDER BY c.calisan_id;
```

</details>

## Açıklama

Bu soruda akla gelen ilk çözüm şu:

```text
SELECT calisan_id, ad, soyad
FROM calisanlar
WHERE calisan_id NOT IN (SELECT yonetici_id FROM calisanlar);
```

Mantıklı görünüyor ama **0 satır** döndürüyor. Hata da vermiyor.

Sebebi, genel müdürün `yonetici_id`'sinin `NULL` olması. Alt sorgu yönetici numaralarının yanında bir de `NULL` döndürüyor. `NOT IN` aslında "listedeki her değerden farklı mı?" diye soruyor. Yani 6 numaralı çalışan için `6 <> 1 AND 6 <> 2 AND ... AND 6 <> NULL` kontrol ediliyor. `6 <> NULL` ifadesi `NULL` döndüğü için bütün ifade de `NULL` oluyor, `TRUE` olmuyor. `WHERE` bu satırı eliyor. Listede tek bir `NULL` olduğu için bu herkes için geçerli ve hiçbir satır gelmiyor.

Kendin görmek istersen `SELECT 6 NOT IN (1, 2, NULL);` çalıştır. `false` değil, `NULL` gelir.

`NOT EXISTS`'te bu sorun yok. O, "bu çalışanı yönetici olarak gösteren tek bir satır var mı?" diye soruyor. Cevap ya var ya yok, `NULL` işin içine girmiyor.

İlginç olan şu: `IN` bu tuzağa düşmüyor. `WHERE calisan_id IN (SELECT yonetici_id FROM calisanlar)` doğru şekilde 8 yöneticiyi getiriyor. `IN` "en az birine eşit mi?" diye sorduğu için bir eşleşme bulduğu an `TRUE` oluyor, `NULL` sonucu bozmuyor. Sorun sadece `NOT IN`'de.

## Alternatif çözüm

`NOT IN` kullanmakta ısrar ediyorsan, alt sorgudan `NULL`'ları elemen gerekiyor:

```sql
SELECT c.calisan_id, c.ad, c.soyad
FROM calisanlar AS c
WHERE c.calisan_id NOT IN (
    SELECT yonetici_id
    FROM calisanlar
    WHERE yonetici_id IS NOT NULL
)
ORDER BY c.calisan_id;
```

Doğru çalışıyor ama bu filtreyi her seferinde hatırlamak zorundasın. Kolon bugün `NULL` içermese bile yarın içerebilir. Bu yüzden ben alt sorguyla "olmayanları" ararken alışkanlık olarak `NOT EXISTS` kullanıyorum.

## Mülakatta

"`NOT IN` ile `NOT EXISTS` arasındaki fark ne?" sorusu sık gelir. Cevabın: alt sorgu `NULL` döndürebiliyorsa `NOT IN` hiç satır döndürmeyebilir, `NOT EXISTS` bundan etkilenmez. Bu örneği, yani genel müdürün `NULL` yöneticisi yüzünden sorgunun boş döndüğünü anlatabilirsen çok iyi bir cevap olur.

<!-- beklenen-satir: 7 -->
