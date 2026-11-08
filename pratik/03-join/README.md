# Modül 3: JOIN

Gerçek veritabanlarında bilgi tek tabloda durmaz. Müşteri bir tabloda, sipariş başka bir tabloda, ürün bir başkasında. `JOIN` bunları birleştirmenin yolu ve SQL mülakatlarının en çok sorulan konusu. Bu modülde en çok zaman ayırman gereken yer burası.

Tabloların birbirine nasıl bağlandığını görmek için [örnek veritabanı sayfasındaki](../../db/README.md) diyagrama bak, soruları çözerken açık tutmak işine yarar.

## Kısa konu özeti

| Tür | Ne getirir |
|---|---|
| `JOIN` (`INNER JOIN`) | Sadece iki tarafta da eşi olan satırlar |
| `LEFT JOIN` | Soldaki tablonun bütün satırları. Eşi yoksa sağdaki kolonlar `NULL` |
| `RIGHT JOIN` | Sağdaki tablonun bütün satırları. Pratikte pek kullanılmaz, tabloların yerini değiştirip `LEFT JOIN` yazılır |
| `FULL JOIN` | İki tablonun da bütün satırları. Eşi olmayan taraf `NULL` |
| `CROSS JOIN` | Her satırı her satırla eşleştirir (kartezyen çarpım) |
| Self join | Ayrı bir tür değil, bir tabloyu farklı takma adla kendisiyle birleştirmek |

Akılda tutman gereken birkaç şey:

- Birden fazla tabloyla çalışırken her kolonun başına tablosunun takma adını yaz (`m.ad`, `s.siparis_id`).
- Eşi olmayan satırları da görmek istiyorsan `LEFT JOIN`. Eşi olmayanları bulmak istiyorsan `LEFT JOIN` + `IS NULL` ya da `NOT EXISTS`.
- `LEFT JOIN`'de sağdaki tablonun koşulları `ON`'a yazılır. `WHERE`'e yazarsan `LEFT JOIN`'in anlamı kaybolur. Tek istisna eşi olmayanları ararken yazılan `IS NULL` kontrolü, o `WHERE`'de kalır (3. soru).
- Bir kayda "birden çok" bağlı iki tabloyu aynı anda birleştirip toplarsan sayılar çarpılır. Önce topla, sonra birleştir.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Aralık siparişleri ve müşteri adları](01-aralik-siparisleri-ve-musteriler.md) | Kolay | `INNER JOIN` |
| 2 | [Antalya'daki müşterilerin aldığı ürünler](02-antalyadaki-musterilerin-urunleri.md) | Kolay | çok tablolu `JOIN` |
| 3 | [Hiç sipariş vermemiş müşteriler](03-hic-siparis-vermeyen-musteriler.md) | Orta | `LEFT JOIN`, anti join |
| 4 | [Müşteri başına sipariş sayısı](04-musteri-basina-siparis-sayisi.md) | Orta | `LEFT JOIN` ile `COUNT` |
| 5 | [Aralık ayı müşteri raporu](05-aralikta-musteri-basina-siparis.md) | Zor | `ON` mu `WHERE` mi |
| 6 | [Çalışanlar ve yöneticileri](06-calisanlar-ve-yoneticileri.md) | Orta | self join |
| 7 | [Yöneticisinden fazla kazanan çalışanlar](07-yoneticisinden-fazla-kazananlar.md) | Orta | self join |
| 8 | [Ana kategorilere göre ciro](08-ana-kategoriye-gore-ciro.md) | Zor | çok tablolu `JOIN` |
| 9 | [Bölünmüş ödemeler ve çoğalan toplamlar](09-join-ile-cogalan-toplamlar.md) | Zor | fan-out |

3, 4 ve 5. sorular birbirinin üstüne kuruluyor, sırayla çözmen iyi olur. 5. ve 9. sorular bu modülün en önemli iki tuzağı.
