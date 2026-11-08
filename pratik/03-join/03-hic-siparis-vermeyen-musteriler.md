# Hiç sipariş vermemiş müşteriler

Zorluk: Orta · Konu: `LEFT JOIN`, `IS NULL`, `NOT EXISTS`

## Soru

Kayıt olup hiç sipariş vermemiş müşterilere hoş geldin indirimi gönderilecek. Bu müşterilerin `musteri_id`, `ad`, `soyad` ve `email` bilgisini listele. Müşteri numarasına göre sırala.

Doğru yaptıysan 20 satır gelir.

<details>
<summary>İpucu</summary>

`INNER JOIN` sadece iki tarafta da eşi olan satırları getiriyor, yani sipariş vermemiş bir müşteri sonuçta hiç görünmez. Eşi olmayan satırları da tutan bir `JOIN` türü var. Eşleşmeyen satırlarda öbür tablonun kolonları ne olur, onu düşün.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT m.musteri_id, m.ad, m.soyad, m.email
FROM musteriler AS m
LEFT JOIN siparisler AS s ON s.musteri_id = m.musteri_id
WHERE s.musteri_id IS NULL
ORDER BY m.musteri_id;
```

</details>

## Açıklama

`LEFT JOIN`, soldaki tablonun (burada `musteriler`) bütün satırlarını tutar. Sağda eşi olan satırlar normal şekilde eşleşir. Eşi olmayan bir müşteri de sonuca girer ama `siparisler` tablosundan gelmesi gereken bütün kolonlar `NULL` olur.

`WHERE s.musteri_id IS NULL` tam bu satırları seçiyor: "sipariş tarafı boş kalan müşteriler". Bu kalıba anti join deniyor: bir tabloda olup öbüründe olmayan kayıtları bulmak.

Neden özellikle `s.musteri_id`'ye bakıyoruz? Eşleşen her satırda bu kolon dolu olmak zorunda, çünkü eşleştirme zaten bu kolonla yapılıyor ve `NULL` hiçbir değere eşit olmaz. Yani bu kolonda `NULL` görüyorsan tek açıklaması eşleşmenin olmaması. Primary key olan `s.siparis_id`'ye bakmak da aynı garantiyi verir ve aynı 20 satırı getirir. Ama `NULL` olabilen bir kolona bakarsan yanlış sonuç alırsın, aşağıdaki hatalara bak.

## Alternatif çözüm

Aynı soruyu `NOT EXISTS` ile de yazabilirsin. Okuması "siparişi olmayan müşteriler" cümlesine daha yakın:

```sql
SELECT m.musteri_id, m.ad, m.soyad, m.email
FROM musteriler AS m
WHERE NOT EXISTS (
    SELECT 1
    FROM siparisler AS s
    WHERE s.musteri_id = m.musteri_id
)
ORDER BY m.musteri_id;
```

`NOT EXISTS`, alt sorgu tek bir satır bile bulursa o müşteriyi eler. Alt sorgunun ne döndürdüğü önemli değil, `SELECT 1` yazmak alışkanlık. Alt sorgulara bir sonraki modülde daha ayrıntılı bakacağız.

## Sık yapılan hatalar

- `LEFT JOIN` yerine `JOIN` yazmak. Sipariş vermemiş müşteriler daha `JOIN` aşamasında elendiği için `WHERE s.musteri_id IS NULL` hiçbir satır bulamaz, 0 satır döner.
- `NULL` olabilen bir kolona bakmak. Örneğin `WHERE s.kupon_kodu IS NULL` yazarsan, sipariş vermemiş 20 müşterinin yanında kupon kullanmadan verilmiş bütün siparişler de gelir ve 779 satır görürsün. Eşleşmeyi her zaman eşleşen satırda `NULL` olamayacak bir kolonla kontrol et: `JOIN` koşulundaki kolon ya da primary key.

## Mülakatta

"Bir tabloda olup diğerinde olmayan kayıtları nasıl bulursun?" sorusu çok sık gelir. İki yolu da bildiğini göstermek iyi olur: `LEFT JOIN ... IS NULL` ve `NOT EXISTS`.

Performans sorulursa şunu bilmekte fayda var: PostgreSQL `NOT EXISTS`'i doğrudan anti join olarak çalıştırır. `LEFT JOIN ... IS NULL`'ı da anti join'e çevirebiliyor ama bunun için `IS NULL` kontrolünü `JOIN` koşulundaki kolonda yapman gerekiyor. Bizim çözümdeki `s.musteri_id IS NULL` anti join olarak çalışıyor. Aynı sorguyu `s.siparis_id IS NULL` ile yazarsan sonuç değişmiyor ama PostgreSQL 17 önce normal bir join yapıp sonra `NULL`'ları süzüyor. Bunu sorgunun başına `EXPLAIN` yazarak kendin görebilirsin. Bu tür ayrıntılar sürümden sürüme değişebildiği için emin olmak istediğinde planı kontrol etmek en doğrusu, `EXPLAIN` okumayı index modülünde göreceğiz.

Üçüncü yol olan `NOT IN`'den bahsedersen, listede `NULL` varsa hiç satır döndürmeyebileceğini de eklemeyi unutma.

<!-- beklenen-satir: 20 -->
