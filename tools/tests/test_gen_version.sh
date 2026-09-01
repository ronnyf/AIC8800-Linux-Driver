#!/bin/sh
# Tests for tools/gen_version.sh. Runs from the repo root.
set -u
G=tools/gen_version.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
ok()   { echo "ok: $1"; }
bad()  { echo "FAIL: $1"; fails=$((fails+1)); }
check() { # check <desc> <expected> <actual>
    if [ "$2" = "$3" ]; then ok "$1"; else bad "$1 (expected [$2], got [$3])"; fi
}

# 1. Env override wins over everything.
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G")
check "override identity" "6.4.3.0-8" "$out"
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G" --base)
check "override base" "6.4.3.0" "$out"

# 2. VERSION-file fallback in a non-git tree.
mkdir -p "$T/plain/tools"
cp "$G" "$T/plain/tools/"
printf '6.4.3.0-8\n' > "$T/plain/VERSION"
out=$(sh "$T/plain/tools/gen_version.sh")
check "VERSION fallback identity" "6.4.3.0-8" "$out"
out=$(sh "$T/plain/tools/gen_version.sh" --base)
check "VERSION fallback base" "6.4.3.0" "$out"

# 3. No identity source at all -> nonzero exit.
mkdir -p "$T/empty/tools"
cp "$G" "$T/empty/tools/"
if sh "$T/empty/tools/gen_version.sh" >/dev/null 2>&1; then
    bad "expected failure with no identity source"
else
    ok "no identity source fails"
fi

# 4. git describe: a git repo whose describe FAILS (no reachable tag) must
#    fall through to the VERSION file, not error on .git presence.
#    -c commit.gpgsign=false: these fixture repos do NOT inherit the
#    repo-local override, and the global config's x509 signing hangs.
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

# 5. git describe: exact tag, post-tag commit, dirty tree.
git -C "$R" tag v6.4.3.0-8
out=$(sh "$R/tools/gen_version.sh")
check "git describe on tag" "6.4.3.0-8" "$out"
git -C "$R" -c user.email=t@example.com -c user.name=t -c commit.gpgsign=false commit --allow-empty -qm bump
out=$(sh "$R/tools/gen_version.sh")
case "$out" in
    6.4.3.0-8-1-g*) ok "git describe post-tag: $out" ;;
    *) bad "git describe post-tag (got [$out])" ;;
esac
echo x >> "$R/VERSION"
out=$(sh "$R/tools/gen_version.sh")
case "$out" in
    6.4.3.0-8-1-g*-dirty) ok "dirty identity: $out" ;;
    *) bad "dirty identity (got [$out])" ;;
esac

# 6. Header output: macros, exact banner for a short identity, 128-byte cap.
h=$(RWNX_VERSION_IDENTITY=6.4.3.0-8 sh "$G" --header)
echo "$h" | grep -q '#define RWNX_VERS_MOD "6.4.3.0"' \
    && ok "header MOD" || bad "header MOD"
echo "$h" | grep -q '#define RWNX_VERS_BANNER "rwnx 6.4.3.0-8 (vendor base 6.4.3.0, fork: ronnyf/AIC8800-Linux-Driver)"' \
    && ok "header banner" || bad "header banner"
echo "$h" | grep -q '#define RELEASE_DATE "' \
    && ok "header RELEASE_DATE" || bad "header RELEASE_DATE"
b=$(echo "$h" | sed -n 's/.*BANNER "\([^"]*\)".*/\1/p')
n=$(printf '%s' "$b" | wc -c | tr -d '[:space:]')
if [ "$n" -le 127 ]; then ok "banner length $n <= 127"; else bad "banner length $n"; fi

# 7. --base against long (post-tag) identities still yields the 4-part base.
out=$(RWNX_VERSION_IDENTITY=6.4.3.0-8-3-g024df29-dirty sh "$G" --base)
check "base from long identity" "6.4.3.0" "$out"

if [ "$fails" -eq 0 ]; then echo "gen_version: all tests passed"; else
    echo "gen_version: $fails test(s) FAILED"; exit 1; fi
