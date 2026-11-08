# Modül 5: Window functions

Satırları kaybetmeden grupla ilgili hesap yapmak: sıralama, grup içi ortalama, kümülatif toplam, bir önceki satırla karşılaştırma. Junior mülakatlarında giderek daha sık soruluyor, veri analisti mülakatlarında ise neredeyse her zaman karşına çıkar.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Kısa konu özeti

Window function'lar `GROUP BY` gibi grup üzerinde hesap yapıyor ama satırları birleştirmiyor. Her satır yerinde kalıyor ve yanına grubuyla ilgili bir değer ekleniyor.

```sql
fonksiyon() OVER (
    PARTITION BY ...   -- hangi gruplar (yazmazsan bütün tablo tek grup)
    ORDER BY ...       -- grup içinde hangi sıra
)
```

| Fonksiyon | Ne yapar |
|---|---|
| `ROW_NUMBER()` | 1, 2, 3... Eşitlere de farklı numara verir |
| `RANK()` | Eşitlere aynı sıra, sonra atlar (1, 2, 2, 4) |
| `DENSE_RANK()` | Eşitlere aynı sıra, atlamaz (1, 2, 2, 3) |
| `LAG(kolon)` / `LEAD(kolon)` | Önceki / sonraki satırın değeri |
| `SUM`, `AVG`, `COUNT`, `MIN`, `MAX` | Bildiğin toplama fonksiyonları, `OVER` ile window olarak |

Akılda tutman gerekenler:

- Window function'lar `SELECT` aşamasında hesaplanıyor. Bu yüzden `WHERE` içinde kullanamazsın. Sonucu süzmek için CTE ya da alt sorgu kullan.
- `OVER` içinde `ORDER BY` varsa toplama fonksiyonları "baştan bu satıra kadar" hesaplanıyor (kümülatif). Yoksa bütün grup üzerinden.
- "Her gruptan ilk N tane" kalıbı: CTE'de `ROW_NUMBER() OVER (PARTITION BY ... ORDER BY ...)`, dışarıda `WHERE sira <= N`.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Kategori içinde fiyat sırası](01-kategori-icinde-fiyat-sirasi.md) | Kolay | `ROW_NUMBER`, `PARTITION BY` |
| 2 | [Ürün fiyatı ve kategori ortalaması](02-urun-ve-kategori-ortalamasi.md) | Kolay | `AVG() OVER` |
| 3 | [ROW_NUMBER, RANK ve DENSE_RANK farkı](03-row-number-rank-dense-rank.md) | Orta | sıralama fonksiyonları |
| 4 | [Her kategorinin en pahalı ürünü](04-her-kategorinin-en-pahali-urunu.md) | Orta | grup başına ilk kayıt |
| 5 | [Departmanda en düşük maaşı alanlar](05-departmanda-en-dusuk-maas.md) | Orta | eşitlik ve `RANK` |
| 6 | [Aylık ve kümülatif ciro](06-kumulatif-ciro.md) | Orta | kümülatif toplam |
| 7 | [Bir önceki aya göre değişim](07-aylik-degisim.md) | Orta | `LAG` |

3. soru mülakatta en çok sorulan konu, 4. soru da en çok kullanılan kalıp. İkisini iyice oturtmanı öneririm.
