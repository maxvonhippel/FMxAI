#!/usr/bin/env bash
# Full verification run: escape-hatch audit, build, tests, independent kernel re-check.
set -euo pipefail
cd "$(dirname "$0")/.."

echo "== escape-hatch audit"
banned='partial def|partial instance|noncomputable|unsafe|implemented_by|native_decide|sorry|^axiom |opaque'
if find Fmxai -name '*.lean' -print0 | xargs -0 cat Main.lean Test.lean Fmxai.lean \
    | sed -e 's/--.*$//' \
    | awk 'BEGIN{skip=0} /\/-/{skip=1} skip==0{print} /-\//{skip=0}' \
    | grep -nE "$banned"; then
  echo "error: banned escape hatch found" >&2
  exit 1
fi
echo "ok: no partial, noncomputable, unsafe, implemented_by, native_decide, sorry, axiom or opaque"

echo "== build"
lake build

echo "== tests and axiom audit"
lake build Test

echo "== independent kernel re-check (leanchecker, from oleans)"
lake env leanchecker Sites Fmxai

echo "== the site builds"
.lake/build/bin/fmxai build dist >/dev/null
test -f dist/index.html && test -f dist/map/index.html && test -f dist/CNAME
echo "all checks passed"
