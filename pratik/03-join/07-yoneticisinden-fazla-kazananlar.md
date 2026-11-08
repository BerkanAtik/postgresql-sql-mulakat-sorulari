# Yöneticisinden fazla kazanan çalışanlar

Zorluk: Orta · Konu: self join, iki satırı karşılaştırmak

## Soru

Kendi yöneticisinden daha fazla maaş alan çalışanları bul. Çalışanın adını, soyadını ve maaşını, yanına da yöneticisinin adını ve maaşını yaz.

Doğru yaptıysan 2 satır gelir.

<details>
<summary>İpucu</summary>

Bir önceki sorudaki self join'i kur. Artık her satırda hem çalışanın hem de yöneticisinin maaşı yan yana duruyor, geriye bir karşılaştırma kalıyor.

</details>

## Çözüm

<details>
<summary>Çözümü göster</summary>

```sql
SELECT c.ad, c.soyad, c.maas,
       y.ad   AS yonetici_ad,
       y.maas AS yonetici_maas
FROM calisanlar AS c
JOIN calisanlar AS y ON y.calisan_id = c.yonetici_id
WHERE c.maas > y.maas;
```

</details>

## Açıklama

Self join'in asıl gücü burada ortaya çıkıyor. Normalde `WHERE` tek bir satırın kolonlarına bakar. "Bu çalışanın maaşı yöneticisinin maaşından büyük mü?" sorusunda ise iki farklı satırı karşılaştırmamız gerekiyor. Self join, yöneticinin satırını çalışanın satırının yanına getirerek bunu tek satırlık bir karşılaştırmaya çeviriyor.

Bu sefer `LEFT JOIN` yerine `JOIN` yeterli. Yöneticisi olmayan genel müdürü karşılaştıracak kimse yok, sonuçta görünmesine gerek de yok. `LEFT JOIN` yazsan da sonuç değişmez, çünkü genel müdürün satırında `y.maas` `NULL` olur ve `WHERE` koşulu onu zaten eler.

## Sık yapılan hatalar

Karşılaştırmayı ters yazmak. `WHERE y.maas > c.maas` yazarsan "yöneticisi kendisinden fazla kazananlar" gelir, yani normal durumda olan 12 çalışan. Hangi takma adın hangi rolü oynadığını kafanda netleştirirsen bu hatayı yapmazsın, kolon adlarını `yonetici_maas` gibi açık yazmak da yardımcı oluyor.

## Mülakatta

Bu, self join için en bilinen mülakat sorularından biri. Aynı kalıp başka şekillerde de karşına çıkar: "Kendi departmanındaki ortalamadan fazla kazananlar", "aynı gün işe başlayan çalışan çiftleri" gibi. Hepsinde fikir aynı: karşılaştırmak istediğin iki satırı `JOIN` ile yan yana getir, sonra karşılaştır.

<!-- beklenen-satir: 2 -->
