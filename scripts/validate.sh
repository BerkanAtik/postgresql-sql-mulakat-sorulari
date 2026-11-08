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
# Bilgisayarında psql kurulu değilse ama Docker varsa, betik container'ın içindeki psql'i
# kullanır (container adı KONTEYNER değişkeniyle değiştirilebilir, varsayılan sql-mulakat-db).
# Yani Docker kurulu olması yeterli, ayrıca psql kurman gerekmez.
#
# Soru dosyalarında (NN-ad.md) şunları arar:
#   - "## Çözüm" ve "## Alternatif ..." başlıklarının altındaki bütün ```sql blokları.
#     Her biri ayrı ayrı çalıştırılır, hata veren olursa test düşer.
#   - İsteğe bağlı <!-- beklenen-satir: 12 --> satırı: her bloğun döndürdüğü satır sayısı
#     bu sayıya eşit olmalı (alternatif çözümler de aynı sonucu vermek zorunda).
#   - Alternatif çözümlerin çıktısı, satır sırasından bağımsız olarak asıl çözümle (ilk blok)
#     birebir aynı olmalı. Alternatif bilerek farklı biçimde çıktı veriyorsa (örneğin tarihi
#     metin olarak gösteriyorsa) dosyaya <!-- alternatif-cikti-farkli --> ekleyin.
# "Sık yapılan hatalar" gibi diğer bölümlerdeki sql blokları çalıştırılmaz.
# Bir modül klasöründe hazirlik.sql varsa (kendi tablosunu kuran modüller), sorulardan önce
# o çalıştırılır.
# Çözümler BEGIN ... ROLLBACK içinde çalışır, veritabanı değişmez.
# Çözümün kendisi BEGIN ile başlıyorsa sarmalanmaz; bu durumda tek başına duran COMMIT
# satırları çalıştırılırken ROLLBACK'e çevrilir (çıktı COMMIT'ten önceki SELECT'ten gelmeli).

set -u

export PGHOST="${PGHOST:-localhost}"
export PGPORT="${PGPORT:-5433}"
export PGUSER="${PGUSER:-ogrenci}"
export PGPASSWORD="${PGPASSWORD:-sifre}"
export PGDATABASE="${PGDATABASE:-eticaret}"
export PGCLIENTENCODING=UTF8

KONTEYNER="${KONTEYNER:-sql-mulakat-db}"
KOK="${1:-pratik}"

# psql nerede? Önce PSQL değişkeni, sonra PATH, o da yoksa Docker container'ı.
DOCKER_PSQL=0
if [ -z "${PSQL:-}" ]; then
    if command -v psql > /dev/null 2>&1; then
        PSQL=psql
    elif command -v docker > /dev/null 2>&1; then
        DOCKER_PSQL=1
        export MSYS_NO_PATHCONV=1   # Windows'taki Git Bash argümanlardaki yolları bozmasın
    else
        PSQL=psql
    fi
fi

basarili=0
hatali=0

sql() {
    if [ "$DOCKER_PSQL" -eq 1 ]; then
        # Dosyalar ana makinede, psql container'da: "-f dosya" yerine dosyayı stdin'den veriyoruz.
        local dosya="" args=()
        while [ $# -gt 0 ]; do
            if [ "$1" = "-f" ]; then
                dosya="$2"
                shift 2
            else
                args+=("$1")
                shift
            fi
        done
        local kom=(docker exec -i -e PGCLIENTENCODING=UTF8 "$KONTEYNER" \
                   psql -U "$PGUSER" -d "$PGDATABASE" -X -q -At -v ON_ERROR_STOP=1)
        if [ -n "$dosya" ]; then
            "${kom[@]}" ${args[@]+"${args[@]}"} < "$dosya"
        else
            # /dev/null: docker, çağıran döngünün girdisini (find çıktısı) yutmasın.
            "${kom[@]}" ${args[@]+"${args[@]}"} < /dev/null
        fi
    else
        "$PSQL" -X -q -At -v ON_ERROR_STOP=1 "$@"
    fi
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

if [ "$DOCKER_PSQL" -eq 1 ]; then
    echo "== Veritabanı kontrolleri (container $KONTEYNER, $PGDATABASE)"
else
    echo "== Veritabanı kontrolleri ($PGHOST:$PGPORT/$PGDATABASE)"
fi

if ! sql -c "SELECT 1" > /dev/null 2>&1; then
    echo "HATA   Veritabanına bağlanılamadı. 'docker compose up -d' çalışıyor mu?"
    [ "$DOCKER_PSQL" -eq 1 ] && echo "         (psql bulunamadı, '$KONTEYNER' container'ındaki psql denendi)"
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

# cozumleri_ayir dosya.md hedef-klasor
# "## Çözüm" ve "## Alternatif..." bölümlerindeki sql bloklarını 1.sql, 2.sql... diye ayırır.
cozumleri_ayir() {
    awk -v hedef="$2" '
        /^## (Çözüm|Alternatif)/        { aktif = 1; next }
        !icerde && /^## /               { aktif = 0; next }
        aktif && !icerde && /^```sql/   { icerde = 1; n++; dosya = hedef "/" n ".sql"; next }
        icerde && /^```/                { icerde = 0; close(dosya); next }
        icerde                          { print > dosya }
    ' "$1"
}

echo
echo "== Soru çözümleri ($KOK)"

if [ ! -d "$KOK" ]; then
    echo "atlandı  $KOK klasörü yok"
else
    # Bazı modüller kendi tablolarını hazırlik.sql ile kuruyor, önce onları çalıştır.
    while IFS= read -r hazirlik; do
        if cikti="$(sql -f "$hazirlik" 2>&1)"; then
            tamam "$hazirlik (hazırlık)"
        else
            hata "$hazirlik (hazırlık)" "$cikti"
        fi
    done < <(find "$KOK" -type f -name 'hazirlik.sql' | sort)

    bulunan=0
    while IFS= read -r dosya; do
        bulunan=$((bulunan + 1))

        dizin="$(mktemp -d)"
        cozumleri_ayir "$dosya" "$dizin"
        blok_sayisi="$(find "$dizin" -name '*.sql' | wc -l | tr -d ' ')"

        if [ "$blok_sayisi" -eq 0 ]; then
            hata "$dosya" "'## Çözüm' başlığının altında \`\`\`sql bloğu bulunamadı"
            rm -rf "$dizin"
            continue
        fi

        beklenen="$(grep -o '<!-- beklenen-satir: [0-9]* -->' "$dosya" | head -n 1 | grep -o '[0-9][0-9]*')"
        cikti_karsilastir=1
        grep -q '<!-- alternatif-cikti-farkli -->' "$dosya" && cikti_karsilastir=0
        dosya_temiz=1
        satirlar=""

        for ((i = 1; i <= blok_sayisi; i++)); do
            cozum="$(tr -d '\r' < "$dizin/$i.sql")"
            calisma="$dizin/calis_$i.sql"

            if printf '%s' "$cozum" | grep -qiE '^[[:space:]]*(BEGIN|START[[:space:]]+TRANSACTION|COMMIT)\b'; then
                # Çözüm kendi transaction'ını açıyorsa sarmalamıyoruz, ama tek başına duran
                # COMMIT satırlarını ROLLBACK'e çeviriyoruz ki doğrulama veriyi değiştirmesin.
                { echo "SET client_min_messages = warning;"
                  printf '%s\n' "$cozum" | awk '{ if (toupper($0) ~ /^[ \t]*COMMIT[ \t]*;?[ \t]*$/) print "ROLLBACK;"; else print }'
                } > "$calisma"
            else
                # client_min_messages: "extension already exists, skipping" gibi NOTICE satırları
                # çıktıya karışıp satır sayısını bozmasın (örneğin pg_trgm daha önce kurulmuşsa).
                printf 'SET client_min_messages = warning;\nBEGIN;\n%s\nROLLBACK;\n' "$cozum" > "$calisma"
            fi

            if ! cikti="$(sql -f "$calisma" 2>&1)"; then
                hata "$dosya (blok $i)" "$cikti"
                dosya_temiz=0
                continue
            fi

            # Windows'taki psql satır sonlarına \r bırakabiliyor, karşılaştırmayı bozmasın.
            cikti="$(printf '%s' "$cikti" | tr -d '\r')"
            gelen="$(printf '%s' "$cikti" | grep -c '')"
            satirlar="$satirlar $gelen"
            if [ -n "$beklenen" ] && [ "$gelen" != "$beklenen" ]; then
                hata "$dosya (blok $i)" "beklenen satır: $beklenen, gelen: $gelen"
                dosya_temiz=0
            fi

            # Alternatifler asıl çözümle aynı veriyi döndürmeli (satır sırası önemsiz).
            printf '%s\n' "$cikti" | LC_ALL=C sort > "$dizin/cikti_$i.txt"
            if [ "$i" -gt 1 ] && [ "$cikti_karsilastir" -eq 1 ] && [ -f "$dizin/cikti_1.txt" ] \
                && ! cmp -s "$dizin/cikti_1.txt" "$dizin/cikti_$i.txt"; then
                hata "$dosya (blok $i)" "çıktısı asıl çözümden (1. blok) farklı. Bilerek farklıysa dosyaya <!-- alternatif-cikti-farkli --> ekleyin."
                dosya_temiz=0
            fi
        done

        if [ "$dosya_temiz" -eq 1 ]; then
            if [ -n "$beklenen" ]; then
                tamam "$dosya ($blok_sayisi blok, her biri $beklenen satır)"
            else
                tamam "$dosya ($blok_sayisi blok çalıştı, satırlar:$satirlar)"
            fi
        fi
        rm -rf "$dizin"
    done < <(find "$KOK" -type f -name '[0-9][0-9]-*.md' | sort)

    [ "$bulunan" -eq 0 ] && echo "atlandı  $KOK altında soru dosyası yok"
fi

echo
echo "Sonuç: $basarili başarılı, $hatali hatalı"
[ "$hatali" -eq 0 ]
