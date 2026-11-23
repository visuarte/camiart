#!/usr/bin/env bash
# RECORTA LOS ICONOS — deja en src/app/fonts el subconjunto de Material Symbols que usa la web.
#
# Por qué: la fuente completa pesa 3,8 MB y venía de Google. Con los iconos que usamos
# de verdad son ~22 KB y se sirven desde el repo (src/app/material-symbols.css).
#
# Qué hace:
#   1. busca los nombres de icono en el código (spans .material-symbols-outlined y `icon: '...'`)
#   2. descarga la fuente variable completa de Google a un temporal
#   3. calcula con HarfBuzz qué glifo produce cada nombre (hay nombres que no coinciden con
#      su glifo: "business" -> "domain", "location_on" -> "place")
#   4. recorta con pyftsubset y COMPRUEBA que los 21+ nombres siguen ligando a un solo glifo
#
# Uso:  scripts/subset-iconos.sh
# Necesita: python3 con fonttools, brotli y uharfbuzz
#           (python3 -m venv /tmp/venv && /tmp/venv/bin/pip install fonttools brotli uharfbuzz)
set -euo pipefail

RAIZ="$(cd "$(dirname "$0")/.." && pwd)"
PY="${PY_SUBSET:-python3}"
FUENTE="https://fonts.gstatic.com/s/materialsymbolsoutlined/v385/kJEhBvYX7BgnkSrUwT8OhrdQw4oELdPIeeII9v6oFsLjBuVY.woff2"
SALIDA="$RAIZ/src/app/fonts/MaterialSymbolsOutlined-subset.woff2"
UA="Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/104.0.0.0 Safari/537.36"
TMP="$(mktemp -d)"; trap 'rm -rf "$TMP"' EXIT

# 1. nombres usados
{
  grep -rho '<span className="material-symbols-outlined[^>]*>[a-z_0-9]*<' "$RAIZ/src" \
    | sed -E 's/.*>([a-z_0-9]*)<$/\1/'
  grep -rho "icon: '[a-z_0-9]*'" "$RAIZ/src" | sed -E "s/icon: '([a-z_0-9]*)'/\1/"
} | grep -v '^$' | sort -u > "$TMP/nombres.txt"

echo "iconos detectados: $(wc -l < "$TMP/nombres.txt" | tr -d ' ')"

# 2. fuente completa
curl -s -A "$UA" -o "$TMP/full.woff2" "$FUENTE"

# 3-4. glifos, subconjunto y comprobación
"$PY" - "$TMP" "$SALIDA" "$RAIZ" <<'PY'
import subprocess, sys, os
import uharfbuzz as hb
from fontTools.ttLib import TTFont

tmp, salida, raiz = sys.argv[1:4]
full = os.path.join(tmp, 'full.woff2')
nombres = open(os.path.join(tmp, 'nombres.txt')).read().split()

f = TTFont(full); f.flavor = None; ttf = os.path.join(tmp, 'full.ttf'); f.save(ttf)
go = TTFont(ttf).getGlyphOrder()
font = hb.Font(hb.Face(open(ttf, 'rb').read()))

def liga(nombre, font=font):
    buf = hb.Buffer(); buf.add_str(nombre); buf.guess_segment_properties()
    hb.shape(font, buf)
    return [go[i.codepoint] for i in buf.glyph_infos]

glifos = sorted({g for n in nombres for g in liga(n)})
print('glifos implicados:', len(glifos))

subprocess.run([
    'pyftsubset', full,
    '--text=' + ' '.join(nombres),
    '--glyphs=' + ','.join(glifos),
    '--layout-features=rclt,rlig',
    '--no-layout-closure',
    '--flavor=woff2',
    '--output-file=' + salida,
], check=True)

# comprobación sobre el recortado
s = TTFont(salida); s.flavor = None; sttf = os.path.join(tmp, 'sub.ttf'); s.save(sttf)
sgo = TTFont(sttf).getGlyphOrder()
sfont = hb.Font(hb.Face(open(sttf, 'rb').read()))
malos = []
for n in nombres:
    g = liga(n, sfont)
    if len(g) != 1 or g[0] == '.notdef':
        malos.append(n)

kb = os.path.getsize(salida) // 1024
print(f'subconjunto: {kb} KB -> {salida}')
if malos:
    print('❌ estos iconos NO ligan en el recortado:', ', '.join(malos))
    sys.exit(1)
print(f'✅ los {len(nombres)} iconos ligan a un solo glifo')
PY
