# Rapor sırasında veri değişirse

Zorluk: Orta · Konu: isolation level, `READ COMMITTED`, `REPEATABLE READ`

## Soru

Bir stok raporu iki sorgudan oluşuyor: bütün ürünlerin toplam stoğu, sonra ürün sayısı. Rapor çalışırken başka biri stokları güncelleyebilir. İki sorgunun da veritabanının aynı andaki hâlini görmesini istiyorsun.

İki sorguyu doğru isolation level ile tek bir transaction içinde yaz.

Sorgu 2 satır döndürmeli: toplam stok (6880) ve ürün sayısı (50).

<details>
<summary>İpucu</summary>

`BEGIN ISOLATION LEVEL ...` ile transaction'ın seviyesini seçebilirsin. PostgreSQL'in varsayılanı her ifadenin kendi anındaki veriyi görmesi. Transaction boyunca sabit bir görüntü istiyorsan hangisini seçmelisin?

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
BEGIN ISOLATION LEVEL REPEATABLE READ;

SELECT SUM(stok) AS toplam_stok FROM urunler;
SELECT COUNT(*) AS urun_sayisi FROM urunler;

COMMIT;
```

</details>

## Açıklama

Varsayılan seviye `READ COMMITTED`. Bu seviyede her ifade, **çalıştığı andaki** commit edilmiş veriyi görüyor. Transaction'ın içinde bile iki sorgu arasında başkası bir şey commit ederse ikinci sorgu yeni veriyi görür.

İki oturumla denedim. A oturumu iki kez toplam stoğu okuyor, arada 2 saniye bekliyor; B oturumu bu sırada 5 numaralı ürünün stoğunu 5 azaltıp commit ediyor:

```text
READ COMMITTED   →  6880, sonra 6875
REPEATABLE READ  →  6880, sonra 6880
```

`READ COMMITTED`'ta aynı transaction içinde aynı sorgu iki farklı sonuç verdi (buna **non-repeatable read** deniyor). `REPEATABLE READ`'de transaction boyunca aynı görüntüyü görüyor: ilk sorguda alınan "fotoğraf" transaction bitene kadar geçerli.

Mutlaka iki sorgu gerekmiyorsa en kolay çözüm tek sorguya indirmek:

```sql
SELECT SUM(stok) AS toplam_stok, COUNT(*) AS urun_sayisi FROM urunler;
```

Tek ifade zaten tek bir görüntü üzerinde çalışır, hangi seviyede olursan ol tutarlıdır. İsolation level asıl, birden fazla ifadenin aynı görüntüyü görmesi gerektiğinde lazım.

### PostgreSQL'deki seviyeler

| Seviye | Ne görürsün |
|---|---|
| `READ COMMITTED` (varsayılan) | Her ifade, çalıştığı anda commit edilmiş veriyi görür |
| `REPEATABLE READ` | Transaction boyunca ilk sorgudaki görüntüyü görürsün |
| `SERIALIZABLE` | İşlemler sanki sırayla, teker teker çalışmış gibi sonuç verir. Çakışma olursa hata verir, uygulamanın yeniden denemesi gerekir |
| `READ UNCOMMITTED` | PostgreSQL'de `READ COMMITTED` gibi davranır, commit edilmemiş veriyi hiç okuyamazsın |

Son satırı kendim denedim: bir oturum stoğu 999 yapıp henüz commit etmemişken, `READ UNCOMMITTED` ile açılan ikinci oturum 25'i okudu, 999'u değil. Yani PostgreSQL'de "kirli okuma" (dirty read) mümkün değil. Bazı veritabanlarında bu seviye gerçekten commit edilmemiş veriyi gösterir.

PostgreSQL'in `REPEATABLE READ` seviyesi bir görüntü (snapshot) tutarak çalışıyor, bu yüzden standardın izin verdiği "phantom read" (aralıkta yeni satır belirmesi) de olmuyor.

### Bedeli: çakışma hatası

`REPEATABLE READ`'de, transaction'ın görüntüsü alındıktan sonra başkasının commit ettiği bir satırı sen de değiştirmeye kalkarsan PostgreSQL izin vermiyor:

```text
A: BEGIN ISOLATION LEVEL REPEATABLE READ;
A: SELECT stok FROM urunler WHERE urun_id = 5;     -- 25
B: UPDATE urunler SET stok = stok - 5 WHERE urun_id = 5;   -- commit edildi
A: UPDATE urunler SET stok = stok - 1 WHERE urun_id = 5;
ERROR:  could not serialize access due to concurrent update
```

Bu hata sorun değil, tasarımın parçası: uygulamanın transaction'ı baştan yeniden denemesi bekleniyor. `SERIALIZABLE`'da da aynı tür hata çıkabilir. Bu yüzden bu seviyeleri kullanırken retry mantığı yazmak gerekiyor.

## Sık yapılan hatalar

Tek sorguya sığacak raporu iki sorgu yazıp seviye değiştirmeye çalışmak. Önce tek sorguya indirmeyi dene.

Yüksek seviyenin her zaman daha iyi olduğunu sanmak. Yüksek seviye hata ve yeniden deneme getirir, daha çok kaynak kullanır. Varsayılan seviye çoğu işe yeter.

`SET TRANSACTION ISOLATION LEVEL` komutunu `BEGIN`'den sonra, ilk sorgudan önce yazmak gerekiyor. İlk sorgu çalıştıktan sonra seviyeyi değiştiremezsin. `BEGIN ISOLATION LEVEL ...` yazmak daha güvenli.

## Mülakatta

"Isolation level'lar nedir?" sorusunda dört seviyeyi ezberlemekten çok, her birinde hangi problemin ortaya çıktığını anlatmak istenir: dirty read, non-repeatable read, phantom read. PostgreSQL'e özel şu ayrıntıları eklersen fark yaratırsın: varsayılan `READ COMMITTED`, `READ UNCOMMITTED` fiilen yok, `REPEATABLE READ` snapshot ile phantom'u da engelliyor.

<!-- beklenen-satir: 2 -->
