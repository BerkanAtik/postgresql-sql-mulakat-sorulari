# Modül 2: Gruplama

Satırları gruplayıp her grup için bir sonuç hesaplamak. "Kaç tane?", "toplam ne kadar?", "ortalama ne?" gibi sorular hep buraya çıkar. Mülakatlarda `WHERE` ile `HAVING` farkı neredeyse her zaman sorulur.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Kısa konu özeti

Toplama (aggregate) fonksiyonları birden fazla satırı tek bir değere indirir:

| Fonksiyon | Ne yapar |
|---|---|
| `COUNT(*)` | Satır sayısı |
| `COUNT(kolon)` | O kolonu boş olmayan satırların sayısı |
| `COUNT(DISTINCT kolon)` | O kolondaki farklı değerlerin sayısı |
| `SUM(kolon)` | Toplam |
| `AVG(kolon)` | Ortalama |
| `MIN(kolon)`, `MAX(kolon)` | En küçük, en büyük |

`COUNT(*)` hariç hepsi `NULL` değerleri yok sayar.

`GROUP BY` yoksa bu fonksiyonlar bütün tabloyu tek bir grup sayar ve tek satır döndürür. `GROUP BY` ile satırları gruplara bölersin, fonksiyon her grup için ayrı çalışır.

Bir sorgu şu sırayla çalışır. Yazdığın sıra bundan farklı:

```
FROM -> WHERE -> GROUP BY -> HAVING -> SELECT -> ORDER BY -> LIMIT
```

`WHERE` gruplamadan önce satırları süzer, `HAVING` gruplamadan sonra grupları süzer. Kurala dikkat: `SELECT`'e yazdığın her kolon ya `GROUP BY`'da olmalı ya da bir toplama fonksiyonunun içinde olmalı.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Duruma göre sipariş sayısı](01-duruma-gore-siparis-sayisi.md) | Kolay | `COUNT`, `GROUP BY` |
| 2 | [Şehre göre müşteri sayısı](02-sehre-gore-musteri-sayisi.md) | Kolay | `NULL` grubu, `COALESCE` |
| 3 | [Ödeme yöntemine göre özet](03-odeme-yontemine-gore-ozet.md) | Kolay | `SUM`, `AVG`, `ROUND` |
| 4 | [Aylık sipariş sayısı ve farklı müşteri sayısı](04-aylik-siparis-ve-musteri-sayisi.md) | Orta | `COUNT(DISTINCT)` |
| 5 | [En az 10 sipariş veren müşteriler](05-en-az-10-siparis-veren-musteriler.md) | Orta | `HAVING` |
| 6 | [İptaller hariç yoğun aylar](06-iptalsiz-aylik-siparisler.md) | Orta | `WHERE` ve `HAVING` birlikte |

Sırayla çözmeni öneririm. 6. soru, 5. sorudaki `HAVING` mantığının üstüne kuruluyor.
