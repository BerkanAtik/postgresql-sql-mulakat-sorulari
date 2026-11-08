# Modül 7: Transaction

Birden fazla işlemi "ya hepsi olsun ya hiçbiri" diye tek pakete koymak, hata olunca geri almak ve aynı anda çalışan işlemlerin birbirini bozmasını önlemek. Mülakatlarda genelde "ACID nedir, isolation level'lar ne işe yarar" diye sorulur, ama işin asıl değeri bir sipariş ya da stok güncellemesinde veriyi bozmamayı bilmek.

Veritabanına nasıl bağlanacağını [ana sayfada](../../README.md), tabloların neler tuttuğunu da [örnek veritabanı sayfasında](../../db/README.md) bulabilirsin.

## Kısa konu özeti

`BEGIN` yazmazsan her ifade kendi başına küçük bir transaction sayılır ve çalışır çalışmaz kalıcı olur. `BEGIN` ile bir blok açarsan, içindekiler `COMMIT` diyene kadar sadece sana görünür, `ROLLBACK` dersen hepsi silinir.

| Komut | Ne yapar |
|---|---|
| `BEGIN` | Transaction'ı başlatır |
| `COMMIT` | Yapılan her şeyi kalıcı yapar |
| `ROLLBACK` | Transaction'daki her şeyi geri alır |
| `SAVEPOINT ad` | Transaction içinde bir kontrol noktası koyar |
| `ROLLBACK TO SAVEPOINT ad` | Sadece o noktadan sonrasını geri alır, transaction devam eder |
| `SELECT ... FOR UPDATE` | Okuduğun satırları, sen bitirene kadar başkası değiştirmesin diye kilitler |

Akılda tutman gerekenler:

- Transaction içinde bir ifade hata verirse **bütün transaction bozulur**. Sonraki ifadeler `current transaction is aborted` hatası verir, tek çıkış `ROLLBACK` (ya da önceden koyduysan `ROLLBACK TO SAVEPOINT`).
- PostgreSQL'de tablo oluşturma, silme gibi şema değişiklikleri de transaction'a dahil, `ROLLBACK` onları da geri alır. Her veritabanında böyle değil.
- `ROLLBACK` sequence'leri (otomatik artan numaraları) geri almaz. Geri alınan bir `INSERT` numarayı harcamış olur, ID'lerde boşluk kalabilir.
- ACID'in harfleri: **A**tomicity (ya hep ya hiç), **C**onsistency (kısıtlar bozulmaz), **I**solation (eşzamanlı işlemler birbirini bozmaz), **D**urability (COMMIT edilen veri kaybolmaz). Bu modülün ilk iki sorusu A'yı, son üçü I'yı gösteriyor.

## İki terminalle denemek

Son üç soru, aynı anda çalışan iki işlemi anlatıyor. Okurken yetinme, iki terminal aç, ikisinde de `psql` ile bağlan (Docker kullanıyorsan iki ayrı pencerede `docker compose exec db psql -U ogrenci -d eticaret`). Sorulardaki adımları sırayla bir pencerede bir diğerinde yazarak kendi gözünle gör.

Açıklamalardaki sonuçları iki oturum açıp birkaç saniye arayla çalıştırarak **benim makinemde** aldım. Aynı sonuç, sırayı doğru tutarsan sende de çıkar.

## Sorular

| # | Soru | Zorluk | Konu |
|---|---|---|---|
| 1 | [Sipariş oluşturmak: ya hep ya hiç](01-siparis-olusturma.md) | Kolay | `BEGIN`, `COMMIT`, atomicity |
| 2 | [Güncellemeyi önce dene, sonra karar ver](02-guncellemeyi-once-dene.md) | Kolay | `ROLLBACK`, `RETURNING` |
| 3 | [Bir kısmını geri almak](03-savepoint.md) | Orta | `SAVEPOINT` |
| 4 | [Aynı anda stok düşmek](04-ayni-anda-stok-dusmek.md) | Orta | kayıp güncelleme, `FOR UPDATE` |
| 5 | [Rapor sırasında veri değişirse](05-isolation-level.md) | Orta | isolation level |
| 6 | [Birbirini bekleyen iki işlem](06-deadlock.md) | Zor | deadlock, kilit sırası |
