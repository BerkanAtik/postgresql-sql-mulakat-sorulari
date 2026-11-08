# En az 10 sipariş veren müşteriler

Zorluk: Orta · Konu: `HAVING`

## Soru

Sadakat programı için, en az 10 sipariş vermiş müşterileri bulmak istiyoruz. Müşterinin `musteri_id`'sini ve sipariş sayısını listele. En çok siparişi olan müşteri en üstte olsun.

Doğru yaptıysan 12 satır gelir.

<details>
<summary>İpucu</summary>

Sipariş sayısı grup bittikten sonra ortaya çıkan bir değer. `WHERE` satırları gruplamadan önce süzer, gruplanmış sonucu süzmek için başka bir ifade var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT musteri_id, COUNT(*) AS siparis_sayisi
FROM siparisler
GROUP BY musteri_id
HAVING COUNT(*) >= 10
ORDER BY siparis_sayisi DESC, musteri_id;
```

</details>

## Açıklama

`WHERE` ve `HAVING` ikisi de filtre ama farklı zamanlarda çalışıyorlar. `WHERE` tek tek satırlara bakar ve gruplamadan önce çalışır. `HAVING` ise gruplar oluştuktan sonra, grupların kendisine bakar. "Sipariş sayısı" bir satırın değil, bir grubun özelliği, bu yüzden `HAVING` içinde yazılması gerekiyor.

Yani sorgunun gerçek çalışma sırası şöyle: önce `FROM`, sonra `WHERE`, sonra `GROUP BY`, sonra `HAVING`, sonra `SELECT`, en son `ORDER BY`.

`HAVING`'de takma ad kullanılamıyor. `HAVING siparis_sayisi >= 10` yazmak istersin ama `HAVING`, `SELECT`'ten önce çalıştığı için o takma ad henüz yok. Hesabı tekrar yazman gerekiyor: `HAVING COUNT(*) >= 10`. (MySQL buna izin veriyor, PostgreSQL vermiyor.)

## Sık yapılan hatalar

- `WHERE COUNT(*) >= 10` yazmak. PostgreSQL `aggregate functions are not allowed in WHERE` hatası verir, çünkü `WHERE` çalışırken henüz gruplar yok.
- `HAVING siparis_sayisi >= 10` yazmak. Bu da `column "siparis_sayisi" does not exist` hatası verir.
- "En az 10" yerine `> 10` yazmak. "En az 10", 10 ve üzeri demek. `> 10` yazarsan tam 10 sipariş veren müşteri kaybolur ve 12 yerine 11 satır gelir. Soruda "en az" ya da "en fazla" geçince eşitliği dahil edip etmediğini bir kere daha düşün.

<!-- beklenen-satir: 12 -->
