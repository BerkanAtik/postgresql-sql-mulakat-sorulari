# Katkıda bulunmak

Bir sorudaki hatayı düzeltmek, yeni soru önermek ya da yazım hatası bulmak, hepsi işe yarıyor. Büyük bir değişiklik düşünüyorsan önce bir issue açıp konuşalım, boşuna emek harcama.

## Hata bulursan

Şunlardan biri varsa issue aç:

- Çözüm çalışmıyor ya da yanlış sonuç veriyor.
- Açıklamadaki bir sayı, plan çıktısı ya da iddia doğru değil.
- Anlatım kafa karıştırıyor.

Issue'da dosya adını ve hangi satırdan bahsettiğini yaz, bir de kendi çalıştırdığında ne gördüğünü. PostgreSQL sürümünü de ekle (`SELECT version();`). Bütün çözümler PostgreSQL 17'de doğrulanıyor, başka sürümde farklı plan çıkabilir.

## Kurulum

[README'deki](README.md) adımlarla veritabanını ayağa kaldır. Değişiklik yaptıktan sonra bunu çalıştır:

```bash
bash scripts/validate.sh
```

Hepsi geçmeden PR açma. Aynı kontrol GitHub'da da otomatik çalışıyor.

## Yeni soru eklemek

Soru dosyaları `pratik/<modül>/NN-kisa-ad.md` biçiminde. Dosya adı küçük harf, Türkçe karaktersiz, `NN` sıra numarası. Mevcut bir soruyu açıp yapısına bak, aynısını izle:

1. Başlık, ardından `Zorluk: · Konu:` satırı.
2. `## Soru`: ne istendiği, doğru çözümde kaç satır geleceği, `<details>` içinde ipucu.
3. `## Çözüm`: `<details>` içinde tek bir ` ```sql ` bloğu.
4. `## Açıklama`: neden böyle yazıldığı.
5. İsteğe bağlı: `## Alternatif çözüm`, `## Sık yapılan hatalar`, `## Mülakatta`.
6. En sonda gizli satır sayısı: `<!-- beklenen-satir: 12 -->`.

`validate.sh`, `## Çözüm` ve `## Alternatif` başlıklarının altındaki sql bloklarını çalıştırıp satır sayısını bu yorumla karşılaştırıyor, alternatiflerin çıktısı da asıl çözümle aynı olmalı. Diğer bölümlerdeki (örneğin "Açıklama" ya da "Sık yapılan hatalar") sql blokları çalıştırılmıyor. Bu yüzden oradaki örnekleri kendin çalıştırıp doğru olduğundan emin ol. Ek bir başlığın adını "Çözüm" ya da "Alternatif" ile başlatma, çünkü o zaman altındaki bloklar da çalıştırılır.

Sorunun yeni bir modül klasörü gerekiyorsa modülün kendi `README.md` dosyasına konu özetini ve soru tablosunu ekle, ana README'deki modül tablosunu da güncelle.

Dikkat edilecekler:

- Tablo ve kolon adları [örnek veritabanındaki](db/README.md) gibi, Türkçe karaktersiz.
- `CURRENT_DATE` gibi değişen değerler kullanma, veri 2024'e ait, sabit tarih ver.
- Açıklamaya yazdığın her sayıyı ve plan çıktısını gerçekten çalıştırıp kontrol et. "Muhtemelen şöyle çıkar" diye yazma, çıkmıyorsa en çok bu yanıltıyor. Süre yazıyorsan "benim makinemde" diye belirt.
- Kısa, sade ve düz Türkçe yaz. Teknik terimleri (`index`, `join`, `transaction`) olduğu gibi bırak.
- Çözümün veritabanını kalıcı değiştirmemesi gerekiyor. `BEGIN` ile başlayan çözümlerde `COMMIT` doğrulama sırasında `ROLLBACK`'e çevriliyor, ama yine de dikkat et.

## Kavramsal soru eklemek

`kavramsal/` altındaki dosyalarda her soru `## N. Soru?` başlığıyla başlıyor, ardından **Kısa cevap** (mülakatta söyleyeceğin 20-30 saniyelik hâli) ve ayrıntı geliyor. Numaralar sırayla gidiyor. Bu dosyalar `validate.sh` tarafından çalıştırılmıyor, bu yüzden verdiğin örnekleri kendin PostgreSQL'de deneyip sonucu yazman gerekiyor.

## Pull request

- Küçük ve tek konulu tut.
- Ne değiştirdiğini ve neden değiştirdiğini birkaç cümleyle yaz.
- `validate.sh` geçiyor olmalı.

Katkılar [MIT lisansı](LICENSE) altında yayınlanır.
