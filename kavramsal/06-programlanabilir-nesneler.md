# Programlanabilir nesneler

View, function, procedure, trigger ve geçici sonuç tutmanın yolları. Hepsini örnek veritabanında denedim.

## 28. View ile materialized view arasındaki fark nedir?

**Kısa cevap:** View, kayıtlı bir sorgudur. Her çağırıldığında sorgu yeniden çalışır, veri tutmaz. Materialized view ise sorgunun sonucunu tabloya benzer şekilde saklar, güncellenmesi için `REFRESH` gerekir.

```sql
CREATE VIEW v_sehir AS
SELECT sehir, COUNT(*) AS n FROM musteriler GROUP BY sehir;

CREATE MATERIALIZED VIEW mv_sehir AS
SELECT sehir, COUNT(*) AS n FROM musteriler GROUP BY sehir;
```

Sonra `musteriler`'e Bursa'dan yeni bir müşteri ekledim:

| | Bursa müşteri sayısı |
|---|---|
| View (`v_sehir`) | 17 (hemen güncel) |
| Materialized view (`mv_sehir`) | 16 (eski, saklı sonuç) |
| `REFRESH MATERIALIZED VIEW mv_sehir` sonrası | 17 |

Ne zaman hangisi?

- **View:** Karmaşık bir sorguyu adlandırıp tekrar tekrar yazmamak, kullanıcıya sadece belirli kolonları göstermek (yetki sınırlamak) için. Hız kazandırmaz, sorguyu sadece kısaltır.
- **Materialized view:** Çok ağır bir rapor sorgusunu her seferinde hesaplamamak için. Bedeli verinin bayatlayabilmesi ve `REFRESH` zamanlaması. Üzerine index de kurulabilir.

## 29. Function, procedure ve trigger arasındaki fark nedir?

**Kısa cevap:** Function bir değer (ya da tablo) döndürür ve sorgunun içinde çağrılır. Procedure `CALL` ile çağrılır ve transaction'ı kendisi yönetebilir. Trigger ise bir tabloda olay (insert/update/delete) olduğunda otomatik çalışan function'dır.

**Function:** `SELECT f_topla(2, 3)` gibi sorgu içinde kullanılır. İçinde `COMMIT` yazarsan hata verir:

```text
ERROR:  invalid transaction termination
CONTEXT:  PL/pgSQL function f_dene() line 1 at COMMIT
```

**Procedure:** `CALL p_dene()` ile çalışır ve içinde `COMMIT`/`ROLLBACK` yazılabilir. Denediğim procedure bir satırı ekleyip `COMMIT` etti, sonra ikinci satırı ekleyip `ROLLBACK` yaptı. Tabloda sadece ilk satır kaldı. Uzun toplu işleri parça parça commit etmek için işe yarıyor.

**Trigger:** Bir tablodaki olaya bağlanır. Fiyat değişince eski ve yeni fiyatı bir log tablosuna yazan bir `AFTER UPDATE` trigger'ı kurdum; iki ürünün fiyatını güncelleyince log tablosuna iki satır düştü.

```sql
CREATE TRIGGER t_fiyat
AFTER UPDATE OF fiyat ON urunler
FOR EACH ROW EXECUTE FUNCTION fiyat_logla();
```

Trigger'ların dikkat edilecek yönü: görünmezler. Uygulama koduna bakan biri `UPDATE`'in yan etkisi olduğunu fark etmeyebilir, hata ayıklamak zorlaşır. Ayrıca `TRUNCATE` satır trigger'larını çalıştırmaz (bu yüzden "silinenleri logla" mantığı `TRUNCATE` ile atlanır). Basit kurallar için `CHECK`/`DEFAULT` gibi kısıtları, yan etkili mantık için uygulama kodunu tercih etmek çoğu zaman daha okunur.

## 30. CTE, alt sorgu ve geçici tablo ne zaman hangisi?

**Kısa cevap:** CTE (`WITH`) ve alt sorgu aynı işi yapıyor, fark okunabilirlik. Aynı ara sonucu birden çok kez kullanacaksan ya da üzerinde index lazımsa geçici tablo (`CREATE TEMP TABLE`) işe yarıyor.

- **Alt sorgu:** Tek yerde kullanılacak kısa sorgular için. Çok iç içe girince okunmuyor.
- **CTE:** Sorguyu adımlara bölüp adlandırmak için. Özyinelemeli sorgu (`WITH RECURSIVE`, örneğin yönetici zinciri) yalnızca CTE ile yazılıyor ([Modül 4](../pratik/04-alt-sorgu-ve-cte/README.md)).
- **Geçici tablo:** Ara sonucu gerçekten saklar, oturum bitince silinir. Büyük bir ara sonucu birden çok sorguda kullanırken, ya da ona index koymak istediğinde.

Eski bir bilgi: PostgreSQL 12'den önce CTE her zaman ayrı bir adım olarak hesaplanıyordu ve bu yüzden bazen yavaş sayılırdı. Artık, bir kez kullanılan ve yan etkisi olmayan CTE sorguyla birleştiriliyor (inline). Denedim, PostgreSQL 17'de:

```sql
WITH c AS (SELECT * FROM urunler WHERE fiyat > 1000)
SELECT * FROM c WHERE kategori_id = 6;
-- plan: Seq Scan on urunler
--       Filter: (fiyat > 1000) AND (kategori_id = 6)
```

CTE planda hiç görünmüyor, iki filtre tek taramada birleşti. İstersen `WITH c AS MATERIALIZED (...)` yazarak eski davranışı zorlayabilirsin, o zaman planda ayrı bir `CTE Scan` çıkıyor. Bu, ara sonucun bir kez hesaplanıp birden çok yerde kullanılacağı ya da optimizasyonu bilerek engellemek istediğin durumlarda işe yarar.
