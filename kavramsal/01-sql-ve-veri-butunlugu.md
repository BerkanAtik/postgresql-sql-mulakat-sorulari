# SQL ve veri bütünlüğü

Her soruda önce mülakatta söyleyeceğin kısa cevap, sonra ayrıntısı var. Örneklerin çoğu [örnek veritabanındaki](../db/README.md) tablolarla çalışıyor, istersen kendin de deneyebilirsin.

## 1. DDL, DML, DCL ve TCL nedir?

**Kısa cevap:** SQL komutlarını işlevine göre gruplamanın yolu. DDL yapıyı tanımlar (`CREATE`, `ALTER`, `DROP`), DML veriyi işler (`SELECT`, `INSERT`, `UPDATE`, `DELETE`), DCL yetki verir (`GRANT`, `REVOKE`), TCL transaction'ı yönetir (`BEGIN`, `COMMIT`, `ROLLBACK`).

| Grup | Açılımı | Örnek |
|---|---|---|
| DDL | Data Definition Language | `CREATE TABLE`, `ALTER TABLE`, `DROP TABLE`, `TRUNCATE` |
| DML | Data Manipulation Language | `INSERT`, `UPDATE`, `DELETE` |
| DQL | Data Query Language | `SELECT` |
| DCL | Data Control Language | `GRANT`, `REVOKE` |
| TCL | Transaction Control Language | `BEGIN`, `COMMIT`, `ROLLBACK`, `SAVEPOINT` |

Kaynaklara göre `SELECT` DML'in içinde de sayılıyor, ayrı bir DQL grubu olarak da. Mülakatta ikisini de bildiğini göstermek yeterli. `TRUNCATE`'in hangi gruba girdiği de tartışmalı, çoğu kaynak DDL der.

**PostgreSQL'e özel güzel bir ayrıntı:** DDL komutları da transaction içinde çalışıyor. `BEGIN; DROP TABLE odemeler; ROLLBACK;` yazarsan tablo yerinde kalıyor (denedim, 962 satır aynen duruyor). MySQL gibi bazı veritabanlarında DDL kendiliğinden commit eder, geri alamazsın.

## 2. Primary key ile unique arasındaki fark nedir?

**Kısa cevap:** İkisi de değerlerin tekrar etmemesini sağlıyor. Primary key ek olarak `NOT NULL` ve tabloda yalnızca bir tane olabilir. Unique kısıtından istediğin kadar koyabilirsin ve PostgreSQL'de `NULL` değerlere izin verir.

- Primary key = `UNIQUE` + `NOT NULL`, satırın kimliği. Tabloda en fazla bir tane.
- `UNIQUE`: ikincil benzersizlik kuralı (örneğin `musteriler.email`). Bir tabloda birden çok olabilir.
- İkisi de arkada otomatik bir unique index oluşturuyor.

`UNIQUE` kolonuna birden çok `NULL` girilebilir, çünkü `NULL` hiçbir değere eşit sayılmaz, kendisine bile. Denedim: `UNIQUE` bir kolona iki `NULL` ve bir `1` girdim, üçü de kabul edildi. Bu davranış veritabanından veritabanına değişiyor (SQL Server'da tek `NULL`'a izin verir).

**Devamında sorulabilir:** "Birden fazla kolondan oluşan primary key olur mu?" Evet, bileşik anahtar. Örnekte `siparis_kalemleri` tablosunda `(siparis_id, urun_id)` çifti `UNIQUE`, aynı ürün bir siparişe iki kez satır olarak girmiyor.

## 3. Foreign key ne işe yarar, `ON DELETE` seçenekleri nelerdir?

**Kısa cevap:** Bir tablodaki kolonun, başka bir tablodaki var olan bir değere işaret etmesini zorunlu kılar. Böylece olmayan bir müşteriye ait sipariş girilemez. `ON DELETE`, işaret edilen satır silinince ne olacağını belirler.

| Seçenek | Ana kayıt silinince |
|---|---|
| `NO ACTION` / `RESTRICT` (varsayılan) | Silme hata verir |
| `CASCADE` | Bağlı satırlar da silinir |
| `SET NULL` | Bağlı satırların foreign key kolonu `NULL` olur |
| `SET DEFAULT` | Kolon varsayılan değerine döner |

Örnek veritabanında 1 numaralı müşteriyi silmeyi denersen:

```text
ERROR:  update or delete on table "musteriler" violates foreign key constraint
"siparisler_musteri_id_fkey" on table "siparisler"
DETAIL:  Key (musteri_id)=(1) is still referenced from table "siparisler".
```

`CASCADE` ve `SET NULL`'u iki küçük tabloyla denedim: ana kayıt silinince `CASCADE`'li tabloda bağlı satırlar da gitti, `SET NULL`'lı tabloda satırlar kaldı ama kolonu `NULL` oldu.

**Dikkat:** PostgreSQL foreign key kolonlarına **otomatik index açmıyor**. `siparisler.musteri_id` gibi kolonlara kendin index koymazsan, o tabloya `JOIN` yapmak ya da ana kaydı silmek yavaş olabilir.

## 4. NULL nedir, neden dikkat gerektirir?

**Kısa cevap:** `NULL` "değer yok / bilinmiyor" demek, sıfır ya da boş metin değil. Bilinmeyen bir şeyle yapılan karşılaştırmanın sonucu da bilinmiyor, o yüzden `NULL = NULL` doğru değil, `NULL` döner. Kontrol için `IS NULL` kullanılır.

Denediğim bazı sonuçlar:

| İfade | Sonuç |
|---|---|
| `NULL = NULL` | `NULL` (doğru değil) |
| `NULL IS NULL` | `true` |
| `NULL <> 1` | `NULL` |
| `NULL AND false` | `false` |
| `NULL OR true` | `true` |

`WHERE` sadece koşulu **doğru** olan satırları getirir, `NULL` olanları da eler. Bu yüzden `WHERE sehir <> 'Ankara'` şehri boş olan müşterileri getirmez.

- Toplama fonksiyonları `NULL`'ı atlar: `AVG` değeri `10, 20, NULL` üzerinde 15 verir (20 değil).
- `COUNT(*)` bütün satırları sayar, `COUNT(kolon)` sadece `NULL` olmayanları. `musteriler` tablosunda `COUNT(*)` 200, `COUNT(sehir)` 192.
- `ORDER BY`'da `NULL`'lar büyük sayılır: artan sıralamada en sonda, azalanda en başta.
- En sinsi tuzak: `NOT IN` alt sorgusunda tek bir `NULL` varsa sonuç hiç satır döndürmez. Detayı [Modül 4'te](../pratik/04-alt-sorgu-ve-cte/README.md) var.

## 5. DELETE, TRUNCATE ve DROP arasındaki fark nedir?

**Kısa cevap:** `DELETE` satırları tek tek siler, `WHERE` ile seçebilirsin. `TRUNCATE` tablonun içini topluca boşaltır, yapı kalır. `DROP` tablonun kendisini siler.

| | `DELETE` | `TRUNCATE` | `DROP TABLE` |
|---|---|---|---|
| Ne siler | Seçtiğin satırlar | Bütün satırlar | Tablonun kendisi |
| `WHERE` | Var | Yok | Yok |
| Tablo yapısı | Kalır | Kalır | Gider |
| Satır başına trigger | Çalışır | Çalışmaz | Çalışmaz |
| Otomatik artan sayaç | Devam eder | Devam eder (`RESTART IDENTITY` ile sıfırlanır) | Tabloyla gider |
| Hız | Büyük tabloda yavaş | Çok hızlı | Çok hızlı |

PostgreSQL'de üçü de transaction içinde geri alınabilir. Denedim: `BEGIN; TRUNCATE siparis_kalemleri; ROLLBACK;` sonrası 2500 satır yerinde duruyor.

Üç ayrıntı:

- Sayaç: üç satır ekleyip `DELETE` ettikten sonra yeni satır `id = 4` aldı. `TRUNCATE`'ten sonra 5 aldı. `TRUNCATE ... RESTART IDENTITY` yazınca 1'e döndü.
- Foreign key: `TRUNCATE musteriler` hata verir (`cannot truncate a table referenced in a foreign key constraint`). Yanına `CASCADE` yazarsan bağlı tablolar da boşalır, dikkatli ol.
- Trigger: tabloda silinen satırları loglayan bir `AFTER DELETE` satır trigger'ı varsa, 3 satırı `DELETE` ile silince log tablosuna 3 kayıt düştü. Aynı 3 satırı `TRUNCATE` ile silince hiç kayıt düşmedi. Yani "silinenleri logla" gibi bir mantık `TRUNCATE` ile atlanıyor.

## 6. Hangi constraint (kısıt) türleri var?

**Kısa cevap:** `PRIMARY KEY`, `FOREIGN KEY`, `UNIQUE`, `NOT NULL`, `CHECK` ve `DEFAULT`. Veritabanı verinin kurallara uymasını uygulamadan bağımsız olarak kendisi zorluyor.

- `NOT NULL`: kolon boş olamaz.
- `CHECK`: bir koşul sağlanmalı. Örnek veritabanında `urunler.stok >= 0` ve `fiyat > 0`.
- `DEFAULT`: değer verilmezse kullanılacak değer.
- Kısıtlar, `INSERT`/`UPDATE` anında kontrol edilir, ihlalde ifade hata verir.

**Neden uygulamada kontrol etmek yetmez?** Uygulamada bir hata, ikinci bir uygulama ya da elle yapılan bir `UPDATE` kuralı atlayabilir. Veritabanındaki kısıt, verinin son savunması. Örneğin stok `-5`'e düşecek bir `UPDATE`, uygulama ne yaparsa yapsın `CHECK` tarafından durdurulur. [Modül 7'nin ilk sorusunda](../pratik/07-transaction/01-siparis-olusturma.md) bunun gerçek örneği var.
