# Çalışanlar ve yöneticileri

Zorluk: Orta · Konu: self join, `LEFT JOIN`

## Soru

Şirketteki bütün çalışanları, yöneticilerinin adı ve soyadıyla birlikte listele. Yöneticisi olmayan genel müdür de listede olsun. Çalışan numarasına göre sırala.

Doğru yaptıysan 15 satır gelir.

<details>
<summary>İpucu</summary>

Yöneticiler de birer çalışan, yani aynı tabloda duruyorlar. `yonetici_id` kolonu, yöneticinin `calisan_id`'sini tutuyor. Aynı tabloyu sorguda iki kez, iki farklı takma adla kullanabilirsin.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT c.ad    AS calisan_ad,
       c.soyad AS calisan_soyad,
       y.ad    AS yonetici_ad,
       y.soyad AS yonetici_soyad
FROM calisanlar AS c
LEFT JOIN calisanlar AS y ON y.calisan_id = c.yonetici_id
ORDER BY c.calisan_id;
```

</details>

## Açıklama

Bir tabloyu kendisiyle birleştirmeye self join deniyor. Yeni bir şey yok, sadece aynı tabloya iki ayrı rol veriyoruz: `c` çalışanın kendisi, `y` onun yöneticisi. Takma adlar olmadan bunu yazmak mümkün değil, PostgreSQL hangi `calisanlar`'dan bahsettiğini anlayamaz.

`ON y.calisan_id = c.yonetici_id` şunu söylüyor: "çalışanın `yonetici_id`'si, yöneticinin `calisan_id`'sine eşit olsun". Bu yönü doğru kurmak önemli, ters yazınca bambaşka bir sonuç çıkıyor.

`LEFT JOIN` kullanmamızın sebebi genel müdür. Onun `yonetici_id`'si `NULL`, eşleşecek bir yönetici yok. `LEFT JOIN` onu tutar ve yönetici kolonlarını boş bırakır.

## Sık yapılan hatalar

- `LEFT JOIN` yerine `JOIN` yazmak. Genel müdür kaybolur, 15 yerine 14 satır gelir.
- `ON`'u ters kurmak. `ON y.yonetici_id = c.calisan_id` yazarsan sorgu çalışır ama anlamı "çalışanın yönettiği kişiler" olur. Her yönetici, ekibindeki kişi sayısı kadar tekrar eder ve 21 satır gelir.
- Ad ve soyadı birleştirip tek kolonda göstermek istersen dikkat: `y.ad || ' ' || y.soyad` genel müdür için `NULL` döner, çünkü `NULL` ile birleştirilen her metin `NULL` olur. Boş yerine bir şey yazsın istiyorsan `COALESCE(y.ad || ' ' || y.soyad, 'Yok')` kullanabilirsin.

<!-- beklenen-satir: 15 -->
