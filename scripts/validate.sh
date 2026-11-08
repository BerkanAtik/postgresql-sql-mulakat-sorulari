#!/usr/bin/env bash
# Örnek veritabanını ve soru dosyalarındaki çözümleri doğrular.
#
# Kullanım:
#   scripts/validate.sh                # pratik/ klasörünü tarar
#   scripts/validate.sh baska/klasor   # başka bir klasörü tarar
#
# Bağlantı ayarları ortam değişkenleriyle değiştirilebilir:
#   PGHOST, PGPORT, PGUSER, PGPASSWORD, PGDATABASE, PSQL (psql'in yolu)
# Varsayılanlar docker-compose.yml'deki değerlerle aynı.
#
# Soru dosyalarında (NN-ad.md) şunları arar:
#   - "## Çözüm" başlığından sonraki ilk ```sql bloğu: çalıştırılır, hata verirse test düşer.
#   - İsteğe bağlı <!-- beklenen-satir: 12 --> satırı: çözümün döndürdüğü satır sayısı kontrol edilir.
# Çözümler BEGIN ... ROLLBACK içinde çalışır, veritabanı değişmez.
# (Çözümün kendisi BEGIN/COMMIT içeriyorsa sarmalanmaz, o durumda dikkatli olun.)

set -u

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5433}"
export PGUSER="${PGUSER:-ogrenci}"
export PGPASSWORD="${PGPASSWORD:-sifre}"
export PGDATABASE="${PGDATABASE:-eticaret}"
export PGCLIENTENCODING=UTF8

PSQL="${PSQL:-psql}"
KOK="${1:-pratik}"

basarili=0
hatali=0

sql() {
    "$PSQL" -X -q -At -v ON_ERROR_STOP=1 "$@"
}

tamam() {
    echo "tamam  $1"
    basarili=$((basarili + 1))
}

hata() {
    echo "HATA   $1"
    [ -n "${2:-}" ] && echo "$2" | sed 's/^/         /'
    hatali=$((hatali + 1))
}

# kontrol "açıklama" "SELECT ..." "beklenen değer"
kontrol() {
    local aciklama="$1" sorgu="$2" beklenen="$3" sonuc
    if ! sonuc=$(sql -c "$sorgu" 2>&1); then
        hata "$aciklama" "$sonuc"
    elif [ "$sonuc" = "$beklenen" ]; then
        tamam "$aciklama"
    else
        hata "$aciklama" "beklenen: $beklenen, gelen: $sonuc"
    fi
}

echo "== Veritabanı kontrolleri ($PGHOST:$PGPORT/$PGDATABASE)"

if ! sql -c "SELECT 1" > /dev/null 2>&1; then
    echo "HATA   Veritabanına bağlanılamadı. 'docker compose up -d' çalışıyor mu?"
    exit 1
fi

kontrol "kategoriler: 18 satır"        "SELECT count(*) FROM kategoriler"       "18"
kontrol "musteriler: 200 satır"        "SELECT count(*) FROM musteriler"        "200"
kontrol "urunler: 50 satır"            "SELECT count(*) FROM urunler"           "50"
kontrol "siparisler: 1000 satır"       "SELECT count(*) FROM siparisler"        "1000"
kontrol "siparis_kalemleri: 2500 satır" "SELECT count(*) FROM siparis_kalemleri" "2500"
kontrol "odemeler: 962 satır"          "SELECT count(*) FROM odemeler"          "962"
kontrol "calisanlar: 15 satır"         "SELECT count(*) FROM calisanlar"        "15"

kontrol "hiç sipariş vermeyen müşteri: 20" \
    "SELECT count(*) FROM musteriler m WHERE NOT EXISTS (SELECT 1 FROM siparisler s WHERE s.musteri_id = m.musteri_id)" \
    "20"

kontrol "hiç satılmayan ürün: 4 (47-50)" \
    "SELECT string_agg(urun_id::text, ',' ORDER BY urun_id) FROM urunler u WHERE NOT EXISTS (SELECT 1 FROM siparis_kalemleri k WHERE k.urun_id = u.urun_id)" \
    "47,48,49,50"

kontrol "en çok satan ürün: 46 numaralı, 346 adet" \
    "SELECT urun_id || ':' || sum(adet) FROM siparis_kalemleri GROUP BY urun_id ORDER BY sum(adet) DESC, urun_id LIMIT 1" \
    "46:346"

kontrol "en yüksek cirolu ürün: 5 numaralı" \
    "SELECT urun_id FROM siparis_kalemleri GROUP BY urun_id ORDER BY sum(adet * birim_fiyat) DESC LIMIT 1" \
    "5"

kontrol "ödeme tutarı ile kalem toplamı her siparişte tutuyor" \
    "SELECT count(*) FROM (
         SELECT s.siparis_id,
                (SELECT sum(adet * birim_fiyat) FROM siparis_kalemleri k WHERE k.siparis_id = s.siparis_id) AS kalem,
                (SELECT sum(tutar) FROM odemeler o WHERE o.siparis_id = s.siparis_id) AS odeme
         FROM siparisler s
         WHERE s.durum IN ('tamamlandi', 'kargoda', 'iade')
     ) t WHERE kalem IS DISTINCT FROM odeme" \
    "0"

kontrol "iptal ve beklemedeki siparişlerin ödemesi yok" \
    "SELECT count(*) FROM odemeler o JOIN siparisler s USING (siparis_id) WHERE s.durum IN ('iptal', 'beklemede')" \
    "0"

kontrol "kayıt tarihinden önce sipariş veren müşteri yok" \
    "SELECT count(*) FROM musteriler m JOIN siparisler s USING (musteri_id) WHERE s.siparis_tarihi::date < m.kayit_tarihi" \
    "0"

# ---------------------------------------------------------------
# Soru dosyalarındaki çözümler
# ---------------------------------------------------------------
cozum_cikar() {
    awk '
        /^## Çözüm/                    { aktif = 1; next }
        aktif && !icerde && /^## /     { exit }
        aktif && !icerde && /^```sql/  { icerde = 1; next }
        aktif && icerde  && /^```/     { exit }
        aktif && icerde                { print }
    ' "$1"
}

echo
echo "== Soru çözümleri ($KOK)"

if [ ! -d "$KOK" ]; then
    echo "atlandı  $KOK klasörü yok"
else
    bulunan=0
    while IFS= read -r dosya; do
        bulunan=$((bulunan + 1))
        cozum="$(cozum_cikar "$dosya" | tr -d '\r')"

        if [ -z "$cozum" ]; then
            hata "$dosya" "'## Çözüm' başlığının altında \`\`\`sql bloğu bulunamadı"
            continue
        fi

        gecici="$(mktemp)"
        if printf '%s' "$cozum" | grep -qiE '^[[:space:]]*(BEGIN|START[[:space:]]+TRANSACTION|COMMIT)\b'; then
            printf '%s\n' "$cozum" > "$gecici"
        else
            printf 'BEGIN;\n%s\nROLLBACK;\n' "$cozum" > "$gecici"
        fi

        if ! cikti="$(sql -f "$gecici" 2>&1)"; then
            hata "$dosya" "$cikti"
            rm -f "$gecici"
            continue
        fi
        rm -f "$gecici"

        beklenen="$(grep -o '<!-- beklenen-satir: [0-9]* -->' "$dosya" | head -n 1 | grep -o '[0-9][0-9]*')"
        if [ -n "$beklenen" ]; then
            gelen="$(printf '%s' "$cikti" | grep -c '')"
            if [ "$gelen" = "$beklenen" ]; then
                tamam "$dosya ($gelen satır)"
            else
                hata "$dosya" "beklenen satır: $beklenen, gelen: $gelen"
            fi
        else
            tamam "$dosya (çalıştı)"
        fi
    done < <(find "$KOK" -type f -name '[0-9][0-9]-*.md' | sort)

    [ "$bulunan" -eq 0 ] && echo "atlandı  $KOK altında soru dosyası yok"
fi

echo
echo "Sonuç: $basarili başarılı, $hatali hatalı"
[ "$hatali" -eq 0 ]
