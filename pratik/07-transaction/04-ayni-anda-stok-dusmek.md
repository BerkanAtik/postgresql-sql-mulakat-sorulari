# Aynı anda stok düşmek

Zorluk: Orta · Konu: kayıp güncelleme (lost update), atomik `UPDATE`, `FOR UPDATE`

## Soru

Uygulamanın stok düşme kodu şöyle çalışıyor:

1. `SELECT stok FROM urunler WHERE urun_id = 5` ile stoğu oku (25),
2. uygulamada `25 - 1 = 24` hesapla,
3. `UPDATE urunler SET stok = 24 WHERE urun_id = 5` ile yaz.

İki müşteri aynı anda birer adet alınca stok 23'e değil, 24'e iniyor: bir satış kayboluyor. Bunu tek bir `UPDATE` ifadesiyle düzelt. Stok yetersizse (0'ın altına inecekse) hiçbir şey güncellenmesin, ve güncellenen satırın yeni stoğunu geri döndürsün.

Sorgu 1 satır döndürmeli: yeni stok (5 numaralı ürün için 24).

<details>
<summary>İpucu</summary>

Değeri uygulamada hesaplamak yerine veritabanına hesaplat: `SET stok = stok - 1`. Yetersiz stok durumunu `WHERE` koşuluyla ele alabilirsin. Sonucu geri almak için `RETURNING`.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
UPDATE urunler
SET stok = stok - 1
WHERE urun_id = 5
  AND stok >= 1
RETURNING stok;
```

</details>

## Açıklama

Sorunun kaynağı "oku, uygulamada hesapla, yaz" sırası. İki oturum aynı anda şöyle ilerlediğinde:

| Zaman | Oturum A | Oturum B |
|---|---|---|
| 1 | `SELECT stok` → 25 | |
| 2 | | `SELECT stok` → 25 |
| 3 | `UPDATE ... SET stok = 24` | |
| 4 | | `UPDATE ... SET stok = 24` |

İki satış oldu ama stok 24. B, A'nın düşüşünü hiç görmedi, kendi okuduğu 25'ten devam etti. Bu iki oturumla denediğimde (arada birkaç saniye bekleterek) benim makinemde sonuç gerçekten 24 çıktı.

`CHECK (stok >= 0)` bunu yakalamıyor, çünkü 24 geçerli bir değer. Hata vermeden sessizce yanlış sonuç üretiyor.

Çözümde hesabı veritabanı yapıyor: `SET stok = stok - 1`. İki oturum aynı anda gelse bile ikincisi, birincinin işi bitene kadar satırı kilit nedeniyle bekliyor, sonra güncel değerden devam ediyor. Aynı iki oturumla bu yöntemi denediğimde sonuç 23 çıktı.

`AND stok >= 1` ise stok yetmediğinde işi hata yerine "0 satır güncellendi" ile bitiriyor. Stoğu 0 olan 33 numaralı ürün için bu sorgu hiç satır döndürmez, uygulama da `RETURNING`'den satır gelmemesine bakıp "stok yok" diyebilir. `CHECK` hatasını beklemekten daha temiz.

### Önce okuyup karar vermen gerekiyorsa

Bazen stoğa göre uygulamada karmaşık bir karar vermen gerekir ve tek `UPDATE`'e sığmaz. O zaman okurken satırı kilitle:

```sql
BEGIN;

SELECT stok FROM urunler WHERE urun_id = 5 FOR UPDATE;
-- uygulama burada karar verir; başka bir oturum bu satırı COMMIT'e kadar bekler

UPDATE urunler SET stok = 24 WHERE urun_id = 5;

COMMIT;
```

`FOR UPDATE` satırı kilitliyor, diğer oturum `SELECT ... FOR UPDATE` ya da `UPDATE` yapmaya kalkınca ilk transaction bitene kadar bekliyor. Bu yöntemi de iki oturumla denedim, sonuç 23 çıktı. Ama `FOR UPDATE`'siz düz `SELECT` kilidi beklemez, o yüzden iki taraf da kullanmak zorunda.

## Sık yapılan hatalar

"Okuyup, uygulamada hesaplayıp, yazmak". En yaygın ve en sessiz hata. Her zaman hesabı `UPDATE` içinde yap.

`SELECT` ile stoğu kontrol edip sonra ayrı bir `UPDATE` yazmak. Arada başkası araya girerse kontrol yanlış çıkar. Kontrol ve güncelleme aynı ifadede olmalı (`WHERE stok >= 1`).

`FOR UPDATE`'i her yere koymak. Kilitler başkalarını bekletir. Sadece okuyup sonra o satırı değiştirecekseniz kullan, sadece okuyorsan gerekmez.

## Mülakatta

"İki kullanıcı aynı anda son ürünü almaya çalışırsa ne olur?" sorusu klasik. Cevap: önce sorunu anlat (oku-hesapla-yaz sırasındaki kayıp güncelleme), sonra çözümü ver: `SET stok = stok - 1 WHERE stok >= 1` ile atomik güncelleme, karar gerekiyorsa `SELECT ... FOR UPDATE`.

<!-- beklenen-satir: 1 -->
