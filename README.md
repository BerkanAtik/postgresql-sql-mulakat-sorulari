# SQL ve PostgreSQL Mülakat Soruları

Junior ve stajyer mülakatlarında sık karşına çıkan SQL sorularını, kendi bilgisayarında çalıştırabileceğin hazır bir PostgreSQL veritabanıyla birlikte topluyorum. Sorular, çözümler ve açıklamalar Türkçe.

Soruyu okuyorsun, sorguyu kendin yazıp gerçek bir veritabanında çalıştırıyorsun, sonra çözümle karşılaştırıyorsun. Çözümlerin hepsi PostgreSQL 17'de çalıştırılıp doğrulanıyor.

> **Durum:** Örnek veritabanı, 7 pratik modül (51 soru) ve 30 kavramsal soru hazır. Repo yayına hazırlanıyor, küçük düzeltmeler gelmeye devam edecek.

## Kimler için

- SQL'i yeni öğrenen ya da dersinde görüp pratik yapmak isteyen üniversite öğrencileri
- Staj ve junior backend/veri mülakatlarına hazırlananlar
- `JOIN`, `GROUP BY`, window function gibi konularda elini hızlandırmak isteyenler

## Başlamak için

Bilgisayarında [Docker](https://www.docker.com/products/docker-desktop/) kurulu olması yeterli.

```bash
git clone <bu-reponun-adresi>
cd <klasör-adı>
docker compose up -d
```

İlk açılışta örnek veritabanı otomatik yüklenir, bir iki dakika sürebilir. Hazır olup olmadığını şöyle kontrol edebilirsin:

```bash
docker compose ps
```

`healthy` yazıyorsa bağlanabilirsin.

## Veritabanına bağlanmak

| | |
|---|---|
| Sunucu | `localhost` |
| Port | `5433` |
| Veritabanı | `eticaret` |
| Kullanıcı | `ogrenci` |
| Şifre | `sifre` |

Port 5432 değil 5433, çünkü bilgisayarında zaten PostgreSQL kuruluysa 5432 dolu olabiliyor.

Terminalden hemen denemek istersen:

```bash
docker compose exec db psql -U ogrenci -d eticaret
```

Daha rahat çalışmak için [DBeaver](https://dbeaver.io/), pgAdmin ya da VS Code'daki PostgreSQL eklentilerinden biriyle yukarıdaki bilgilerle bağlanabilirsin.

Docker kullanmak istemiyorsan kendi PostgreSQL'inde `eticaret` adında bir veritabanı açıp şunu çalıştır:

```bash
psql -d eticaret -f db/01_sema.sql -f db/02_veri.sql
```

## Nasıl çalışmanı öneririm

1. Önce modülün kısa konu özetini oku.
2. Soruyu oku, çözümü açmadan kendi sorgunu yaz ve çalıştır.
3. Takılırsan ipucuna bak. Hâlâ olmuyorsa çözümü aç.
4. Çözümü açtıktan sonra açıklamayı mutlaka oku. Mülakatta sorgunun doğru olması kadar neden öyle yazdığını anlatabilmen de önemli.

Sadece çözümü okuyup geçmek pek işe yaramıyor, elin yazmayınca mülakatta takılıyorsun.

## İçerik

| Modül | Konular | Durum |
|---|---|---|
| [01 Temel sorgular](pratik/01-temel-sorgular/README.md) | `WHERE`, `IN`, `ORDER BY`, `LIMIT`, `DISTINCT`, `NULL`, tarih aralığı | 6 soru hazır |
| [02 Gruplama](pratik/02-gruplama/README.md) | `COUNT`, `SUM`, `AVG`, `GROUP BY`, `HAVING`, `COUNT(DISTINCT)` | 6 soru hazır |
| [03 JOIN](pratik/03-join/README.md) | `INNER`, `LEFT`, self join, hiç eşleşmeyen kayıtlar, çoğalan toplamlar | 9 soru hazır |
| [04 Alt sorgu ve CTE](pratik/04-alt-sorgu-ve-cte/README.md) | `IN`, `EXISTS`, correlated subquery, `WITH`, `WITH RECURSIVE` | 7 soru hazır |
| [05 Window functions](pratik/05-window-functions/README.md) | `ROW_NUMBER`, `RANK`, `DENSE_RANK`, `LAG`, kümülatif toplam | 7 soru hazır |
| [06 Index ve EXPLAIN](pratik/06-index-ve-explain/README.md) | `EXPLAIN ANALYZE` okumak, birleşik index, expression index, index'in işe yaramadığı durumlar | 4 soru hazır |
| [07 Transaction](pratik/07-transaction/README.md) | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT`, kayıp güncelleme, isolation level, deadlock | 6 soru hazır |
| [Kavramsal sorular](kavramsal/README.md) | ACID, normalizasyon, index, `JOIN` farkları, `DELETE`/`TRUNCATE`/`DROP`, MVCC, view | 30 soru hazır |

## Örnek veritabanı

Bütün sorular aynı e-ticaret veritabanı üzerinde: müşteriler, siparişler, ürünler, ödemeler ve bir de çalışanlar tablosu. Şema, tablolar arası ilişkiler ve verideki ayrıntılar [db/README.md](db/README.md) dosyasında.

## Klasörler

```
db/        örnek veritabanının şeması ve verisi
pratik/    SQL yazarak çözdüğün sorular (modül modül)
kavramsal/ sözlü anlatman gereken mülakat soruları
scripts/   çözümleri otomatik doğrulayan betik
```

## Çözümleri doğrulamak

Soru dosyalarındaki çözümlerin gerçekten çalıştığını kontrol eden bir betik var. Veritabanı ayaktayken:

```bash
bash scripts/validate.sh
```

Hem örnek verinin bozulmadığını hem de her çözümün hatasız çalıştığını kontrol eder. Bir soruda yanlış bir şey bulursan ya da kendi sorunu eklemek istersen issue açabilirsin.
