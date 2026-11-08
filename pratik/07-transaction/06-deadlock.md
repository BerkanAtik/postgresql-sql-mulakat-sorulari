# Birbirini bekleyen iki işlem

Zorluk: Zor · Konu: deadlock, kilit sırası

## Soru

İki farklı işlem aynı anda iki ürünün stoğunu düşürüyor:

- İşlem A önce 1 numaralı ürünü, sonra 2 numaralıyı güncelliyor.
- İşlem B önce 2 numaralı ürünü, sonra 1 numaralıyı güncelliyor.

Bu ikisi aynı anda çalışınca birinin `deadlock detected` hatasıyla iptal edildiğini görüyorsun. Sorunu çözmek için bir işlemin iki ürünü hangi sırayla güncellemesi gerektiğini düşün ve 1 ile 2 numaralı ürünün stoğunu birer düşüren transaction'ı yaz. Sonda iki ürünün `urun_id` ve `stok` değerini göster.

Sorgu 2 satır döndürmeli.

<details>
<summary>İpucu</summary>

Sorun işlemlerin kilitleri farklı sırayla alması. Çözüm, ikisinin de her zaman aynı sırayla (örneğin küçük `urun_id`'den büyüğe) güncellemesi.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
BEGIN;

-- her işlem ürünleri her zaman urun_id'ye göre küçükten büyüğe güncellesin
UPDATE urunler SET stok = stok - 1 WHERE urun_id = 1;
UPDATE urunler SET stok = stok - 1 WHERE urun_id = 2;

SELECT urun_id, stok
FROM urunler
WHERE urun_id IN (1, 2)
ORDER BY urun_id;

COMMIT;
```

</details>

## Açıklama

Bir `UPDATE`, güncellediği satırı transaction bitene kadar kilitler. Deadlock şöyle oluşuyor:

| Zaman | İşlem A | İşlem B |
|---|---|---|
| 1 | 1 numaralı ürünü günceller (kilitler) | |
| 2 | | 2 numaralı ürünü günceller (kilitler) |
| 3 | 2 numaralıyı güncellemeye çalışır, B'yi bekler | |
| 4 | | 1 numaralıyı güncellemeye çalışır, A'yı bekler |

İkisi de ötekinin bitmesini bekliyor, kimse ilerleyemiyor. PostgreSQL bunu yaklaşık 1 saniye sonra (`deadlock_timeout`) fark edip işlemlerden birini iptal ediyor:

```text
ERROR:  deadlock detected
DETAIL:  Process 4372 waits for ShareLock on transaction 891; blocked by process 30960.
Process 30960 waits for ShareLock on transaction 890; blocked by process 4372.
HINT:  See server log for query details.
CONTEXT:  while updating tuple (0,2) in relation "urunler"
```

Bunu iki oturumla, her ifadenin arasında 1 saniye bekleyerek denedim. Bir oturum hata aldı ve geri alındı, diğeri tamamlandı. Sonuçta iki ürünün stoğu da sadece **bir** kez düştü (1 numaralı 45'ten 44'e, 2 numaralı 120'den 119'a), yani iptal edilen işlemin hiçbir etkisi kalmadı. Hatayı alan uygulamanın işlemi yeniden denemesi gerekiyor.

Çözüm kilitleri herkesin aynı sırayla alması. İki işlem de önce 1'i, sonra 2'yi güncellerse, A 1'i kilitlediğinde B 1'e takılır ve 2'ye hiç ulaşmaz. A işini bitirip kilidi bırakınca B devam eder. Döngü oluşamaz.

Aynı sırayı uygulamada nasıl sağlarsın? İki işlem de ürün numaralarını önce **sıraya dizip** öyle güncellemeli. Ya da başta tüm satırları sıralı kilitleyebilirsin:

```sql
BEGIN;

SELECT urun_id FROM urunler
WHERE urun_id IN (1, 2)
ORDER BY urun_id
FOR UPDATE;

-- bundan sonra istediğin sırayla güncelleyebilirsin, kilitler zaten alındı
UPDATE urunler SET stok = stok - 1 WHERE urun_id = 2;
UPDATE urunler SET stok = stok - 1 WHERE urun_id = 1;

COMMIT;
```

Bu hâlini de iki oturumla (biri 1 sonra 2, diğeri 2 sonra 1 güncelleyerek) denedim: deadlock çıkmadı, ikisi de tamamlandı ve stoklar 45'ten 43'e, 120'den 118'e düştü.

## Sık yapılan hatalar

Deadlock'u veritabanı hatası sanmak. Aslında uygulama kodundaki kilit sırası sorunu. Veritabanı sadece takılan işlemi iptal ederek bir çıkış sağlıyor.

Hatayı yakalamayıp kullanıcıya göstermek. Deadlock olabilecek yerlerde işlemi birkaç kez yeniden deneyen mantık yazmak gerekiyor.

Transaction'ı gereksiz uzun tutmak. Ne kadar uzun açık kalırsa kilitler o kadar uzun tutulur, deadlock ve bekleme ihtimali artar. Transaction içinde kullanıcıdan girdi bekleme, dış servise istek atma gibi şeyler yapma.

## Mülakatta

"Deadlock nedir, nasıl önlersin?" Cevap: iki işlem birbirinin kilidini bekleyince oluşur. Önlemek için kilitleri her yerde aynı sırayla almak, transaction'ları kısa tutmak, deadlock hatası alındığında yeniden denemek. PostgreSQL'in deadlock'u kendisinin tespit edip birini iptal ettiğini eklemek iyi.

<!-- beklenen-satir: 2 -->
