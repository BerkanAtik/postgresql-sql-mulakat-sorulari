-- E-ticaret örnek veritabanı: veri
--
-- Veri tamamen deterministik: random() kullanmadım, herkes birebir aynı veriyi alıyor.
-- Böylece sorulardaki sonuçlar her makinede aynı çıkıyor.
-- Siparişler 2024 yılına yayılmış. Sorgularda CURRENT_DATE yerine sabit tarih kullanın.

-- Windows'ta konsol kod sayfası farklıysa Türkçe karakterler bozulmasın.
SET client_encoding = 'UTF8';

-- ---------------------------------------------------------------
-- Kategoriler
-- ---------------------------------------------------------------
INSERT INTO kategoriler (kategori_id, ad, ust_kategori_id) VALUES
    (1,  'Elektronik',         NULL),
    (2,  'Giyim',              NULL),
    (3,  'Ev ve Yaşam',        NULL),
    (4,  'Kitap',              NULL),
    (5,  'Spor ve Outdoor',    NULL),
    (6,  'Telefon',            1),
    (7,  'Bilgisayar',         1),
    (8,  'Kulaklık ve Ses',    1),
    (9,  'Erkek Giyim',        2),
    (10, 'Kadın Giyim',        2),
    (11, 'Ayakkabı',           2),
    (12, 'Mutfak',             3),
    (13, 'Mobilya',            3),
    (14, 'Roman',              4),
    (15, 'Yazılım Kitapları',  4),
    (16, 'Fitness',            5),
    (17, 'Kamp',               5),
    (18, 'Dekorasyon',         3);   -- içinde hiç ürün yok, bilerek

-- ---------------------------------------------------------------
-- Ürünler
-- 47-50 numaralı ürünler hiç sipariş almadı. 33 stokta yok, 33 ve 47 satıştan kalktı.
-- ---------------------------------------------------------------
INSERT INTO urunler (urun_id, ad, kategori_id, fiyat, stok, aktif) VALUES
    (1,  'Akıllı Telefon X12 128 GB',        6,  18999.00,  45, TRUE),
    (2,  'Akıllı Telefon Lite 64 GB',        6,   8499.90, 120, TRUE),
    (3,  'Telefon Kılıfı Silikon',           6,    149.90, 500, TRUE),
    (4,  'Hızlı Şarj Adaptörü 20W',          6,    299.00, 300, TRUE),
    (5,  'Dizüstü Bilgisayar 15.6"',         7,  32999.00,  25, TRUE),
    (6,  'Mekanik Klavye',                   7,   1899.00,  80, TRUE),
    (7,  'Kablosuz Mouse',                   7,    449.90, 200, TRUE),
    (8,  '27" Monitör',                      7,   6799.00,  40, TRUE),
    (9,  'USB-C Çoklu Hub',                  7,    799.00, 150, TRUE),
    (10, 'Kablosuz Kulaklık Pro',            8,   3499.00,  70, TRUE),
    (11, 'Bluetooth Hoparlör',               8,   1299.00,  90, TRUE),
    (12, 'Kulak İçi Kulaklık',               8,    399.90, 250, TRUE),
    (13, 'Pamuklu Basic Tişört',             9,    249.90, 400, TRUE),
    (14, 'Slim Fit Kot Pantolon',            9,    899.00, 180, TRUE),
    (15, 'Kışlık Mont',                      9,   2499.00,  60, TRUE),
    (16, 'Polo Yaka Tişört',                 9,    349.90, 220, TRUE),
    (17, 'Örgü Kazak',                       10,   749.00, 140, TRUE),
    (18, 'Yazlık Elbise',                    10,  1099.00,  95, TRUE),
    (19, 'Yüksek Bel Pantolon',              10,   799.00, 130, TRUE),
    (20, 'Keten Gömlek',                     10,   599.00, 160, TRUE),
    (21, 'Koşu Ayakkabısı',                  11,  2299.00,  85, TRUE),
    (22, 'Günlük Spor Ayakkabı',             11,  1599.00, 110, TRUE),
    (23, 'Deri Bot',                         11,  2999.00,  50, TRUE),
    (24, 'Çelik Tencere Seti 6 Parça',       12,  1899.00,  60, TRUE),
    (25, 'Filtre Kahve Makinesi',            12,  1399.00,  75, TRUE),
    (26, 'Blender',                          12,   899.00, 100, TRUE),
    (27, 'Çay Makinesi',                     12,  1299.00,  90, TRUE),
    (28, 'Bıçak Seti',                       12,   649.00, 120, TRUE),
    (29, 'Tost Makinesi',                    12,   999.00,  85, TRUE),
    (30, 'Çalışma Masası',                   13,  2799.00,  30, TRUE),
    (31, 'Ofis Koltuğu',                     13,  3999.00,  20, TRUE),
    (32, 'Kitaplık 5 Raflı',                 13,  1599.00,  35, TRUE),
    (33, 'Orta Sehpa',                       13,   899.00,   0, FALSE),
    (34, 'Suç ve Ceza',                      14,   129.00, 300, TRUE),
    (35, 'Sefiller',                         14,   189.00, 200, TRUE),
    (36, 'Tutunamayanlar',                   14,   169.90, 150, TRUE),
    (37, 'Kürk Mantolu Madonna',             14,    79.90, 400, TRUE),
    (38, 'Simyacı',                          14,    99.00, 350, TRUE),
    (39, 'SQL ile Veri Analizi',             15,   349.00,  90, TRUE),
    (40, 'Temiz Kod',                        15,   449.00,  70, TRUE),
    (41, 'PostgreSQL Rehberi',               15,   399.00,  60, TRUE),
    (42, 'Algoritmalara Giriş',              15,   599.00,  45, TRUE),
    (43, 'Yoga Matı',                        16,   299.00, 200, TRUE),
    (44, 'Ayarlanabilir Dambıl Seti',        16,  1799.00,  40, TRUE),
    (45, 'Direnç Bandı Seti',                16,   249.00, 260, TRUE),
    (46, 'Atlama İpi',                       16,    99.90, 300, TRUE),
    (47, '2 Kişilik Çadır',                  17,  2499.00,  25, FALSE),
    (48, 'Uyku Tulumu',                      17,   899.00,  55, TRUE),
    (49, 'Kamp Sandalyesi',                  17,   449.00,  80, TRUE),
    (50, 'Termos 750 ml',                    17,   349.00, 140, TRUE);

-- ---------------------------------------------------------------
-- Müşteriler (200 kişi)
--   * Her 25. müşterinin şehri boş (NULL), her 17.'nin doğum tarihi boş.
--   * Numarası 10'a bölünen müşteriler (20 kişi) hiç sipariş vermedi.
-- ---------------------------------------------------------------
INSERT INTO musteriler (musteri_id, ad, soyad, email, sehir, dogum_tarihi, kayit_tarihi)
SELECT
    i,
    ad,
    soyad,
    lower(translate(ad || '.' || soyad, 'çğıöşüÇĞİÖŞÜ', 'cgiosuCGIOSU')) || i || '@ornek.com',
    CASE WHEN i % 25 = 0 THEN NULL
         ELSE (ARRAY['İstanbul', 'İstanbul', 'İstanbul', 'Ankara', 'Ankara', 'İzmir',
                     'İzmir', 'Bursa', 'Antalya', 'Adana', 'Konya', 'Trabzon'])[((i * 5) % 12) + 1]
    END,
    CASE WHEN i % 17 = 0 THEN NULL
         ELSE DATE '1980-01-01' + ((i * 131) % 9000)
    END,
    DATE '2022-01-01' + ((i * 37) % 720)
FROM (
    SELECT
        i,
        (ARRAY['Ahmet', 'Mehmet', 'Ayşe', 'Fatma', 'Zeynep', 'Mustafa', 'Emre', 'Elif',
               'Burak', 'Selin', 'Can', 'Deniz', 'Cem', 'Merve', 'Ece', 'Kerem',
               'Büşra', 'Onur', 'Gizem', 'Yusuf'])[(i % 20) + 1] AS ad,
        (ARRAY['Yılmaz', 'Kaya', 'Demir', 'Çelik', 'Şahin', 'Yıldız', 'Aydın', 'Özdemir',
               'Arslan', 'Doğan', 'Kılıç', 'Aslan', 'Çetin', 'Koç', 'Kurt', 'Özkan',
               'Şimşek', 'Polat', 'Erdoğan', 'Güneş'])[((i * 7 + 3 * (i / 20)) % 20) + 1] AS soyad
    FROM generate_series(1, 200) AS i
) AS m
ORDER BY i;

-- ---------------------------------------------------------------
-- Siparişler (1000 adet, 2024 boyunca)
--   * Sipariş sayısı yıl içinde artıyor (ocakta günde ~2, aralıkta günde ~3-4).
--   * Son 30 siparişin bir kısmı beklemede ya da kargoda.
--   * Yaklaşık %10'u iptal, %5'i iade.
-- ---------------------------------------------------------------
INSERT INTO siparisler (siparis_id, musteri_id, siparis_tarihi, durum, kupon_kodu)
SELECT
    k,
    j + j / 9 + 1,    -- 10'a bölünen müşteri numaralarını atlar
    TIMESTAMP '2024-01-01 08:00:00'
        + floor(366 * power((k - 1) / 1000.0, 0.8))::int * INTERVAL '1 day'
        + ((k * 53) % 840) * INTERVAL '1 minute',
    CASE
        WHEN k > 970       THEN (ARRAY['beklemede', 'kargoda', 'tamamlandi'])[(k % 3) + 1]
        WHEN k % 20 IN (0, 1) THEN 'iptal'
        WHEN k % 20 = 2    THEN 'iade'
        ELSE 'tamamlandi'
    END,
    CASE WHEN k % 6 = 0 THEN 'YENI10'
         WHEN k % 11 = 0 THEN 'BAHAR20'
    END
FROM (
    SELECT k, (k * 13 + (k * k) % 97) % 180 AS j
    FROM generate_series(1, 1000) AS k
) AS s
ORDER BY k;

-- ---------------------------------------------------------------
-- Sipariş kalemleri
--   * Her sipariş 1 ile 4 kalem içeriyor.
--   * Ucuz ürünler (atlama ipi, tişört, kılıf, kulaklık...) daha sık satılıyor,
--     pahalı ürünler (telefon, bilgisayar) az adet ama yüksek ciro getiriyor.
--     Yani "en çok satan" ile "en çok ciro yapan" ürün aynı çıkmıyor.
--   * Bazı kalemlerde birim_fiyat, ürünün güncel fiyatından %10 düşük
--     (indirimli satılmış). Toplam hesaplarken urunler.fiyat ile
--     siparis_kalemleri.birim_fiyat arasındaki fark sonucu değiştirir.
-- ---------------------------------------------------------------
WITH agirlik AS (
    SELECT urun_id,
           CASE WHEN urun_id = 46                              THEN 5
                WHEN urun_id IN (3, 12, 13, 16, 37, 45)        THEN 4
                WHEN urun_id IN (4, 7, 20, 34, 35, 38, 39, 43) THEN 2
                ELSE 1
           END AS w
    FROM urunler
    WHERE urun_id <= 46     -- 47-50 hiç satılmasın
),
havuz AS (
    -- Ağırlığı kadar tekrarlanan ürün listesi. Toplam 76 satır (5 + 6*4 + 8*2 + 31*1).
    SELECT row_number() OVER (ORDER BY a.urun_id, g) - 1 AS idx, a.urun_id
    FROM agirlik AS a
    CROSS JOIN LATERAL generate_series(1, a.w) AS g
)
INSERT INTO siparis_kalemleri (siparis_id, urun_id, adet, birim_fiyat)
SELECT
    s.siparis_id,
    u.urun_id,
    1 + ((s.siparis_id + m) % 3),
    CASE WHEN (s.siparis_id + m) % 9 = 0 THEN round(u.fiyat * 0.90, 2) ELSE u.fiyat END
FROM siparisler AS s
CROSS JOIN LATERAL generate_series(1, 1 + (s.siparis_id % 4)) AS m
JOIN havuz AS h ON h.idx = (s.siparis_id * 7 + m * 11) % 76
JOIN urunler AS u ON u.urun_id = h.urun_id
ORDER BY s.siparis_id, m
ON CONFLICT (siparis_id, urun_id) DO NOTHING;

-- ---------------------------------------------------------------
-- Ödemeler
--   * Sadece tamamlanan, kargodaki ve iade edilen siparişler için ödeme var.
--   * İptal ve beklemedeki siparişlerin ödemesi yok.
--   * Her 13. siparişte ödeme iki parçaya bölünmüş (taksit gibi).
-- ---------------------------------------------------------------
WITH toplam AS (
    SELECT s.siparis_id, s.siparis_tarihi, SUM(k.adet * k.birim_fiyat) AS tutar
    FROM siparisler AS s
    JOIN siparis_kalemleri AS k ON k.siparis_id = s.siparis_id
    WHERE s.durum IN ('tamamlandi', 'kargoda', 'iade')
    GROUP BY s.siparis_id, s.siparis_tarihi
),
parcalar AS (
    SELECT siparis_id, 1 AS sira,
           CASE WHEN siparis_id % 13 = 0 THEN round(tutar / 2, 2) ELSE tutar END AS tutar,
           siparis_tarihi + ((siparis_id % 90) + 5) * INTERVAL '1 minute' AS odeme_tarihi
    FROM toplam
    UNION ALL
    SELECT siparis_id, 2,
           tutar - round(tutar / 2, 2),
           siparis_tarihi + INTERVAL '1 day' + ((siparis_id % 90) + 5) * INTERVAL '1 minute'
    FROM toplam
    WHERE siparis_id % 13 = 0
)
INSERT INTO odemeler (siparis_id, tutar, yontem, odeme_tarihi)
SELECT siparis_id,
       tutar,
       CASE siparis_id % 4
            WHEN 0 THEN 'havale'
            WHEN 3 THEN 'kapida_odeme'
            ELSE 'kredi_karti'
       END,
       odeme_tarihi
FROM parcalar
ORDER BY siparis_id, sira;

-- ---------------------------------------------------------------
-- Çalışanlar (şirketin kendi ekibi)
--   * Genel müdürün yöneticisi yok (NULL).
--   * 10 ve 11 numaralı çalışanların maaşı aynı (RANK / DENSE_RANK farkı için).
--   * 6 numaralı Dilara (kıdemli mimar) ve 15 numaralı Kaan (piyasa ücretiyle yeni
--     işe alınmış) kendi yöneticilerinden fazla kazanıyor.
-- ---------------------------------------------------------------
INSERT INTO calisanlar (calisan_id, ad, soyad, departman, yonetici_id, maas, ise_giris_tarihi) VALUES
    (1,  'Murat',   'Aksoy',    'Yönetim',            NULL, 85000.00, '2015-03-01'),
    (2,  'Selma',   'Karaca',   'Teknoloji',          1,    62000.00, '2016-06-15'),
    (3,  'Hakan',   'Tunç',     'Satış',              1,    58000.00, '2016-09-01'),
    (4,  'Nermin',  'Eren',     'İnsan Kaynakları',   1,    52000.00, '2017-01-10'),
    (5,  'Okan',    'Bozkurt',  'Teknoloji',          2,    41000.00, '2019-02-18'),
    (6,  'Dilara',  'Sezer',    'Teknoloji',          2,    64000.00, '2020-05-04'),
    (7,  'Tarık',   'Uysal',    'Teknoloji',          5,    28000.00, '2022-09-12'),
    (8,  'Pınar',   'Acar',     'Satış',              3,    34000.00, '2019-11-25'),
    (9,  'Volkan',  'Tekin',    'Satış',              3,    31000.00, '2021-03-08'),
    (10, 'Aslı',    'Güler',    'Satış',              8,    24000.00, '2023-02-20'),
    (11, 'Gökhan',  'Işık',     'Satış',              8,    24000.00, '2023-06-01'),
    (12, 'Esra',    'Kaplan',   'İnsan Kaynakları',   4,    33000.00, '2020-10-12'),
    (13, 'Berk',    'Yavuz',    'İnsan Kaynakları',   12,   22000.00, '2024-01-15'),
    (14, 'Ceren',   'Özer',     'Müşteri Hizmetleri', 3,    26000.00, '2022-04-18'),
    (15, 'Kaan',    'Ateş',     'Müşteri Hizmetleri', 14,   27500.00, '2024-03-04');

-- ---------------------------------------------------------------
-- Elle numara verdiğimiz için sequence'ları yeni kayıtlar çakışmasın diye güncelle
-- ---------------------------------------------------------------
DO $$
BEGIN
    PERFORM setval(pg_get_serial_sequence('kategoriler',        'kategori_id'), (SELECT max(kategori_id) FROM kategoriler));
    PERFORM setval(pg_get_serial_sequence('musteriler',         'musteri_id'),  (SELECT max(musteri_id)  FROM musteriler));
    PERFORM setval(pg_get_serial_sequence('urunler',            'urun_id'),     (SELECT max(urun_id)     FROM urunler));
    PERFORM setval(pg_get_serial_sequence('siparisler',         'siparis_id'),  (SELECT max(siparis_id)  FROM siparisler));
    PERFORM setval(pg_get_serial_sequence('siparis_kalemleri',  'kalem_id'),    (SELECT max(kalem_id)    FROM siparis_kalemleri));
    PERFORM setval(pg_get_serial_sequence('odemeler',           'odeme_id'),    (SELECT max(odeme_id)    FROM odemeler));
    PERFORM setval(pg_get_serial_sequence('calisanlar',         'calisan_id'),  (SELECT max(calisan_id)  FROM calisanlar));
END
$$;

ANALYZE;
