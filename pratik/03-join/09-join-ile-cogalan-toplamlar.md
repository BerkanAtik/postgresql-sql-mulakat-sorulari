# Bölünmüş ödemeler ve çoğalan toplamlar

Zorluk: Zor · Konu: `JOIN` çoğaltması (fan-out), önce toplayıp sonra birleştirmek

## Soru

Bazı siparişlerin ödemesi iki parçaya bölünmüş. Muhasebe bu siparişlerde ödemelerin sipariş tutarını tuttuğunu kontrol etmek istiyor. Birden fazla ödemesi olan her sipariş için sipariş numarasını, kalemlerden hesaplanan sipariş tutarını (`adet * birim_fiyat` toplamı) ve ödemelerin toplamını göster. Sipariş numarasına göre sırala.

Doğru yaptıysan 69 satır gelir ve **her satırda iki tutar birbirine eşit olur**. Eşit çıkmayan bir satır varsa sorguda bir sorun var demektir.

<details>
<summary>İpucu</summary>

Önce aklına gelen yolu dene: `siparisler`, `siparis_kalemleri` ve `odemeler`'i birlikte `JOIN` et ve iki `SUM` yaz. Sonra 13 numaralı siparişin tutarını elle kontrol et. Bir siparişte 2 kalem ve 2 ödeme varsa `JOIN` sonucunda kaç satır oluşur?

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT k.siparis_id, k.kalem_toplami, o.odeme_toplami
FROM (
    SELECT siparis_id, SUM(adet * birim_fiyat) AS kalem_toplami
    FROM siparis_kalemleri
    GROUP BY siparis_id
) AS k
JOIN (
    SELECT siparis_id, SUM(tutar) AS odeme_toplami
    FROM odemeler
    GROUP BY siparis_id
    HAVING COUNT(*) > 1
) AS o ON o.siparis_id = k.siparis_id
ORDER BY k.siparis_id;
```

</details>

## Açıklama

Akla ilk gelen sorgu şöyle bir şey:

```text
SELECT s.siparis_id, SUM(k.adet * k.birim_fiyat), SUM(o.tutar)
FROM siparisler s
JOIN siparis_kalemleri k ON k.siparis_id = s.siparis_id
JOIN odemeler o          ON o.siparis_id = s.siparis_id
GROUP BY s.siparis_id
```

Hata vermiyor ama sayılar yanlış. 13 numaralı siparişe bakalım: 2 kalemi ve 2 ödemesi var. `JOIN` bir siparişin her kalemini o siparişin her ödemesiyle eşleştirir. 2 kalem × 2 ödeme = 4 satır oluşur. Her kalem iki kez, her ödeme de iki kez sayılır.

Gerçekte bu siparişin tutarı 4.048,70 TL, ödemeleri de 4.048,70 TL. Hatalı sorgu ise ikisini de 8.097,40 TL gösteriyor. En tehlikeli yanı şu: iki sayı **birbirini tutuyor**. İkisi de iki katına çıktığı için kontrol "her şey yolunda" diyor. 69 siparişin 53'ünde sayılar tutmuyor ve hata göze çarpıyor, ama kalem sayısı ile ödeme sayısı aynı olan 16 siparişte iki toplam da şişmiş hâlde birbirine eşit çıkıyor. Bu yüzden "toplamlar tuttu" demek, doğru hesapladın demek değil.

Bu hataya fan-out (çoğalma) deniyor. Bir siparişe "birden çok" bağlı iki tabloyu aynı anda `JOIN` edersen satırlar çarpılır.

Çözüm: **önce topla, sonra birleştir.** Kalemleri kendi içinde sipariş başına topluyoruz, ödemeleri de kendi içinde. Artık iki tarafta da sipariş başına tek satır var, bunları birleştirince çarpma olmuyor. `FROM` içinde parantezle yazdığımız bu sorgulara alt sorgu (subquery) deniyor, bir sonraki modülde ayrıntılı göreceğiz.

## Alternatif çözüm

Kalem toplamını `SELECT` içinde ayrı bir alt sorguyla da hesaplayabilirsin. Ödemeler tek başına gruplanıyor, kalemler her sipariş için ayrı hesaplanıyor, iki tablo hiç `JOIN` olmuyor:

```sql
SELECT o.siparis_id,
       (SELECT SUM(k.adet * k.birim_fiyat)
        FROM siparis_kalemleri AS k
        WHERE k.siparis_id = o.siparis_id) AS kalem_toplami,
       SUM(o.tutar) AS odeme_toplami
FROM odemeler AS o
GROUP BY o.siparis_id
HAVING COUNT(*) > 1
ORDER BY o.siparis_id;
```

## Mülakatta

Raporlama ve veri analistliği mülakatlarında bu soru sık gelir, gerçek işte de en çok yapılan hatalardan biri. "İki tabloyu birleştirince toplam neden iki katına çıktı?" sorusuna cevabın: ikisi de aynı tabloya bire-çok bağlı olduğu için satırlar çarpıldı. Çözüm, her tabloyu önce kendi içinde toplamak, sonra birleştirmek.

<!-- beklenen-satir: 69 -->
