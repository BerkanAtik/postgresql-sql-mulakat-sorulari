# Ödeme yöntemine göre özet

Zorluk: Kolay · Konu: `COUNT`, `SUM`, `AVG`, `ROUND`

## Soru

Muhasebe, ödeme yöntemlerine göre bir özet istiyor. Her yöntem için işlem sayısını, toplam tutarı ve ortalama tutarı göster. Ortalama virgülden sonra 2 hane olsun. Toplam tutarı en yüksek yöntem en üstte olsun.

Doğru yaptıysan 3 satır gelir.

<details>
<summary>İpucu</summary>

Üç farklı hesap var ama hepsi aynı gruplamayı kullanıyor. Ortalamayı yuvarlamak için `ROUND`'un ikinci bir parametresi var.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT yontem,
       COUNT(*)                AS islem_sayisi,
       SUM(tutar)              AS toplam_tutar,
       ROUND(AVG(tutar), 2)    AS ortalama_tutar
FROM odemeler
GROUP BY yontem
ORDER BY toplam_tutar DESC;
```

</details>

## Açıklama

Bir `GROUP BY` ile istediğin kadar toplama fonksiyonunu yan yana kullanabilirsin. Her biri aynı grubun içinde ayrı bir hesap yapıyor: `COUNT(*)` satırları sayıyor, `SUM` topluyor, `AVG` ortalamasını alıyor.

`AVG(tutar)` ham hâliyle uzun bir ondalık sayı döndürür. Örneğin `havale` için `1121.7961860465116279` çıkar. `ROUND(AVG(tutar), 2)` bunu 1121.80 yapıyor. Yuvarlamayı sadece göstermek için yapıyoruz, ortalamayı başka bir hesapta kullanacaksan yuvarlamayı en sona bırak.

Bir ayrıntı daha: buradaki "işlem sayısı" sipariş sayısı değil, `odemeler` tablosundaki satır sayısı. Bazı siparişler iki parça hâlinde ödendiği için aynı sipariş iki işlem olarak sayılıyor. Toplam 962 ödeme satırı var ama bunlar 893 siparişe ait.

## Sık yapılan hatalar

`ROUND(AVG(tutar))` yazıp ikinci parametreyi unutmak. O zaman ortalama tam sayıya yuvarlanır, `1122`, `11695` gibi. Kuruş bilgisi kaybolur.

<!-- beklenen-satir: 3 -->
