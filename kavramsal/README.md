# Kavramsal sorular

Mülakatta SQL yazmanın yanında "şunu anlatır mısın?" diye de sorulur. Bu klasördeki 30 soru onlar için: `DELETE` ile `TRUNCATE` farkı, ACID, normalizasyon, `WHERE` ile `HAVING` gibi.

Her sorunun başında **kısa cevap** var, mülakatta 20-30 saniyede söyleyebileceğin hâli. Altında ayrıntısı ve çoğu yerde örnek veritabanında ya da `ziyaretler` tablosunda denediğim sonuç duruyor. Rakamlar kendi makinemde alındı, süreler sende farklı çıkabilir, sayılar ve plan adımları aynı olmalı.

Okurken sadece ezberleme: kısa cevabı sesli söylemeyi dene, sonra ayrıntıya bakıp neyi atladığını gör. Bir iddiadan şüphelenirsen kendin çalıştırıp kontrol et, bütün örnekler [örnek veritabanıyla](../db/README.md) denenebilir.

| Dosya | Sorular |
|---|---|
| [01 SQL ve veri bütünlüğü](01-sql-ve-veri-butunlugu.md) | 1. DDL/DML/DCL/TCL · 2. Primary key ve unique · 3. Foreign key ve `ON DELETE` · 4. `NULL` · 5. `DELETE`/`TRUNCATE`/`DROP` · 6. Constraint türleri |
| [02 Sorgu mantığı](02-sorgu-mantigi.md) | 7. Sorgunun çalışma sırası · 8. `WHERE` ve `HAVING` · 9. `JOIN` türleri · 10. `UNION` ve `UNION ALL` · 11. `IN`, `EXISTS`, `NOT IN` tuzağı · 12. `COUNT` çeşitleri |
| [03 Index](03-index.md) | 13. Index nedir · 14. Index türleri · 15. Index neden kullanılmaz · 16. Covering index · 17. `EXPLAIN`, yavaş sorgu |
| [04 Transaction ve eşzamanlılık](04-transaction-ve-eszamanlilik.md) | 18. ACID · 19. Isolation level · 20. MVCC · 21. `VACUUM` · 22. Kilitler ve deadlock |
| [05 Veri modelleme](05-veri-modelleme.md) | 23. Normalizasyon · 24. Denormalizasyon · 25. İlişki türleri · 26. Surrogate key, `IDENTITY` · 27. Veri tipi seçimi |
| [06 Programlanabilir nesneler](06-programlanabilir-nesneler.md) | 28. View ve materialized view · 29. Function, procedure, trigger · 30. CTE, alt sorgu, geçici tablo |

SQL yazarak pratik yapmak istersen [pratik/](../pratik/) klasörüne bak.
