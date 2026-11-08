# Müşterilerin yaşadığı şehirler

Zorluk: Kolay · Konu: `DISTINCT`, `IS NOT NULL`, `ORDER BY`

## Soru

Müşterilerin yaşadığı şehirleri, her şehir bir kez geçecek şekilde alfabetik sırayla listele. Şehri girilmemiş müşteriler listeye boş bir satır olarak girmesin.

Doğru yaptıysan 8 satır gelir.

<details>
<summary>İpucu</summary>

200 müşterinin şehirleri tekrar tekrar geçiyor. Tekrarları temizleyen bir anahtar kelime var. Boş olanları ise ayrıca elemen gerekecek.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT DISTINCT sehir
FROM musteriler
WHERE sehir IS NOT NULL
ORDER BY sehir;
```

</details>

## Açıklama

`DISTINCT` sonuçtaki aynı satırları teke indirir. Tek kolon seçtiğin için burada "benzersiz şehirler" demek oluyor.

Takılabileceğin yer `NULL`. `DISTINCT` bütün `NULL`'ları birbirine eşit sayar, yani şehri boş olan 8 müşteri tek bir boş satıra iner. `WHERE sehir IS NOT NULL` satırını silersen 9 satır gelir ve biri boş görünür.

Sorgu yazdığın sırayla çalışmıyor. Önce `WHERE` boş şehirleri eliyor, sonra `DISTINCT` tekrarları temizliyor, `ORDER BY` en son sıralıyor.

## Alternatif çözüm

`GROUP BY` ile de aynı sonucu alırsın:

```sql
SELECT sehir
FROM musteriler
WHERE sehir IS NOT NULL
GROUP BY sehir
ORDER BY sehir;
```

## Sık yapılan hatalar

`SELECT DISTINCT(sehir), ad FROM musteriler` yazınca `DISTINCT` sadece `sehir`'e uygulanıyor sanılıyor ama öyle değil. Parantez bir şey değiştirmez, `DISTINCT` seçilen bütün kolonların birleşimine bakar. Yani `sehir` ile `ad` ikilisinin benzersiz olanları gelir ve 8 yerine 64 satır döner.

## Mülakatta

"`DISTINCT` ile `GROUP BY` arasındaki fark ne?" sorusu sık sorulur. Sadece tekrar temizliyorsan sonuç aynı. `GROUP BY`'ı asıl `COUNT`, `SUM` gibi toplama fonksiyonlarıyla kullanırsın. `DISTINCT` ise "sadece tekrarları temizliyorum" niyetini daha açık gösterir. PostgreSQL çoğu durumda ikisi için benzer plan çıkarır, performans farkı beklemene gerek yok.

<!-- beklenen-satir: 8 -->
