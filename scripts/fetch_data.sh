#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "$0")/.." && pwd)"
data_root="$repo_root/data"
vendor="$data_root/vendor"; derived="$data_root/derived"
perseus="$vendor/perseus/iliad"; lsj="$vendor/lsj"; smyth="$vendor/smyth"; agldt="$vendor/agldt"

mkdir -p "$perseus" "$lsj" "$smyth" "$agldt" "$derived"

download_first_ok () {
  out="$1"; shift
  for url in "$@"; do
    echo "Downloading $url -> $out"
    if curl -fsSL "$url" -o "$out"; then
      [ -s "$out" ] && return 0
    fi
  done
  echo "All URLs failed for $out" >&2; exit 1
}

normalize_utf8_lf () {
  f="$1"
  # Ensure LF endings and UTF-8 (no BOM)
  awk '{printf "%s\r\n", $0}' "$f" | tr -d '\r' > "$f.tmp"
  iconv -f UTF-8 -t UTF-8 "$f.tmp" -o "$f"
  rm -f "$f.tmp"
}

# Iliad TEI
download_first_ok "$perseus/tlg0012.tlg001.perseus-grc2.xml" \
  "https://raw.githubusercontent.com/PerseusDL/canonical-greekLit/master/data/tlg0012/tlg001/tlg0012.tlg001.perseus-grc2.xml" \
  "https://raw.githubusercontent.com/OpenGreekAndLatin/First1KGreek/master/data/tlg0012/tlg001/tlg0012.tlg001.perseus-grc2.xml"
cp -f "$perseus/tlg0012.tlg001.perseus-grc2.xml" "$perseus/book1.xml"
normalize_utf8_lf "$perseus/tlg0012.tlg001.perseus-grc2.xml"

# LSJ TEI
download_first_ok "$lsj/grc.lsj.perseus-eng13.xml" \
  "https://raw.githubusercontent.com/PerseusDL/lexica/master/CTS_XML_TEI/perseus/pdllex/grc/lsj/grc.lsj.perseus-eng13.xml" \
  "https://raw.githubusercontent.com/gcelano/LSJ_GreekUnicode/master/grc.lsj.perseus-eng19.xml"
normalize_utf8_lf "$lsj/grc.lsj.perseus-eng13.xml"

# Smyth HTML
download_first_ok "$smyth/smyth.html" \
  "https://grammars.alpheios.net/smyth/xhtml/smyth.html"
normalize_utf8_lf "$smyth/smyth.html"

echo "Done."
