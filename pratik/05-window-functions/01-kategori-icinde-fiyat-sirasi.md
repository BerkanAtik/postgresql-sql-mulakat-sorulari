# Kategori içinde fiyat sırası

Zorluk: Kolay · Konu: `ROW_NUMBER`, `OVER`, `PARTITION BY`

## Soru

Her ürünün kendi kategorisi içinde pahalılık sırasını bul: kategorinin en pahalı ürünü 1, ikincisi 2 olsun ve böyle devam etsin. `kategori_id`, ürün adı, fiyat ve sıra numarasını göster. Sonuç kategoriye, aynı kategoridekiler de sıraya göre dizilsin.

Doğru yaptıysan 50 satır gelir.

<details>
<summary>İpucu</summary>

Satırları gruplamadan, yani 50 ürünün hepsini kaybetmeden her ürüne bir numara vermen gerekiyor. Numaralandırma her kategoride baştan başlamalı.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT kategori_id, ad, fiyat,
       ROW_NUMBER() OVER (PARTITION BY kategori_id ORDER BY fiyat DESC) AS sira
FROM urunler
ORDER BY kategori_id, sira;
```

</details>

## Açıklama

Window function'lar `GROUP BY`'a benziyor ama önemli bir farkla: satırları birleştirmiyorlar. `GROUP BY` kullansaydık her kategori tek satıra inerdi. Burada ise 50 ürünün hepsi yerinde duruyor ve her birinin yanına grubuyla ilgili bir bilgi ekleniyor.

`OVER (...)` kısmı "bu hesabı hangi satırlar üzerinde yap" diyor:

- `PARTITION BY kategori_id` satırları kategorilere bölüyor. Numaralandırma her kategoride 1'den yeniden başlıyor.
- `ORDER BY fiyat DESC` her kategorinin içinde hangi sırayla numara verileceğini belirliyor.

`ROW_NUMBER()` da her satıra 1, 2, 3 diye artan bir numara veriyor. Bizim veride aynı kategoride aynı fiyatlı iki ürün yok, o yüzden sıralama her seferinde aynı çıkıyor. Eşit değerler olsaydı `ROW_NUMBER` onlara yine farklı numaralar verirdi ve hangisinin önce geleceği belli olmazdı. Bu konuya 3. soruda bakacağız.

Sondaki `ORDER BY kategori_id, sira` ise pencereden bağımsız, sadece sonucun nasıl gösterileceğini belirliyor.

## Sık yapılan hatalar

`PARTITION BY`'ı unutmak. `ROW_NUMBER() OVER (ORDER BY fiyat DESC)` yazarsan numaralar kategoriye göre sıfırlanmaz, bütün ürünler tek sırada 1'den 50'ye kadar numaralanır. Bu da "en pahalı ürünler listesi" sorusunun cevabı olur, bu sorunun değil.

<!-- beklenen-satir: 50 -->
