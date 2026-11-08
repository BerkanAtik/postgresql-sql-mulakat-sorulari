# Birleşik index ve kolon sırası

Zorluk: Orta · Konu: çok kolonlu index, kolon sırası, `ORDER BY ... LIMIT`

## Soru

42 numaralı müşterinin `sepet` sayfasına yaptığı ziyaretleri getiren sorguyu yaz. Önce sadece `musteri_id` için bir index oluşturup planına bak. Sonra iki kolonu birden kapsayan tek bir index kur ve planı karşılaştır. İki kolonu hangi sırayla yazmak daha doğru?

Sorgu 222 satır döndürmeli.

<details>
<summary>İpucu</summary>

`CREATE INDEX isim ON tablo (kolon1, kolon2)`. Önce `Rows Removed by Filter` satırına bak: index bulduğu satırların kaçını yine de atıyor?

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
CREATE INDEX idx_ziyaretler_musteri_sayfa ON ziyaretler (musteri_id, sayfa);

SELECT *
FROM ziyaretler
WHERE musteri_id = 42
  AND sayfa = 'sepet';
```

</details>

## Açıklama

Sadece `musteri_id` üzerinde index varken plan:

```text
Bitmap Heap Scan on ziyaretler
  Recheck Cond: (musteri_id = 42)
  Filter: (sayfa = 'sepet'::text)
  Rows Removed by Filter: 2278
  ->  Bitmap Index Scan on idx_ziyaretler_musteri
Execution Time: 2.3 ms
```

Index 42 numaralı müşterinin 2500 satırını buluyor, tablodan okuyor, sonra `sepet` olmayan 2278 tanesini atıyor. Index işe yaradı ama emeğin %90'ı boşa gitti.

İki kolonlu index ile:

```text
Bitmap Heap Scan on ziyaretler
  Recheck Cond: ((musteri_id = 42) AND (sayfa = 'sepet'::text))
  ->  Bitmap Index Scan on idx_ziyaretler_musteri_sayfa
        Index Cond: ((musteri_id = 42) AND (sayfa = 'sepet'::text))
Execution Time: 0.1 ms
```

Atılan satır kalmadı, index'ten sadece 222 satır geldi. Süre 2,3 ms'den yaklaşık 0,1 ms'ye düştü. Tablo küçük olduğu için mutlak fark az görünüyor ama oran 10-20 kat.

### Kolon sırası neden önemli?

Birleşik index, önce ilk kolona sonra ikinciye göre sıralanmış bir telefon rehberi gibi (önce soyadı, sonra ad). Soyadını biliyorsan hemen bulursun, sadece adı biliyorsan rehber işe yaramaz. `(musteri_id, sayfa)` index'i de aynı şekilde çalışıyor:

| Filtre | Index kullanılır mı |
|---|---|
| `musteri_id = 42 AND sayfa = 'sepet'` | Evet |
| `musteri_id = 42` | Evet (ilk kolon) |
| `sayfa = 'sepet'` | Hayır, Seq Scan (benim makinemde 34 ms) |

Ters sırayla, `(sayfa, musteri_id)` kursaydın tam tersi olurdu. İki kolonu birden filtreleyen sorgu yine hızlı çıkar (0,13 ms), ama sadece `musteri_id = 42` arayınca index kullanılmaz, Seq Scan'e (27-30 ms) düşer. PostgreSQL 17'de ilk kolonu atlayıp ikinciye bakan bir mekanizma yok.

Kural: ikisini de `=` ile filtreliyorsan sıra sorgunun hızını değiştirmiyor. O zaman **tek başına da sorgulanan kolonu başa koy**, çünkü o index başka sorgulara da hizmet eder. Burada müşteriye göre arama çok daha yaygın, o yüzden `musteri_id` başta.

### `ORDER BY` de index'ten gelebilir

Birleşik index sadece filtre için değil, sıralama için de işe yarıyor. "42 numaralı müşterinin son 10 ziyareti" için:

```text
SELECT * FROM ziyaretler
WHERE musteri_id = 42
ORDER BY ziyaret_zamani DESC
LIMIT 10;
```

Sadece `musteri_id` index'i varken PostgreSQL 2500 satırı okuyup sıralıyor (`Sort`, `top-N heapsort`), 2,5 ms sürüyor. `(musteri_id, ziyaret_zamani)` index'i varken:

```text
Limit
  ->  Index Scan Backward using idx_ziyaretler_musteri_zaman on ziyaretler
        Index Cond: (musteri_id = 42)
Execution Time: 0.04 ms
```

Satırlar index'te zaten sıralı olduğu için sondan 10 tanesini alıp duruyor, `Sort` adımı yok. Kalıp şu: önce `=` ile filtrelenen kolonlar, en sona sıralanan kolon.

## Sık yapılan hatalar

Her kolon için ayrı ayrı index kurmak. `musteri_id` ve `sayfa` için iki ayrı index olunca PostgreSQL ikisini birleştirebiliyor (`BitmapAnd`), ama burada `sayfa` index'inden 50.000 satırlık bir liste okumak zorunda kalıyor. Benim makinemde 1,2 ile 2 ms sürdü, birleşik index 0,1 ms. Üstüne iki index'in yazma maliyeti de var.

Kolon sırasını rastgele seçmek. Sorguların nasıl filtrelendiğine bakmadan `(sayfa, musteri_id)` diye kurarsan, en yaygın sorgun index'i kullanmayabilir.

Gereksiz index biriktirmek. `(musteri_id, sayfa)` kurduktan sonra tek başına `(musteri_id)` index'ine gerek kalmıyor, birleşik olan ilk kolon için de çalışıyor. Eskisini silmek hem yer hem yazma maliyeti kazandırır.

## Mülakatta

"Birleşik index'te kolon sırası neden önemli?" sorusunu rehber örneğiyle anlatmak yeterli. Üzerine "ikisi de `=` ile filtreleniyorsa sıra hıza etki etmez, tek başına sorgulanan kolonu başa koyarım, sıralama varsa o kolonu en sona koyarım" demek iyi bir cevap.

<!-- beklenen-satir: 222 -->
