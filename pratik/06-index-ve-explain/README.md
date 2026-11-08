# Modül 6: Index ve EXPLAIN

Bir sorgunun neden yavaş olduğunu görmek ve index ile düzeltmek. "Bu sorgu yavaş, ne yapardın?" mülakatlarda neredeyse her zaman sorulur ve cevabı `EXPLAIN` okumaktan geçer.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Önce tabloyu hazırla

Index'in etkisini görmek için 1000 satır yetmiyor, bu modülde 500.000 satırlık ayrı bir `ziyaretler` tablosu kullanıyoruz (sitedeki sayfa ziyaretleri). Önce şunu çalıştır:

```bash
# Docker kullanıyorsan
docker compose exec -T db psql -U ogrenci -d eticaret < pratik/06-index-ve-explain/hazirlik.sql

# Kendi PostgreSQL'inde
psql -d eticaret -f pratik/06-index-ve-explain/hazirlik.sql
```

Tabloyu silip baştan kuruyor, birkaç saniye sürer. Sorular index oluşturuyor, bu yüzden bir soruya başlarken bunu tekrar çalıştırırsan önceki sorudan kalan index'ler temizlenir.

| Kolon | Ne tutuyor |
|---|---|
| `ziyaret_id` | Birincil anahtar |
| `musteri_id` | Giriş yapan müşteri. Ziyaretlerin %20'sinde `NULL`, 160 farklı müşteri var |
| `sayfa` | `anasayfa` (%40), `urun` (%30), `sepet`, `odeme`, `arama` (%10'ar) |
| `ziyaret_zamani` | 2024 boyunca yaklaşık 63 saniyede bir ziyaret |
| `sure_saniye` | Sayfada kalınan süre |

## Kısa konu özeti

Index olmayınca PostgreSQL aradığını bulmak için bütün tabloyu baştan sona okuyor (**Seq Scan**). Index, kolonun sıralı bir kopyası gibi düşünülebilir: aradığın değere doğrudan gidiyor. En yaygın tür B-tree ve `CREATE INDEX` ile başka bir şey söylemezsen o oluşuyor.

Planı görmek için sorgunun başına `EXPLAIN` yazılır:

| Komut | Ne yapar |
|---|---|
| `EXPLAIN` | Sorguyu çalıştırmaz, planlayıcının tahminini gösterir |
| `EXPLAIN ANALYZE` | Sorguyu **gerçekten çalıştırır**, gerçek süreyi ve satır sayısını da yazar |

`INSERT`, `UPDATE`, `DELETE` için `EXPLAIN ANALYZE` yazarsan değişiklik gerçekten yapılır. Denemek istiyorsan `BEGIN; ... ROLLBACK;` içine al.

Plandaki başlıca okuma yöntemleri:

| Plan adımı | Anlamı |
|---|---|
| `Seq Scan` | Bütün tabloyu oku, her satıra filtre uygula |
| `Index Scan` | Index'te bul, satırı tabloda tek tek oku. Az satır için |
| `Bitmap Index Scan` + `Bitmap Heap Scan` | Önce index'ten hangi sayfalarda olduğunu topla, sonra o sayfaları sırayla oku. Orta miktarda satır için |
| `Parallel Seq Scan` | Seq Scan'in birkaç işçiyle paylaşılmış hâli |

Planı okurken bakacağın yerler: adımın adı, `Index Cond` ya da `Filter` satırı, `Rows Removed by Filter` (atılan satır sayısı) ve en altta `Execution Time`.

Süreleri **benim makinemde** ölçtüm. Seninkinde farklı çıkar, önemli olan oranlar ve plandaki adım adları. İlk çalıştırma biraz yavaş çıkabilir, birkaç kez çalıştırıp bak.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Index yokken ve varken](01-index-yokken-ve-varken.md) | Kolay | `CREATE INDEX`, Seq Scan, `EXPLAIN ANALYZE` |
| 2 | [Tarih kolonuna fonksiyon uygulamak](02-tarih-kolonuna-fonksiyon.md) | Orta | index'i bozan filtre, expression index |
| 3 | [Birleşik index ve kolon sırası](03-birlesik-index-kolon-sirasi.md) | Orta | çok kolonlu index |
| 4 | [Index var ama kullanılmıyor](04-index-var-ama-kullanilmiyor.md) | Zor | `LIKE` ve `text_pattern_ops`, index'in işe yaramadığı durumlar |

2. soru, mülakatta "index var ama sorgu yine yavaş, neden?" diye sorulan sorunun en tipik cevabı.
