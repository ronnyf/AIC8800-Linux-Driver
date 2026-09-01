#!/bin/sh
# tests for tools/gen_version.sh; runs from the repo root
set -u
G=tools/gen_version.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
ok()   { echo "ok: $1"; }
bad()  { echo "FAIL: $1"; fails=$((fails+1)); }
# check: literal or glob match (no existing expectation carries metachars)
check() {
    case "$3" in
        $2) ok "$1";;
        *) bad "$1 (expected [$2], got [$3])";;
    esac
}
check_contains() {
    if printf '%s\n' "$3" | grep -q -- "$2"; then ok "$1"; else bad "$1"; fi
}

# 1. env override wins over everything
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G")
check "override identity" "6.4.3.0-8" "$out"
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G" --base)
check "override base" "6.4.3.0" "$out"

# 1b. one leading v normalized for all sources, both modes
out=$(RWNX_VERSION_IDENTITY=v6.4.3.0-8 sh "$G")
check "v-prefix identity" "6.4.3.0-8" "$out"
out=$(RWNX_VERSION_IDENTITY=v6.4.3.0-8 sh "$G" --base)
check "v-prefix base" "6.4.3.0" "$out"

# 1c. malformed identities rejected (quotes/garbage must not reach #defines)
if RWNX_VERSION_IDENTITY='6.4"; char x[10]={' sh "$G" >/dev/null 2>&1; then
    bad "quote identity accepted"; else ok "quote identity rejected"; fi
if RWNX_VERSION_IDENTITY=banana sh "$G" --base >/dev/null 2>&1; then
    bad "non-version base accepted"; else ok "non-version identity rejected"; fi

# 2. VERSION-file fallback in a non-git tree
mkdir -p "$T/plain/tools"
cp "$G" "$T/plain/tools/"
printf '6.4.3.0-8\n' > "$T/plain/VERSION"
out=$(sh "$T/plain/tools/gen_version.sh")
check "VERSION fallback identity" "6.4.3.0-8" "$out"
out=$(sh "$T/plain/tools/gen_version.sh" --base)
check "VERSION fallback base" "6.4.3.0" "$out"

# 2b. VERSION-only tree nested in an unrelated repo must not leak its tags
#     (fixture repos never inherit the repo-local gpgsign override; global
#     x509 signing hangs, so every git call carries the -c overrides)
O="$T/outer"; mkdir -p "$O/inner/tools"
git -C "$O" init -q
git -C "$O" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit --allow-empty -qm base
git -C "$O" -c tag.gpgsign=false tag v9.9.9.9-1
cp "$G" "$O/inner/tools/"
printf '6.4.3.0-8\n' > "$O/inner/VERSION"
out=$(sh "$O/inner/tools/gen_version.sh")
check "nested tree uses own VERSION, not outer tag" "6.4.3.0-8" "$out"

# 3. no identity source at all -> nonzero exit
mkdir -p "$T/empty/tools"
cp "$G" "$T/empty/tools/"
if sh "$T/empty/tools/gen_version.sh" >/dev/null 2>&1; then
    bad "expected failure with no identity source"; else ok "no identity source fails"; fi

# 4. git repo whose describe FAILS (no reachable tag) falls through to VERSION
R="$T/git"
mkdir -p "$R/tools"
git -C "$R" init -q
git -C "$R" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit --allow-empty -qm base
printf '6.4.3.0-8\n' > "$R/VERSION"
git -C "$R" add VERSION
git -C "$R" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit -qm "add VERSION"
cp "$G" "$R/tools/"
out=$(sh "$R/tools/gen_version.sh")
check "describe-failure falls to VERSION file" "6.4.3.0-8" "$out"

# 5. exact tag, post-tag commit, dirty tree
git -C "$R" -c tag.gpgsign=false tag v6.4.3.0-8
out=$(sh "$R/tools/gen_version.sh")
check "git describe on tag" "6.4.3.0-8" "$out"
git -C "$R" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit --allow-empty -qm bump
out=$(sh "$R/tools/gen_version.sh")
check "git describe post-tag" "6.4.3.0-8-1-g*" "$out"
echo x >> "$R/VERSION"
out=$(sh "$R/tools/gen_version.sh")
check "dirty identity" "6.4.3.0-8-1-g*-dirty" "$out"

# 6. header: macros + exact banner for a short identity
h=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G" --header)
check_contains "header MOD" '#define RWNX_VERS_MOD "6.4.3.0"' "$h"
check_contains "header banner" '#define RWNX_VERS_BANNER "rwnx 6.4.3.0-8 (vendor base 6.4.3.0, fork: ronnyf/AIC8800-Linux-Driver)"' "$h"
check_contains "header RELEASE_DATE" '#define RELEASE_DATE "' "$h"

# 6b. banner hard cap: 150-char identity, still <=127
LONG=$(printf '1.2%.0s' $(seq 50))
h=$(RWNX_VERSION_IDENTITY="$LONG" sh "$G" --header)
b=$(printf '%s\n' "$h" | sed -n 's/.*BANNER "\([^"]*\)".*/\1/p')
n=$(printf '%s' "$b" | wc -c | tr -d '[:space:]')
if [ "$n" -le 127 ]; then ok "banner length $n <= 127"; else bad "banner length $n"; fi

# 7. --base from a long (post-tag) identity
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8-3-g024df29-dirty sh "$G" --base)
check "base from long identity" "6.4.3.0" "$out"

if [ "$fails" -eq 0 ]; then echo "gen_version: all tests passed"; else
    echo "gen_version: $fails test(s) FAILED"; exit 1; fi
