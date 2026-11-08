# Departmanda en düşük maaşı alanlar

Zorluk: Orta · Konu: eşitlik varken grup başına ilk kayıt, `RANK`

## Soru

Her departmanda en düşük maaşı alan çalışanı bul. Bir departmanda en düşük maaşı alan birden fazla kişi varsa hepsi listede olsun. Departman, ad, soyad ve maaşı göster. Departmana, aynı departmandakiler de ada göre sırala.

Doğru yaptıysan 6 satır gelir. 5 departman var ama birinde en düşük maaşı alan iki kişi var.

<details>
<summary>İpucu</summary>

Bir önceki sorudaki kalıbın aynısı, ama "eşitlik varsa hepsi" şartı var. Hangi sıralama fonksiyonu eşitlere aynı numarayı veriyordu?

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
WITH sirali AS (
    SELECT departman, ad, soyad, maas,
           RANK() OVER (PARTITION BY departman ORDER BY maas) AS sira
    FROM calisanlar
)
SELECT departman, ad, soyad, maas
FROM sirali
WHERE sira = 1
ORDER BY departman, ad;
```

</details>

## Açıklama

Satış departmanında Aslı ve Gökhan aynı maaşı alıyor (24.000 TL) ve ikisi de departmanın en düşük maaşı. `RANK` eşit maaşlara aynı sırayı verdiği için ikisi de 1 oluyor ve ikisi de sonuca giriyor.

Bir önceki soruda `ROW_NUMBER` kullanmıştık ve sorun olmamıştı, çünkü kategorilerde aynı fiyatlı iki ürün yoktu. Burada ise `ROW_NUMBER` eşit maaşlılardan sadece birini seçerdi. Grup başına ilk kayıt sorularında hangisini kullanacağın, sorunun eşitlik hakkında ne istediğine bağlı:

- "Her departmandan **bir** kişi" deniyorsa: `ROW_NUMBER`, eşitlikte kimin seçileceği için `ORDER BY`'a ikinci bir kolon ekle.
- "Eşitse **hepsi**" deniyorsa: `RANK` ya da `DENSE_RANK`. `= 1` için ikisi aynı sonucu verir.

Yönetim departmanında sadece genel müdür var. Tek kişi olduğu için hem en yüksek hem en düşük maaş onun ve o da listede.

## Alternatif çözüm

Window function olmadan, correlated subquery ile de yapılabilir:

```sql
SELECT c.departman, c.ad, c.soyad, c.maas
FROM calisanlar AS c
WHERE c.maas = (
    SELECT MIN(c2.maas)
    FROM calisanlar AS c2
    WHERE c2.departman = c.departman
)
ORDER BY c.departman, c.ad;
```

Bu da eşitleri otomatik olarak getiriyor, çünkü en düşük maaşa eşit olan herkes koşulu sağlıyor.

## Sık yapılan hatalar

`RANK` yerine `ROW_NUMBER` kullanmak. Hata vermez ama Satış'tan sadece bir kişi gelir, 6 yerine 5 satır görürsün. Hangisinin geleceği de belli değil, Aslı da olabilir Gökhan da. Soruda "eşitse hepsi" gibi bir şart yoksa bile mülakatta "eşitlik olursa ne yapayım?" diye sormak iyi bir alışkanlık.

<!-- beklenen-satir: 6 -->
