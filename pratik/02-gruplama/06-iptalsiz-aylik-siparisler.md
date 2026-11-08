# İptaller hariç yoğun aylar

Zorluk: Orta · Konu: `WHERE` ile `HAVING` birlikte

## Soru

İptal edilen siparişleri hiç saymadan, bir ayda 80'den fazla siparişin geldiği ayları bul. Ayı (ayın ilk günü olarak) ve o aydaki sipariş sayısını göster. Sonuç aylara göre sıralı olsun.

Doğru yaptıysan 6 satır gelir.

<details>
<summary>İpucu</summary>

İki ayrı filtre var ve ikisi de farklı seviyede çalışıyor: biri tek tek satırlara, biri de gruplanmış sonuca uygulanıyor.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT date_trunc('month', siparis_tarihi)::date AS ay,
       COUNT(*)                                  AS siparis_sayisi
FROM siparisler
WHERE durum <> 'iptal'
GROUP BY ay
HAVING COUNT(*) > 80
ORDER BY ay;
```

</details>

## Açıklama

Burada iki filtreyi birlikte kullanıyoruz ve sırası önemli:

1. `WHERE durum <> 'iptal'` önce çalışır, iptal edilen siparişleri sayıma hiç sokmaz.
2. `GROUP BY ay` kalan siparişleri aylara böler.
3. `HAVING COUNT(*) > 80` gruplara bakar ve 80 ya da altında olan ayları eler.

Soruda "iptalleri sayma" dediği için bu bir satır filtresi, `WHERE`'e yazılır. "80'den fazla" ise grup hakkında bir koşul, `HAVING`'e yazılır. Bir koşulu nereye koyacağını anlamak için kendine şunu sor: "Bu koşul tek bir siparişe mi bakıyor, yoksa bir ayın toplamına mı?"

Sonucun neden önemli olduğunu görmek için `WHERE`'i silip çalıştır. İptaller de sayıldığında 8 ay çıkar, çünkü Mayıs ve Haziran'da iptallerle birlikte 83 ve 84 sipariş var ama iptaller çıkınca 75 ve 76'ya düşüyorlar. Temmuz ise çok kıl payı geçiyor, iptaller hariç 81 sipariş.

## Alternatif çözüm

PostgreSQL'de `FILTER` ile koşulu toplama fonksiyonunun içine yazabilirsin. `WHERE` kullanmıyorsun, filtre sadece o hesaba uygulanıyor:

```sql
SELECT date_trunc('month', siparis_tarihi)::date               AS ay,
       COUNT(*) FILTER (WHERE durum <> 'iptal')                AS siparis_sayisi
FROM siparisler
GROUP BY ay
HAVING COUNT(*) FILTER (WHERE durum <> 'iptal') > 80
ORDER BY ay;
```

Aynı sonucu veriyor. `FILTER`'ın işe yaradığı yer, aynı sorguda hem iptalli hem iptalsiz sayıyı yan yana göstermek istediğinde. O zaman `WHERE` kullanamazsın çünkü iki hesap da aynı satırlara bakıyor olurdu. `FILTER` standart SQL'de var ama her veritabanında yok.

## Sık yapılan hatalar

- `HAVING durum <> 'iptal' AND COUNT(*) > 80` yazmak. `durum` gruplanmış bir kolon değil, bu yüzden PostgreSQL `column "siparisler.durum" must appear in the GROUP BY clause or be used in an aggregate function` hatası verir. Satır filtreleri `WHERE`'e yazılır.
- `WHERE`'i unutup sadece `HAVING COUNT(*) > 80` yazmak. Hata vermez, 6 yerine 8 satır döner. İptal edilenler de sayıldığı için bazı aylar yanlışlıkla listeye girer.

## Mülakatta

"`WHERE` ile `HAVING` arasındaki fark ne?" soruyla sık karşılaşırsın. Kısa cevap: `WHERE` gruplamadan önce satırları süzer, `HAVING` gruplamadan sonra grupları süzer. Toplama fonksiyonu içeren koşullar yalnızca `HAVING`'de olabilir.

<!-- beklenen-satir: 6 -->
