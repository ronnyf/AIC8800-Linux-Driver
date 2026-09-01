# Release Pipeline & Versioning Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make every `v*` tag release produce an Arch `.pkg.tar.zst`, an Ubuntu/Debian `.deb` (+ native `.dsc` + tarball source trio), the curated source tarball, and the Pages pacman repo — with one verified version that cannot drift.

**Architecture:** A top-level `VERSION` file is the single source of truth; `tools/check_release_version.sh` gates the release workflow (tag == VERSION == PKGBUILD == debian/changelog == dkms.conf baseline). The committed `rwnx_version_gen.h` files become build-time generated (identity: `$RWNX_VERSION_IDENTITY` → `git describe --tags` → `VERSION` file). The pipeline is three jobs in `release.yml`: `release` (Arch, existing, hardens), `ubuntu-package` (new, hand-written `debian/` tree, **`3.0 (native)`**, no debhelper), and `publish-repo` (Pages, existing, consumes Arch assets only).

**Tech Stack:** POSIX sh, GNU make / kbuild, GitHub Actions (archlinux + ubuntu-latest), makepkg, dpkg-source/dpkg-buildpackage (native), lintian (report-only).

**Spec:** `docs/specs/2026-08-31-release-pipeline-and-versioning.md` (approved, then revised by adversarial review — this plan follows the **revised** spec: native format, `debian/prerm`, dkms.conf gate, `append_body` notes, `publish-repo` decoupled).

**Environment notes for the executor:**
- **GPG signing:** this machine's *global* git config has `commit.gpgsign=true` (x509 via `ac-sign`), which **hangs non-interactive commits indefinitely**. This repo therefore carries `commit.gpgsign=false` in its *local* config (already set; re-apply idempotently on a fresh checkout: `git config --local commit.gpgsign false`). Repo-local config does NOT propagate to the throwaway git repos the tests create in `$TMPDIR` — every `git commit` in test fixtures below therefore carries `-c commit.gpgsign=false`. Never "fix" this by editing the global config.
- **Execution deviation (2026-09-01, user instruction):** work happens on branch `release-pipeline-and-versioning` with **PR #30** as the push gate instead of direct `main` commits — every task commit lands on the branch and is pushed to the PR; local `main` stays at `origin/main`. This replaces the "work on `main`" convention below and re-scopes Task 9 (PR #30 going green replaces the direct `main` push; see Task 9). Task 10's tag push is unchanged and still needs its own explicit confirmation.
- Remote pushes require explicit user confirmation (Task 8 is local-only; the gates are the PR push flow and Task 10). Before the first commit, run `git config --local commit.gpgsign false` (idempotent).
- Test scripts are POSIX sh (macOS `/bin/sh`-safe, no bashisms). Runner: `sh tools/tests/run.sh`, invoked from anywhere (it cds to the repo root).
- `docker` binary exists on this Mac but the daemon may be down. Only Task 5 uses it, conditionally; the CI `ubuntu-package` job is the authoritative Debian test.
- Existing releases `v6.4.3.0-3` … `v6.4.3.0-7` must keep working; the Pages repo rebuilds from whatever releases exist.

---

### Task 1: `tools/gen_version.sh` — build-identity generator (TDD)

**Files:**
- Create: `tools/tests/run.sh`
- Create: `tools/tests/test_gen_version.sh`
- Create: `tools/gen_version.sh`

- [x] **Step 1: Write the test runner + failing tests**

`tools/tests/run.sh`:
```sh
#!/bin/sh
# Run all tools/tests/test_*.sh. Cds to the repo root first.
set -u
cd "$(dirname "$0")/../.."
status=0
for t in tools/tests/test_*.sh; do
    echo "== $t"
    if ! sh "$t"; then status=1; fi
done
[ "$status" -eq 0 ] && echo "ALL TESTS PASSED"
exit "$status"
```

`tools/tests/test_gen_version.sh`:
```sh
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
```

- [x] **Step 2: Run tests, verify they fail**

Run: `sh tools/tests/run.sh`
Expected: every gen_version case `FAIL`s (no script yet), nonzero exit.

- [x] **Step 3: Implement `tools/gen_version.sh`**

```sh
#!/bin/sh
# Print the build identity of the AIC8800 driver fork.
#
# Identity chain (first hit wins; a failed git describe falls THROUGH, it does
# not error just because .git exists):
#   1. $RWNX_VERSION_IDENTITY       (exported by CI from the release tag)
#   2. git describe --tags [dirty]  (only when it actually succeeds)
#   3. $ROOT/VERSION                (release tarball / DKMS tree)
#
# Modes:
#   (none)      print the identity string, e.g. 6.4.3.0-8
#   --base      print the vendor baseline, e.g. 6.4.3.0
#   --header    print the rwnx_version_gen.h content on stdout
#
# ROOT is derived from this script's own location, so it works from the git
# repo (tools/ at repo root) and from a staged/DKMS tree (tools/ at root).
set -eu

MODE="${1:-identity}"
case "$MODE" in
    identity|--base|--header) ;;
    *) echo "usage: $0 [identity|--base|--header]" >&2; exit 2 ;;
esac

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)

identity=""
if [ -n "${RWNX_VERSION_IDENTITY:-}" ]; then
    identity="$RWNX_VERSION_IDENTITY"
elif V=$(git -C "$ROOT" describe --tags --dirty 2>/dev/null); then
    identity="${V#v}"
elif [ -f "$ROOT/VERSION" ]; then
    identity=$(tr -d '[:space:]' < "$ROOT/VERSION")
fi
if [ -z "$identity" ]; then
    echo "ERROR: no build identity. Set RWNX_VERSION_IDENTITY, build in a git" \
         "repository with a reachable v<version> tag, or provide $ROOT/VERSION" >&2
    exit 1
fi

# Vendor baseline = identity up to (not including) the first "-<N>" fork
# revision, stable across release, post-tag, and dirty identities alike, and
# agnostic to how many dotted components the vendor baseline itself has (it
# has been four so far; check_release_version.sh's dkms.conf check uses this
# same "strip from the first hyphen" rule, so the two stay in lockstep if
# AICSemi ever ships a differently-shaped version).
base="${identity#v}"
base="${base%%-*}"
if [ -z "$base" ]; then
    echo "ERROR: cannot parse vendor baseline from identity '$identity'" >&2
    exit 1
fi

case "$MODE" in
    identity) printf '%s\n' "$identity" ;;
    --base)   printf '%s\n' "$base" ;;
    --header)
        GITHASH=$(git -C "$ROOT" rev-parse --short=7 HEAD 2>/dev/null || echo nogit)
        RELEASE_DATE="$(date -u +%Y_%m%d)_${GITHASH}"
        BANNER="rwnx ${identity} (vendor base ${base}, fork: ronnyf/AIC8800-Linux-Driver)"
        # The vendor command copies the banner into char[128] (aic_vendor.c);
        # never emit one it cannot hold.
        if [ "$(printf '%s' "$BANNER" | wc -c | tr -d '[:space:]')" -ge 128 ]; then
            BANNER="rwnx ${base} (vendor base ${base}, fork: ronnyf/AIC8800-Linux-Driver)"
        fi
        cat <<EOF
/* Generated by tools/gen_version.sh - do not edit, do not commit. */
#define RWNX_VERS_MOD "${base}"
#define RWNX_VERS_BANNER "${BANNER}"
#define RELEASE_DATE "${RELEASE_DATE}"
EOF
        ;;
esac
```

- [x] **Step 4: Run tests, verify they pass**

Run: `sh tools/tests/run.sh`
Expected: all `ok:` lines, `gen_version: all tests passed`, `ALL TESTS PASSED`, exit 0.

- [x] **Step 5: Commit**

```bash
git add tools/gen_version.sh tools/tests/run.sh tools/tests/test_gen_version.sh
git commit -m "tools: add gen_version.sh build-identity generator with tests"
```

---

### Task 2: Wire version generation into kbuild; drop the committed headers

**Files:**
- Modify: `drivers/aic8800/Makefile`
- Modify: `drivers/aic8800/aic8800_fdrv/Makefile:6,351`
- Modify: `drivers/aic8800/aic_load_fw/Makefile:63`
- Delete: `drivers/aic8800/aic8800_fdrv/rwnx_version_gen.h`
- Delete: `drivers/aic8800/aic_load_fw/rwnx_version_gen.h`
- Modify: `.gitignore`

- [ ] **Step 1: Add the generator target to `drivers/aic8800/Makefile`**

It MUST be a prerequisite of `modules` (not just `all`): `build.yml` runs `make ... modules` directly, bypassing `all`.

Change:
```make
all: modules
modules:
```
to:
```make
all: modules
# Generate rwnx_version_gen.h for both modules before any compilation.
# Hangs off modules (not just all) because CI invokes `make ... modules`
# directly. Content-based: the header is rewritten only when it changes, so
# incremental builds do not churn.
modules: version-header
```
Append at end of file:
```make

# Generate rwnx_version_gen.h for both modules. The script finds its own root
# (VERSION file / git repo) from its own path; both layout variants are handled:
# in the git repo the script is at $(MAKEFILE_DIR)../../tools/ (this Makefile
# lives at <root>/drivers/aic8800/), in a staged tree / DKMS build dir (where
# this Makefile is installed at the tree's own root) at $(MAKEFILE_DIR)tools/.
version-header: FORCE
	@gen=$(wildcard $(MAKEFILE_DIR)tools/gen_version.sh); \
	if [ -z "$$gen" ]; then gen=$(wildcard $(MAKEFILE_DIR)../../tools/gen_version.sh); fi; \
	if [ -z "$$gen" ]; then \
	  echo "ERROR: tools/gen_version.sh not found - incomplete source tree" >&2; \
	  exit 1; \
	fi; \
	for m in aic_load_fw aic8800_fdrv; do \
	  h="$(MAKEFILE_DIR)$$m/rwnx_version_gen.h"; \
	  if ! sh "$$gen" --header > "$$h.tmp"; then \
	    rm -f "$$h.tmp"; exit 1; \
	  fi; \
	  if cmp -s "$$h" "$$h.tmp" 2>/dev/null; then \
	    rm -f "$$h.tmp"; \
	  else \
	    mv "$$h.tmp" "$$h"; echo "  GEN     $$m/rwnx_version_gen.h"; \
	  fi; \
	done

FORCE:
```
Update the existing `.PHONY` line to:
```make
.PHONY: modules install_modules uninstall_modules version-header
```

- [ ] **Step 2: Remove dead variable; extend clean targets**

`drivers/aic8800/aic8800_fdrv/Makefile`: delete line 6 (`RWNX_VERS_NUM := 6.4.3.0`) and its dangling blank line. Change `clean:` to append the generated header:
```make
clean:
	rm -rf *.o *.ko *.o.* *.mod.* modules.* Module.* .a* .o* .*.o.* *.mod .tmp* .cache.mk .modules.order.cmd .Module.symvers.cmd rwnx_version_gen.h rwnx_version_gen.h.tmp
```
`drivers/aic8800/aic_load_fw/Makefile` `clean:` (line 63): append the same two file names to its `rm -rf` list.

- [ ] **Step 3: Remove the committed headers; ignore the generated ones**

```bash
git rm drivers/aic8800/aic8800_fdrv/rwnx_version_gen.h drivers/aic8800/aic_load_fw/rwnx_version_gen.h
```
Append to `.gitignore`:
```
# Generated at build time (make version-header, see drivers/aic8800/Makefile)
drivers/aic8800/aic_load_fw/rwnx_version_gen.h
drivers/aic8800/aic8800_fdrv/rwnx_version_gen.h
```

- [ ] **Step 4: Verify generation locally (no kernel needed)**

Run: `make -C drivers/aic8800 version-header`
Expected: two `GEN` lines.

Run it again; expected: NO `GEN` lines (content unchanged → no rewrite).

Run: `head -4 drivers/aic8800/aic8800_fdrv/rwnx_version_gen.h`
Expected: generated comment, `#define RWNX_VERS_MOD "6.4.3.0"`, banner with the local `git describe` identity.

Run: `cc -fsyntax-only -x c drivers/aic8800/aic8800_fdrv/rwnx_version_gen.h && cc -fsyntax-only -x c drivers/aic8800/aic_load_fw/rwnx_version_gen.h`
Expected: exit 0 for both.

Run: `sh tools/tests/run.sh` — expected: still green.

Also prove the *other* layout branch (the one every real install actually
uses): `T=$(mktemp -d) && mkdir -p "$T/tools" "$T/aic8800_fdrv" "$T/aic_load_fw" && cp tools/gen_version.sh "$T/tools/" && cp drivers/aic8800/Makefile "$T/" && echo 6.4.3.0-8 > "$T/VERSION" && make -C "$T" version-header && rm -rf "$T"`
Expected: two `GEN` lines (the staged/DKMS-tree branch, `$(MAKEFILE_DIR)tools/...`,
is otherwise never exercised by any task).

- [ ] **Step 5: Commit**

```bash
git add drivers/aic8800/Makefile drivers/aic8800/aic8800_fdrv/Makefile drivers/aic8800/aic_load_fw/Makefile .gitignore
git commit -m "build: generate rwnx_version_gen.h at build time, drop dead RWNX_VERS_NUM"
```

---

### Task 3: `tools/check_release_version.sh` — the release version gate (TDD)

**Files:**
- Create: `tools/check_release_version.sh`
- Create: `tools/tests/test_check_release_version.sh`

Note: the gate covers **five** sources of truth — `VERSION`, `PKGBUILD` (pkgver+pkgrel), `debian/changelog` top entry, and `dkms.conf` `PACKAGE_VERSION` (baseline component).

- [ ] **Step 1: Write the failing test**

`tools/tests/test_check_release_version.sh`:
```sh
#!/bin/sh
# Fixture tests for tools/check_release_version.sh. Each fixture is a fake
# repo root; the script is copied INTO the fixture because it resolves its
# root from its own location (scripts live in tools/, root is one level up).
set -u
C=tools/check_release_version.sh
T=$(mktemp -d)
trap 'rm -rf "$T"' EXIT
fails=0
ok()  { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails+1)); }

mkfixture() { # <dir> <version|-> <pkgver> <pkgrel> <changelog|-> <dkmsbase|->
    d="$1"; mkdir -p "$d/debian"
    [ "$2" = "-" ] || printf '%s\n' "$2" > "$d/VERSION"
    printf 'pkgname=aic8800-fdrv-dkms\npkgver=%s\npkgrel=%s\n' "$3" "$4" > "$d/PKGBUILD"
    [ "$5" = "-" ] || printf 'aic8800-fdrv-dkms (%s) unstable; urgency=medium\n\n  * x\n\n -- T <t@t>  Sun, 01 Jan 2026 00:00:00 +0000\n' "$5" > "$d/debian/changelog"
    [ "$6" = "-" ] || printf 'PACKAGE_VERSION="%s"\n' "$6" > "$d/dkms.conf"
}
run_in() {
    # The script resolves ROOT as dirname($0)/.. , so it must sit one level
    # below the fixture root (tools/), exactly like the real repo layout.
    d="$1"; mkdir -p "$d/tools"; cp "$C" "$d/tools/"
    OUT=$(sh "$d/tools/check_release_version.sh" "$2" 2>&1); RC=$?
}

# 1. Fully consistent state passes (baseline 6.4.3.0 across VERSION+dkms.conf).
mkfixture "$T/cons" "6.4.3.0-8" "6.4.3.0" "8" "6.4.3.0-8" "6.4.3.0"
run_in "$T/cons" "6.4.3.0-8"
if [ "$RC" -eq 0 ]; then ok "consistent passes"; else bad "consistent: $OUT"; fi

# 2. VERSION mismatch.
mkfixture "$T/vm" "6.4.3.0-7" "6.4.3.0" "8" "6.4.3.0-8" "6.4.3.0"
run_in "$T/vm" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "VERSION file is"; } \
    && ok "VERSION mismatch" || bad "VERSION mismatch (rc=$RC): $OUT"

# 3. pkgrel mismatch.
mkfixture "$T/rel" "6.4.3.0-8" "6.4.3.0" "5" "6.4.3.0-8" "6.4.3.0"
run_in "$T/rel" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "pkgrel"; } \
    && ok "pkgrel mismatch" || bad "pkgrel mismatch (rc=$RC): $OUT"

# 4. pkgver mismatch.
mkfixture "$T/ver" "6.4.3.0-8" "6.4.3.1" "8" "6.4.3.0-8" "6.4.3.1"
run_in "$T/ver" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "pkgver"; } \
    && ok "pkgver mismatch" || bad "pkgver mismatch (rc=$RC): $OUT"

# 5. changelog mismatch.
mkfixture "$T/cl" "6.4.3.0-8" "6.4.3.0" "8" "6.4.3.0-7" "6.4.3.0"
run_in "$T/cl" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "changelog"; } \
    && ok "changelog mismatch" || bad "changelog mismatch (rc=$RC): $OUT"

# 6. missing VERSION file.
mkfixture "$T/nv" "-" "6.4.3.0" "8" "6.4.3.0-8" "6.4.3.0"
run_in "$T/nv" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "VERSION file"; } \
    && ok "missing VERSION" || bad "missing VERSION (rc=$RC): $OUT"

# 7. dkms.conf baseline mismatch (dkms.conf says 6.4.3.1, VERSION baseline 6.4.3.0).
mkfixture "$T/dk" "6.4.3.0-8" "6.4.3.0" "8" "6.4.3.0-8" "6.4.3.1"
run_in "$T/dk" "6.4.3.0-8"
{ [ "$RC" -ne 0 ] && echo "$OUT" | grep -q "PACKAGE_VERSION"; } \
    && ok "dkms.conf baseline mismatch" || bad "dkms.conf (rc=$RC): $OUT"

# 8. revision-less version (baseline change): pkgrel defaults to 1, dkms.conf baseline = full version.
mkfixture "$T/norev" "6.5.0" "6.5.0" "1" "6.5.0" "6.5.0"
run_in "$T/norev" "6.5.0"
if [ "$RC" -eq 0 ]; then ok "revision-less passes"; else bad "revision-less: $OUT"; fi

if [ "$fails" -eq 0 ]; then echo "check_release_version: all tests passed"; else
    echo "check_release_version: $fails test(s) FAILED"; exit 1; fi
```

- [ ] **Step 2: Run tests, verify they fail**

Run: `sh tools/tests/run.sh`
Expected: new file's cases all `FAIL` (no script yet), exit 1.

- [ ] **Step 3: Implement `tools/check_release_version.sh`**

```sh
#!/bin/sh
# Release version gate. Argument = version implied by the pushed tag
# (tag "v6.4.3.0-8" -> "6.4.3.0-8"). Fails if ANY in-repo manifest disagrees:
#   VERSION file                      == $1
#   PKGBUILD pkgver / pkgrel          == $1   (dash splits ver/rel; no dash => rel 1)
#   debian/changelog top entry        == $1
#   dkms.conf PACKAGE_VERSION         == baseline($1)   (strip trailing -<digits>)
# Failing here is the point: it makes tag/manifest drift unshippable.
set -eu

EXPECTED="${1:-}"
if [ -z "$EXPECTED" ]; then
    echo "usage: check_release_version.sh <version>" >&2
    echo "       e.g. check_release_version.sh 6.4.3.0-8" >&2
    exit 2
fi

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
cd "$ROOT"

fail() {
    echo "VERSION MISMATCH: $*" >&2
    exit 1
}

[ -f VERSION ] || fail "no VERSION file at repo root - add it with the release version (e.g. 6.4.3.0-8) in the release PR"
VFILE=$(tr -d '[:space:]' < VERSION)
[ -n "$VFILE" ] || fail "VERSION file is empty"
[ "$VFILE" = "$EXPECTED" ] || fail "VERSION file is '$VFILE' but the tag says '$EXPECTED' - bump VERSION in the release PR"

case "$EXPECTED" in
    *-*) PKGVER="${EXPECTED%-*}"; PKGREL="${EXPECTED##*-}" ;;
    *)   PKGVER="$EXPECTED";      PKGREL="1" ;;
esac

BPKGVER=$(sed -n 's/^pkgver=//p' PKGBUILD | head -n1)
BPKGREL=$(sed -n 's/^pkgrel=//p' PKGBUILD | head -n1)
[ "$BPKGVER" = "$PKGVER" ] || fail "PKGBUILD pkgver is '$BPKGVER', expected '$PKGVER'"
[ "$BPKGREL" = "$PKGREL" ] || fail "PKGBUILD pkgrel is '$BPKGREL', expected '$PKGREL'"

CVER=$(sed -n 's/^[^(]*(\([^)]*\)).*/\1/p' debian/changelog | head -n1)
[ -n "$CVER" ] || fail "debian/changelog has no parseable version header"
[ "$CVER" = "$EXPECTED" ] || fail "debian/changelog top entry is '$CVER', expected '$EXPECTED'"

DBASE=$(sed -n 's/^PACKAGE_VERSION=.//p' dkms.conf | head -n1 | tr -d '"[:space:]')
BASELINE=$(printf '%s' "$EXPECTED" | sed 's/-[0-9][0-9]*$//')
[ -n "$DBASE" ] || fail "dkms.conf has no parseable PACKAGE_VERSION"
[ "$DBASE" = "$BASELINE" ] || fail "dkms.conf PACKAGE_VERSION is '$DBASE', expected baseline '$BASELINE'"

echo "version consistent: $EXPECTED (VERSION, PKGBUILD $PKGVER-$PKGREL, debian/changelog, dkms.conf $BASELINE)"
```

- [ ] **Step 4: Run tests, verify they pass**

Run: `sh tools/tests/run.sh`
Expected: all test files green, `ALL TESTS PASSED`.

- [ ] **Step 5: Commit**

```bash
git add tools/check_release_version.sh tools/tests/test_check_release_version.sh
git commit -m "tools: add release version gate (VERSION/PKGBUILD/changelog/dkms.conf consistency)"
```

---

### Task 4: `tools/stage-release.sh` — the curated tree (TDD)

**Files:**
- Create: `tools/stage-release.sh`
- Create: `tools/tests/test_stage_release.sh`
- Create: `VERSION` (moved up from Task 8 — `stage-release.sh` copies it
  unconditionally, so it must exist before this task's own test can run)
- Modify: `PKGBUILD:25-46` (`package()` installs `VERSION` + `tools/gen_version.sh` so the Arch DKMS tree can self-identify)

- [ ] **Step 1: Create the top-level `VERSION` file**

```
6.4.3.0-8
```

- [ ] **Step 2: Write the failing test**

`tools/tests/test_stage_release.sh`:
```sh
#!/bin/sh
# Stage the real repo into a temp dir; assert the curated tarball contains
# exactly what a build/install needs and nothing it must not.
set -u
S=tools/stage-release.sh
D=$(mktemp -d)
trap 'rm -rf "$D"' EXIT
fails=0
ok()  { echo "ok: $1"; }
bad() { echo "FAIL: $1"; fails=$((fails+1)); }

sh "$S" 6.4.3.0-8 "$D/_stage" >/dev/null || { echo "FAIL: stage-release.sh errored"; exit 1; }
tar -czf "$D/rel.tar.gz" -C "$D/_stage" AIC8800-Linux-Driver-6.4.3.0-8
list=$(tar -tf "$D/rel.tar.gz")

P="AIC8800-Linux-Driver-6.4.3.0-8"
for f in \
    "$P/drivers/aic8800/Makefile" \
    "$P/drivers/aic8800/Kconfig" \
    "$P/drivers/aic8800/aic8800_fdrv/Makefile" \
    "$P/drivers/aic8800/aic8800_fdrv/rwnx_main.c" \
    "$P/drivers/aic8800/aic_load_fw/Makefile" \
    "$P/drivers/aic8800/aic_load_fw/aic_bluetooth_main.c" \
    "$P/fw/aic8800D80/fmacfw_8800d80_u02.bin" \
    "$P/tools/aic.rules" \
    "$P/tools/gen_version.sh" \
    "$P/dkms.conf" \
    "$P/VERSION" \
    "$P/LICENSE" \
    "$P/README.md"
do
    if echo "$list" | grep -qx "$f"; then ok "contains $f"; else bad "missing $f"; fi
done

if echo "$list" | grep -Eq '([./]rwnx_version_gen\.h|\.o$|\.ko$|\.git/)'; then
    bad "forbidden content shipped"; else ok "no residue / generated headers"; fi

if [ "$fails" -eq 0 ]; then echo "stage-release: all tests passed"; else
    echo "stage-release: $fails test(s) FAILED"; exit 1; fi
```

- [ ] **Step 3: Run tests, verify they fail**

Run: `sh tools/tests/run.sh`
Expected: new test fails ("stage-release.sh errored"), exit 1.

- [ ] **Step 4: Implement `tools/stage-release.sh`**

```sh
#!/bin/sh
# Assemble the curated release tree - the single definition of what a release
# ships (tarball, Arch package, and Debian source all consume this).
# Usage: stage-release.sh <version> [dest]
set -eu

VER="${1:-}"
if [ -z "$VER" ]; then
    echo "usage: stage-release.sh <version> [dest]" >&2
    exit 2
fi
DEST="${2:-_stage}"

ROOT=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
PKG="AIC8800-Linux-Driver-${VER}"

rm -rf "$DEST"
mkdir -p "$DEST/$PKG/drivers/aic8800" "$DEST/$PKG/fw" "$DEST/$PKG/tools"

cp -r "$ROOT/drivers/aic8800/aic_load_fw" "$DEST/$PKG/drivers/aic8800/"
cp -r "$ROOT/drivers/aic8800/aic8800_fdrv" "$DEST/$PKG/drivers/aic8800/"
cp    "$ROOT/drivers/aic8800/Makefile"     "$DEST/$PKG/drivers/aic8800/"
cp    "$ROOT/drivers/aic8800/Kconfig"      "$DEST/$PKG/drivers/aic8800/"
cp -r "$ROOT/fw/aic8800D80"                "$DEST/$PKG/fw/"
cp    "$ROOT/tools/aic.rules"     "$DEST/$PKG/tools/"
cp    "$ROOT/tools/gen_version.sh" "$DEST/$PKG/tools/"
cp    "$ROOT/dkms.conf"    "$DEST/$PKG/"
cp    "$ROOT/VERSION"      "$DEST/$PKG/"
cp    "$ROOT/LICENSE"      "$DEST/$PKG/"
cp    "$ROOT/README.md"    "$DEST/$PKG/"

# Strip anything that must not ship: build residue and generated headers.
find "$DEST/$PKG" \( -name '*.o' -o -name '*.ko' -o -name '*.mod' \
    -o -name '.cache.mk' -o -name 'modules.order' -o -name 'Module.symvers' \
    -o -name 'rwnx_version_gen.h' -o -name 'rwnx_version_gen.h.tmp' \
    \) -exec rm -f {} +
if [ -d "$DEST/$PKG/.git" ]; then rm -rf "$DEST/$PKG/.git"; fi

echo "$DEST/$PKG"
```

- [ ] **Step 5: Run tests, verify they pass**

Run: `sh tools/tests/run.sh`
Expected: all test files green.

- [ ] **Step 6: `PKGBUILD` `package()` — ship VERSION + gen script**

In `package()`, after the line `install -Dm 644 drivers/aic8800/Kconfig  "${dkms_dest}/Kconfig"`, insert:
```sh
    install -Dm 644 VERSION               "${dkms_dest}/VERSION"
    install -Dm 755 tools/gen_version.sh  "${dkms_dest}/tools/gen_version.sh"
```
(No other `PKGBUILD` change here — the `pkgrel` bump is Task 8.)

- [ ] **Step 7: Commit**

```bash
git add tools/stage-release.sh tools/tests/test_stage_release.sh VERSION PKGBUILD
git commit -m "tools: add stage-release.sh curated-tree assembler; ship VERSION + gen script in DKMS tree"
```

---

### Task 5: `debian/` packaging tree (**3.0 native**, hand-written rules, `prerm`)

**Files:**
- Create: `debian/control`, `debian/rules`, `debian/postinst`, `debian/prerm`, `debian/postrm`, `debian/changelog`, `debian/copyright`, `debian/source/format`

**Design rationale (from the revised spec):**
- `3.0 (native)`: every `-N` mutates the driver source, so there is no upstream truth frozen across revisions for a quilt orig/debian split to preserve. Native ships the full curated tree as one tarball per release (name carries the full `6.4.3.0-8`). A hyphenated native version only warns under dpkg-source's vendor hook / lintian; it does not fail the build. **Risk:** if `dpkg-source` on the CI runner rejects the hyphen, revert this task to the quilt variant (orig at baseline `6.4.3.0` + `debian.tar.xz`). The CI `ubuntu-package` job is the decider.
- `debian/rules` is a hand-written **shell script** (no debhelper): `build` is a no-op (DKMS compiles on the user's machine), `binary` — the target `dpkg-buildpackage -b` actually invokes after `build`, not `install` — populates `debian/<pkg>`, generates `DEBIAN/{control,postinst,prerm,postrm}` with version/baseline substitution, and runs `dpkg-deb --build` to emit the `.deb`; `clean` removes `debian/<pkg>`.
- DKMS lifecycle (mirrors the arch `.install`): `prerm upgrade` removes the old registration BEFORE the new `postinst` re-registers; `postrm remove` removes on uninstall. Every `-N` reuses the baseline-only DKMS path, so `postinst` does a clean `dkms remove ... || true` before `add` to tolerate a stale registration.

- [ ] **Step 1: `debian/source/format`**

```
3.0 (native)
```

- [ ] **Step 2: `debian/control`**

```
Source: aic8800-fdrv-dkms
Section: net
Priority: optional
Maintainer: Ronny F. <ronnyf@icloud.com>
Build-Depends: dpkg-dev
Standards-Version: 4.6.2
Homepage: https://github.com/ronnyf/AIC8800-Linux-Driver

Package: aic8800-fdrv-dkms
Architecture: all
Depends: dkms
Description: AIC8800 (D80/DC/DW) USB WiFi driver - DKMS source package
 AIC8800D80/DC/DW USB 2.0 WiFi (802.11ax) + BLE driver for Linux,
 built by DKMS against the running kernel.
 .
 Installs the DKMS source tree, the vendor firmware to
 /usr/lib/firmware/aic8800D80, and the udev rule.
 .
 Make sure the headers for your running kernel are installed, e.g.:
 apt install linux-headers-$(uname -r)
 If headers are installed after this package, run: dkms autoinstall
```

- [ ] **Step 3: `debian/rules` (executable shell script)**

```sh
#!/bin/sh -e
# Hand-written rules: assemble the package by hand (no debhelper).
# Targets: clean, build (no-op: DKMS compiles on the user's machine), binary
# (the target dpkg-buildpackage actually invokes after build - NOT "install",
# which nothing in this pipeline calls).
PKG=aic8800-fdrv-dkms
case "$1" in
    clean)
        rm -rf "debian/$PKG"
        ;;
    build)
        echo "no build step: headers are produced by DKMS on the user's machine"
        ;;
    binary)
        VER=$(dpkg-parsechangelog -SVersion)
        BASE=$(echo "$VER" | sed 's/-[0-9][0-9]*$//')
        P="debian/$PKG"
        rm -rf "$P"
        # DKMS source tree (same layout as the Arch package)
        install -dm 755 "$P"/usr/src/"$PKG-$BASE"
        cp -r drivers/aic8800/aic_load_fw  "$P"/usr/src/"$PKG-$BASE"/
        cp -r drivers/aic8800/aic8800_fdrv "$P"/usr/src/"$PKG-$BASE"/
        install -Dm 644 drivers/aic8800/Makefile "$P"/usr/src/"$PKG-$BASE"/Makefile
        install -Dm 644 dkms.conf     "$P"/usr/src/"$PKG-$BASE"/dkms.conf
        install -Dm 644 VERSION       "$P"/usr/src/"$PKG-$BASE"/VERSION
        install -Dm 755 tools/gen_version.sh "$P"/usr/src/"$PKG-$BASE"/tools/gen_version.sh
        # Firmware
        mkdir -p "$P"/usr/lib/firmware
        cp -r fw/aic8800D80 "$P"/usr/lib/firmware/
        # Udev rule
        install -Dm 644 tools/aic.rules "$P"/etc/udev/rules.d/aic.rules
        # Docs
        install -Dm 644 LICENSE   "$P"/usr/share/doc/"$PKG"/LICENSE
        install -Dm 644 README.md "$P"/usr/share/doc/"$PKG"/README.md
        install -Dm 644 debian/copyright "$P"/usr/share/doc/"$PKG"/copyright
        gzip -9c debian/changelog > "$P"/usr/share/doc/"$PKG"/changelog.Debian.gz
        # DEBIAN control + maintainer scripts (generated: version/baseline substituted)
        mkdir -p "$P"/DEBIAN
        IS=$(du -sk "$P" | awk '{print $1}')
        cat > "$P"/DEBIAN/control <<EOF
Package: $PKG
Version: $VER
Section: net
Priority: optional
Architecture: all
Maintainer: Ronny F. <ronnyf@icloud.com>
Installed-Size: $IS
Depends: dkms
Homepage: https://github.com/ronnyf/AIC8800-Linux-Driver
Description: AIC8800 (D80/DC/DW) USB WiFi driver - DKMS source package
 AIC8800D80/DC/DW USB 2.0 WiFi (802.11ax) + BLE driver for Linux,
 built by DKMS against the running kernel.
 .
 Installs the DKMS source tree, the vendor firmware to
 /usr/lib/firmware/aic8800D80, and the udev rule.
 .
 Make sure the headers for your running kernel are installed, e.g.:
 apt install linux-headers-$(uname -r)
 If headers are installed after this package, run: dkms autoinstall
EOF
        chmod 644 "$P"/DEBIAN/control
        sed "s/@@BASE@@/$BASE/" debian/postinst > "$P"/DEBIAN/postinst
        sed "s/@@BASE@@/$BASE/" debian/prerm   > "$P"/DEBIAN/prerm
        sed "s/@@BASE@@/$BASE/" debian/postrm  > "$P"/DEBIAN/postrm
        chmod 755 "$P"/DEBIAN/postinst "$P"/DEBIAN/prerm "$P"/DEBIAN/postrm
        # dpkg-buildpackage runs this with CWD = the source root, and expects
        # the .deb one level up, next to the .dsc/.tar.xz - same place `cd ..`
        # looks for it in the CI job and the docker smoke test.
        dpkg-deb --build --root-owner-group "$P" "../${PKG}_${VER}_all.deb"
        ;;
    *)
        echo "rules: unknown target '$1' (want: clean|build|binary)" >&2
        exit 1
        ;;
esac
```
Then: `chmod +x debian/rules` (git must record the executable bit).

- [ ] **Step 4: `debian/postinst`**

```sh
#!/bin/sh -e
# DKMS setup. Every -N release reuses the baseline-only DKMS path, so remove
# any stale registration before re-adding (prerm upgrade already did this for
# in-place upgrades; this makes fresh installs and odd states converge too).
DKMS_PKG=aic8800-fdrv-dkms
DKMS_VER=@@BASE@@

case "$1" in
    configure)
        echo "==> Registering DKMS module ${DKMS_PKG}/${DKMS_VER}"
        dkms remove -m "$DKMS_PKG" -v "$DKMS_VER" --all 2>/dev/null || true
        if ! dkms add -m "$DKMS_PKG" -v "$DKMS_VER"; then
            echo "==> dkms add failed" >&2
            exit 1
        fi
        if ! dkms build -m "$DKMS_PKG" -v "$DKMS_VER"; then
            echo "==> DKMS build failed: kernel headers for $(uname -r) are probably missing."
            echo "==> Run:  sudo apt install linux-headers-$(uname -r) && sudo dkms autoinstall"
        else
            dkms install -m "$DKMS_PKG" -v "$DKMS_VER"
        fi
        ;;
    abort-upgrade|abort-remove|abort-deconfigure)
        ;;
    *)
        echo "postinst called with unknown argument '$1'" >&2
        exit 1
        ;;
esac
```

- [ ] **Step 5: `debian/prerm`**

```sh
#!/bin/sh -e
# On upgrade, remove the baseline-only DKMS registration before the new
# version's postinst re-registers it (mirrors the arch .install post_upgrade:
# pre_remove -> post_install). On remove, postrm handles the actual removal.
DKMS_PKG=aic8800-fdrv-dkms
DKMS_VER=@@BASE@@

case "$1" in
    upgrade)
        echo "==> Removing DKMS module ${DKMS_PKG}/${DKMS_VER} for upgrade"
        dkms remove -m "$DKMS_PKG" -v "$DKMS_VER" --all 2>/dev/null || true
        ;;
    *)
        ;;
esac
```

- [ ] **Step 6: `debian/postrm`**

```sh
#!/bin/sh -e
# Remove the DKMS registration on uninstall. On upgrade, deconfigure, and
# abort paths, the module is intentionally left in place (the new/remaining
# installation owns it), so only a plain remove tears it down.
DKMS_PKG=aic8800-fdrv-dkms
DKMS_VER=@@BASE@@

case "$1" in
    remove)
        echo "==> Removing DKMS module ${DKMS_PKG}/${DKMS_VER}"
        dkms remove -m "$DKMS_PKG" -v "$DKMS_VER" --all 2>/dev/null || true
        ;;
    *)
        ;;
esac
```

- [ ] **Step 7: `debian/changelog`** (seeded with the next release, `6.4.3.0-8`)

```
aic8800-fdrv-dkms (6.4.3.0-8) unstable; urgency=medium

  * Fork release 6.4.3.0-8: kernel 7.2 support, AIC8800D80 USB IDs + firmware
    path module parameter, HE radiotap zero-init fix, vendor logger
    ring-buffer overflow fix, release pipeline v2 (Ubuntu .deb + version gate).

 -- Ronny F. <ronnyf@icloud.com>  Mon, 31 Aug 2026 12:00:00 +0000
```

- [ ] **Step 8: `debian/copyright`**

```
Format: https://www.debian.org/doc/packaging-manuals/copyright-format/1.0/
Upstream-Name: AIC8800-Linux-Driver
Source: https://github.com/ronnyf/AIC8800-Linux-Driver

Files: *
Copyright: 2012-2019 RivieraWaves
           2018-2020 AICSemi
           2025-2026 Ronny F.
License: GPL-2.0

License: GPL-2.0
 This program is free software; you can redistribute it and/or modify
 it under the terms of the GNU General Public License as published by
 the Free Software Foundation; either version 2 of the License, or
 (at your option) any later version.
 .
 This program is distributed in the hope that it will be useful,
 but WITHOUT ANY WARRANTY; without even the implied warranty of
 MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 GNU General Public License for more details.
 .
 On Debian systems, the complete text of the GNU General Public
 License version 2 can be found in "/usr/share/common-licenses/GPL-2".
```

- [ ] **Step 9: Verify (conditional docker smoke; otherwise defer to CI)**

Run: `docker info >/dev/null 2>&1 && echo up || echo down`
- If `up`, run the smoke (builds the native source + binary locally, the same as CI):
  ```bash
  docker run --rm -v "$PWD":/w -w /w ubuntu:24.04 bash -c '
    apt-get update -qq && apt-get install -y -qq dpkg-dev lintian >/dev/null
    VER=6.4.3.0-8; PKG=aic8800-fdrv-dkms; SRC="$PKG"_"$VER"
    rm -rf "$SRC" _stage
    sh tools/stage-release.sh "$VER" _stage >/dev/null
    mkdir -p "$SRC"
    tar -cf - -C "_stage/AIC8800-Linux-Driver-$VER" . | tar -xf - -C "$SRC"
    cp -r debian "$SRC"/
    sh -c "cd $SRC && dpkg-source -b ."
    sh -c "cd $SRC && dpkg-buildpackage -b -us -uc"
    ls -lh ./*.dsc ./*.tar.xz ./*.deb
    dpkg-deb -I "$PKG"_"$VER"_all.deb | sed -n "1,12p"
  '
  ```
  Expected: source `aic8800-fdrv-dkms_6.4.3.0-8.dsc` + `..._6.4.3.0-8.tar.xz` and binary `aic8800-fdrv-dkms_6.4.3.0-8_all.deb` are produced; `dpkg-deb -I` shows `Version: 6.4.3.0-8`, `Architecture: all`, `Depends: dkms`, a sane `Installed-Size`.
- If `down` (daemon not running) OR the container build is not possible, **do not start Docker unprompted** — record in the task notes that the Debian tree is unverified locally and the CI `ubuntu-package` job (Task 9) is the authoritative check, then proceed.

- [ ] **Step 10: Commit**

```bash
git add debian/
git commit -m "debian: hand-written 3.0 (native) DKMS packaging (rules/postinst/prerm/postrm)"
```

---

### Task 6: Rewrite `.github/workflows/release.yml` (3 jobs, native deb, append_body notes)

**Files:**
- Modify: `.github/workflows/release.yml` (full rewrite)

**Shape (per revised spec):**
- `release` (archlinux container): gate → stage → tarball → makepkg → `.SRCINFO` → softprops **creates** the release with the **Arch-only** notes + Arch assets.
- `ubuntu-package` (ubuntu-latest, `needs: release`): gate → stage → native `dpkg-source -b` + `dpkg-buildpackage -b` → lintian (report-only) → softprops **appends** the Ubuntu notes (`append_body: true`) + the 3 Debian assets.
- `publish-repo` (reusable, `needs: release` **only** — it reads only `.pkg.tar.zst`, so a Debian failure must not block the working Arch+Pages publish).
- The old `sed` "Patch PKGBUILD with tag version" step is **deleted** (the gate proves `PKGBUILD == tag` first). `makepkg` still uses the locally staged tarball by name match; the `PKGBUILD` `source=` URL remains for user-side `makepkg`.

- [ ] **Step 1: Replace `.github/workflows/release.yml` with:**

```yaml
name: Release

on:
  push:
    tags:
      - 'v*'

permissions:
  contents: write

jobs:
  release:
    name: Arch package + release
    runs-on: ubuntu-latest
    container:
      image: archlinux:base-devel
    steps:
      - name: Install build tools
        run: |
          pacman -Syu --noconfirm --needed git sudo

      - name: Create builder user
        run: |
          useradd -m builder
          echo 'builder ALL=(ALL) NOPASSWD: ALL' >> /etc/sudoers

      - name: Checkout
        uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: |
          TAG="${GITHUB_REF#refs/tags/}"
          VERSION="${TAG#v}"
          if [[ "$VERSION" == *-* ]]; then
            PKGVER="${VERSION%-*}"
            PKGREL="${VERSION##*-}"
          else
            PKGVER="$VERSION"
            PKGREL="1"
          fi
          {
            echo "tag=${TAG}"
            echo "version=${VERSION}"
            echo "pkgver=${PKGVER}"
            echo "pkgrel=${PKGREL}"
          } >> "$GITHUB_OUTPUT"
          echo "Tag=${TAG} pkgver=${PKGVER} pkgrel=${PKGREL}"

      - name: Verify version consistency
        run: sh tools/check_release_version.sh "${{ steps.version.outputs.version }}"

      - name: Stage curated tree
        run: sh tools/stage-release.sh "${{ steps.version.outputs.version }}" _stage

      - name: Create source tarball
        id: tarball
        run: |
          VER="${{ steps.version.outputs.version }}"
          TARBALL="AIC8800-Linux-Driver-${VER}.tar.gz"
          tar -czf "${TARBALL}" -C _stage "AIC8800-Linux-Driver-${VER}"
          echo "tarball=${TARBALL}" >> "$GITHUB_OUTPUT"
          ls -lh "${TARBALL}"

      - name: Build pacman package
        id: pacman
        run: |
          chown -R builder:builder .
          sudo -u builder makepkg --noconfirm --skipchecksums --nodeps -f
          PKGFILE=$(ls aic8800-fdrv-dkms-*.pkg.tar.zst | head -1)
          [ -n "${PKGFILE}" ] || { echo "ERROR: no .pkg.tar.zst produced"; exit 1; }
          echo "pkg=${PKGFILE}" >> "$GITHUB_OUTPUT"
          ls -lh "${PKGFILE}"
          echo "--- package contents ---"
          bsdtar -tf "${PKGFILE}" | head -40

      - name: Generate .SRCINFO
        run: |
          sudo -u builder makepkg --printsrcinfo > .SRCINFO
          cat .SRCINFO

      - name: Create GitHub Release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          name: "Release ${{ steps.version.outputs.version }}"
          generate_release_notes: true
          body: |
            ## Install on Arch Linux / CachyOS

            **Option 1 — install the prebuilt package:**
            ```bash
            curl -LO https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/${{ steps.pacman.outputs.pkg }}
            sudo pacman -U ${{ steps.pacman.outputs.pkg }}
            ```

            **Option 2 — build from PKGBUILD with `makepkg`:**
            ```bash
            curl -LO https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/PKGBUILD
            curl -LO https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/aic8800-fdrv-dkms.install
            makepkg -si
            ```

            DKMS rebuilds the modules automatically on each kernel update.
            Make sure the matching headers are installed for your kernel
            (`linux-headers`, `linux-cachyos-headers`, etc.).
          files: |
            ${{ steps.tarball.outputs.tarball }}
            ${{ steps.pacman.outputs.pkg }}
            PKGBUILD
            .SRCINFO
            aic8800-fdrv-dkms.install

  ubuntu-package:
    name: Ubuntu/Debian package
    needs: release
    runs-on: ubuntu-latest
    steps:
      - name: Checkout
        uses: actions/checkout@v4

      - name: Extract version from tag
        id: version
        run: |
          VERSION="${GITHUB_REF#refs/tags/v}"
          PKG="aic8800-fdrv-dkms"
          {
            echo "version=${VERSION}"
            echo "pkg=${PKG}"
          } >> "$GITHUB_OUTPUT"
          echo "package=${PKG} version=${VERSION}"

      - name: Verify version consistency
        run: sh tools/check_release_version.sh "${{ steps.version.outputs.version }}"

      - name: Install packaging tools
        run: |
          sudo apt-get update
          sudo apt-get install -y --no-install-recommends dpkg-dev lintian

      - name: Stage Debian source tree (native)
        id: stage
        run: |
          VER="${{ steps.version.outputs.version }}"
          PKG="${{ steps.version.outputs.pkg }}"
          SRC="${PKG}_${VER}"
          sh tools/stage-release.sh "$VER" _stage
          mkdir -p "${SRC}"
          tar -cf - -C "_stage/AIC8800-Linux-Driver-${VER}" . | tar -xf - -C "${SRC}"
          cp -r debian "${SRC}/"
          echo "src=${SRC}" >> "$GITHUB_OUTPUT"
          ls -la "${SRC}"

      - name: Build source package (dpkg-source, native)
        run: |
          SRC="${{ steps.stage.outputs.src }}"
          cd "${SRC}"
          dpkg-source -b .
          cd ..
          ls -lh "${SRC}.dsc" "${SRC}.tar.xz"

      - name: Build binary package (dpkg-buildpackage)
        run: |
          SRC="${{ steps.stage.outputs.src }}"
          VER="${{ steps.version.outputs.version }}"
          PKG="${{ steps.version.outputs.pkg }}"
          cd "${SRC}"
          dpkg-buildpackage -b -us -uc
          cd ..
          ls -lh "${PKG}_${VER}_all.deb"

      - name: Lint (report-only)
        run: |
          VER="${{ steps.version.outputs.version }}"
          PKG="${{ steps.version.outputs.pkg }}"
          set +e
          lintian "${PKG}_${VER}.dsc" "${PKG}_${VER}_all.deb" 2>&1 | tee /tmp/lintian.log | tail -n 40
          N=$(grep -cE '^(I|W|E):' /tmp/lintian.log || true)
          echo "::notice title=Lintian::${N} finding(s), see step log"

      - name: Append Debian assets to the release
        uses: softprops/action-gh-release@v2
        with:
          tag_name: ${{ github.ref_name }}
          append_body: true
          body: |
            ## Install on Ubuntu / Debian

            **Prebuilt DKMS package:**
            ```bash
            curl -LO https://github.com/${{ github.repository }}/releases/download/${{ github.ref_name }}/aic8800-fdrv-dkms_${{ steps.version.outputs.version }}_all.deb
            sudo apt install dkms "linux-headers-$(uname -r)"
            sudo dpkg -i aic8800-fdrv-dkms_${{ steps.version.outputs.version }}_all.deb
            ```

            If the headers were installed after the package, run
            `sudo dkms autoinstall`.
          files: |
            aic8800-fdrv-dkms_${{ steps.version.outputs.version }}_all.deb
            aic8800-fdrv-dkms_${{ steps.version.outputs.version }}.dsc
            aic8800-fdrv-dkms_${{ steps.version.outputs.version }}.tar.xz

  # Runs only after the Arch release exists. It reads only .pkg.tar.zst assets, so
  # it needs the `release` job alone - a Debian-side failure must not block the
  # working Arch + Pages publish.
  publish-repo:
    name: Publish pacman repository
    needs: release
    permissions:
      contents: read
      pages: write
      id-token: write
    uses: ./.github/workflows/pacman-repo.yml
```

- [ ] **Step 2: Validate the YAML**

Run: `ruby -ryaml -e 'YAML.safe_load_file(".github/workflows/release.yml"); puts "YAML OK"'`
Expected: `YAML OK`. (If `ruby` is unavailable: `python3 -c 'import yaml,sys; yaml.safe_load(open(".github/workflows/release.yml")); print("YAML OK")'`.)

- [ ] **Step 3: Confirm the three-job wiring by inspection**

Run: `grep -nE '^(jobs:|  [a-z-]+:|    needs:)' .github/workflows/release.yml`
Expected: `release`, `ubuntu-package` (`needs: release`), `publish-repo` (`needs: release`).

- [ ] **Step 4: Commit**

```bash
git add .github/workflows/release.yml
git commit -m "ci: release builds Arch + Ubuntu packages with a shared version gate"
```

---

### Task 7: Documentation (versioning strategy, README, AGENTS)

**Files:**
- Create: `docs/versioning.md`
- Modify: `README.md` (Ubuntu install section, after the Arch section at line ~48-72)
- Modify: `AGENTS.md` (new "Versioning" section)

- [ ] **Step 1: Create `docs/versioning.md`**

```markdown
# Versioning Strategy

The fork ships as `<baseline>-<N>`:

- `6.4.3.0` is the **frozen vendor (AICSemi) driver/firmware baseline**. It
  only moves if AICSemi ships new firmware; when it does, `N` resets to 1.
- `N` is the **fork release number**, strictly increasing, never reused.
  Vendor upstream is effectively dead, so `N` is the driver's real version
  axis: every `-N` release contains a genuine source change.

## One version, four consumers

| Consumer | Format | Value |
|---|---|---|
| git tag | `v<pkgver>-<pkgrel>` | `v6.4.3.0-8` |
| Arch | `pkgver` / `pkgrel` | `6.4.3.0` / `8` |
| Debian | `Version` | `6.4.3.0-8` |
| DKMS | `PACKAGE_VERSION` | `6.4.3.0` (baseline only) |
| `modinfo` | `MODULE_VERSION` | `6.4.3.0` (vendor baseline) |

DKMS deliberately uses the **baseline-only** version so a package upgrade
swaps the source in place at `/usr/src/aic8800-fdrv-dkms-6.4.3.0/` instead of
stacking a dkms entry per release.

## Single source of truth

The top-level `VERSION` file holds the version the repo is ready to release
(e.g. `6.4.3.0-8`). `tools/check_release_version.sh` (run by the release
workflow in both the Arch and Ubuntu jobs) fails unless:

- pushed tag (minus `v`) == `VERSION`
- `PKGBUILD` `pkgver`/`pkgrel` == tag
- `debian/changelog` top entry == tag
- `dkms.conf` `PACKAGE_VERSION` == the tag's baseline component

## Bump procedure

1. On `main`: a PR bumping `VERSION` to `6.4.3.0-(N+1)`, `PKGBUILD`
   `pkgrel`, and adding a `debian/changelog` entry
   (`dch -v 6.4.3.0-(N+1) -D unstable --noedit "Fork release"`).
2. Merge.
3. Push tag `v6.4.3.0-(N+1)`.
4. CI: version gate, Arch package, Debian package (native `.dsc`), Pages publish.

## Build-time driver identity

`rwnx_version_gen.h` is generated at build time (`make version-header`, which
`modules` depends on; generator `tools/gen_version.sh`). Identity chain, first
hit wins: `$RWNX_VERSION_IDENTITY` → `git describe --tags` (falls through on
failure) → `$ROOT/VERSION` → hard error. `modinfo` shows the vendor baseline;
the dmesg / vendor-command banner shows the exact fork build. Never commit the
generated headers; they are git-ignored and removed by `make clean`.

The old dead constant `RWNX_VERS_NUM` (previously in
`aic8800_fdrv/Makefile`) and the two hand-committed `rwnx_version_gen.h` files
are gone — there is no longer a seventh copy of the version to drift.
```

- [ ] **Step 2: README Ubuntu section**

In `README.md`, immediately after the Arch section (the `## Installation on Arch Linux / CachyOS (pacman repository)` block, ending before `## Compilation and Installation`), insert:
```markdown
## Installation on Ubuntu / Debian (prebuilt .deb)

Release assets include a DKMS `.deb` that installs the source tree, firmware,
and udev rule, and registers the module with DKMS:

```bash
curl -LO https://github.com/ronnyf/AIC8800-Linux-Driver/releases/download/<tag>/aic8800-fdrv-dkms_<version>_all.deb
sudo apt install dkms "linux-headers-$(uname -r)"
sudo dpkg -i aic8800-fdrv-dkms_<version>_all.deb
```

If the kernel headers are installed after the package, run `sudo dkms autoinstall`.
```

- [ ] **Step 3: AGENTS.md Versioning section**

Append to `AGENTS.md` (top level, after the existing sections):
```markdown
## Versioning

- Scheme: `<baseline>-<N>`; `6.4.3.0` is the frozen vendor/FW baseline, `N` the
  fork release number. See `docs/versioning.md`.
- Single source of truth: the top-level `VERSION` file. Release PRs bump
  `VERSION`, `PKGBUILD` pkgver/pkgrel, and the `debian/changelog` top entry
  together; `tools/check_release_version.sh` (release workflow) fails if tag,
  VERSION, PKGBUILD, changelog, or dkms.conf disagree.
- Tags: `v<baseline>-<N>` (e.g. `v6.4.3.0-8`).
- `rwnx_version_gen.h` is generated at build time (top-level `make
  version-header`, wired into `modules`); identity = `$RWNX_VERSION_IDENTITY`
  → `git describe` → `VERSION` file. Do NOT commit the headers. `modinfo`
  shows the vendor baseline; the dmesg banner shows the exact fork build.
- DKMS version stays at the baseline (`6.4.3.0`) so package upgrades swap the
  DKMS source in place (remove-then-add via `prerm upgrade` / `postinst`).
```

- [ ] **Step 4: Commit**

```bash
git add docs/versioning.md README.md AGENTS.md
git commit -m "docs: versioning strategy, Ubuntu install, AGENTS versioning section"
```

---

### Task 8: Release-ready state — `PKGBUILD` pkgrel bump (local only)

**Files:**
- Modify: `PKGBUILD:5` (`pkgrel=5` → `pkgrel=8`)

- [ ] **Step 1: Confirm `VERSION` (created in Task 4)**

Run: `cat VERSION` — expected: `6.4.3.0-8`.

- [ ] **Step 2: Bump `PKGBUILD` `pkgrel`**

Change `pkgrel=5` to `pkgrel=8`. (`pkgver` stays `6.4.3.0`; the `source=` URL
already uses `${pkgver}`/`${pkgrel}` so it now points at `v6.4.3.0-8`.)

- [ ] **Step 3: Verify the repo now passes the gate for the next tag**

Run: `sh tools/check_release_version.sh 6.4.3.0-8`
Expected: `version consistent: 6.4.3.0-8 (VERSION, PKGBUILD 6.4.3.0-8, debian/changelog, dkms.conf 6.4.3.0)`, exit 0.

Run: `sh tools/tests/run.sh`
Expected: `ALL TESTS PASSED`.

- [ ] **Step 4: Stage a dry-run tarball and inspect it**

Run: `sh tools/stage-release.sh 6.4.3.0-8 /tmp/drystage >/dev/null && tar -tzf <(tar -cf - -C /tmp/drystage AIC8800-Linux-Driver-6.4.3.0-8) | grep -E 'VERSION|gen_version.sh|dkms.conf'`
Expected: it lists `.../VERSION`, `.../tools/gen_version.sh`, `.../dkms.conf`. Then `rm -rf /tmp/drystage`.

- [ ] **Step 5: Commit (local only — do NOT push)**

```bash
git add PKGBUILD
git commit -m "release: prepare 6.4.3.0-8 (PKGBUILD pkgrel bump)"
```

---

### Task 9: CI verification — watch `build.yml` on PR #30 (replaces direct `main` push)

The PR's `pull_request` trigger runs `build.yml` (the only job that compiles
the driver, including the WERROR upstream job). This proves the kbuild
version-header wiring end-to-end — the local `version-header` smoke (Task 2)
cannot cover kbuild's object-dependency and WERROR behavior.

- [ ] **Step 1: Confirm the full task history is on the PR**

Each task commit was pushed to the PR branch as it landed (deviation note at
the top). Confirm the PR head matches local before watching:
```bash
git push origin release-pipeline-and-versioning
gh pr view 30 --json headRefOid --jq .headRefOid
```
Expected: printed SHA == `git rev-parse HEAD`.

- [ ] **Step 2: Watch the build workflow**

Run: `gh pr checks 30`
Expected (after a few minutes): all matrix legs pass on the PR head (linux-headers, linux-lts-headers, linux-headers testing, upstream v7.2 gcc, upstream v7.2 clang).

If any leg fails: fetch `gh run view <id> --log-failed`, confirm the VERSION-MISMATCH / missing-header / WERROR error, fix in a NEW commit on the branch (never amend the pushed one), push, re-watch. **Do not push the release tag (Task 10) until build.yml is green on the tip.** PR #30 is merged by the user's decision after this is green; that merge is what lands the commits on `main`.

- [ ] **Step 3: Confirm the generated header landed in a build**

Run: `gh run view <id> --log 2>/dev/null | grep -i 'GEN ' | head`
Expected: `GEN aic_load_fw/rwnx_version_gen.h` and `GEN aic8800_fdrv/rwnx_version_gen.h` appear. (No "or it's cached" escape hatch: `actions/checkout@v4` starts from a clean tree with no prior `rwnx_version_gen.h` — since the header is git-ignored and never committed, `GEN` absent here means the wiring didn't run, not that it was skipped.)

---

### Task 10: Cut and verify the `v6.4.3.0-8` release (push gate)

- [ ] **Step 1: Confirm with the user, then push the tag**

The tag push triggers the full `release.yml` (Arch + Ubuntu + Pages). This
creates a real public release. Ask the user to confirm before:
```bash
git tag v6.4.3.0-8
git push origin v6.4.3.0-8
```

- [ ] **Step 2: Watch all three release jobs**

Run: `gh run list --workflow=release.yml --limit 2 --json databaseId,headBranch,status,conclusion,createdAt`
Expected: the run on `v6.4.3.0-8` has `conclusion: success` for `release`, `ubuntu-package`, and `publish-repo`.

- [ ] **Step 3: Verify the release assets**

Run: `gh release view v6.4.3.0-8 --json assets --jq '.assets[].name'`
Expected (8 assets):
```
AIC8800-Linux-Driver-6.4.3.0-8.tar.gz
aic8800-fdrv-dkms-6.4.3.0-8-any.pkg.tar.zst
PKGBUILD
.SRCINFO
aic8800-fdrv-dkms.install
aic8800-fdrv-dkms_6.4.3.0-8_all.deb
aic8800-fdrv-dkms_6.4.3.0-8.dsc
aic8800-fdrv-dkms_6.4.3.0-8.tar.xz
```
(and the Ubuntu section appended to the release body after the Arch section).

- [ ] **Step 4: Verify the Pages pacman repo re-published**

Run: `gh run view <id> --log 2>/dev/null | grep -E 'notice title=(Repo unreachable|Pacman repo|Smoke test)' | head`
Expected: a `Pacman repo::published at <url>x86_64` notice and a passing `Smoke test::pacman resolved and downloaded...` notice.

- [ ] **Step 5: Failure recovery (only if a job failed)**

If any release job failed: inspect `gh run view <id> --log-failed`. Repeating history's proven path — fix the workflow/manifest in a new commit, then
```bash
gh release delete v6.4.3.0-8 --cleanup-tag
git push origin :refs/tags/v6.4.3.0-8
git push origin v6.4.3.0-8
```
Assets are replaced on the same tag and the Pages repo rebuilds from whatever releases exist. Re-watch. **Loop rule: at most 2 fix attempts per symptom; if a third is needed, STOP and report rather than keep pushing tags.**

---

## Self-Review

**Spec coverage (revised spec → task):**
- Arch `.pkg.tar.zst` + tarball + `.SRCINFO`/PKGBUILD/install → Task 6 `release` job.
- Ubuntu `.deb` + native `.dsc` + tarball for maintainers → Task 5 (tree) + Task 6 `ubuntu-package`.
- No zip → not built (tarball is the source archive). ✓
- `VERSION` single source of truth + gate (incl. dkms.conf baseline) → Tasks 3 + 8.
- Generated `rwnx_version_gen.h` + identity chain + `RWNX_VERS_NUM` removal → Tasks 1 + 2.
- `3.0 (native)` + `prerm`/`postinst`/`postrm` + hand-written rules → Task 5.
- `publish-repo` needs only `release`; `append_body` notes; sed PKGBUILD step removed → Task 6.
- `docs/versioning.md`, README, AGENTS → Task 7.
- Verification & recovery → Tasks 9 + 10.

**Placeholder scan:** none — every file has full content, every step a command + expected output.

**Consistency:** `check_release_version.sh` covers exactly five sources (VERSION, PKGBUILD×2, changelog, dkms.conf) matching Task 3 fixtures and Task 8 verification; native asset names in Task 5 docker smoke == Task 6 ubuntu-package == Task 10 asset list (`_all.deb`, `.dsc`, `.tar.xz`). `prerm`/`postinst`/`postrm` all substitute `@@BASE@@` (set in Task 5 `rules binary`).

**Known risks (honest):** (1) native source with a hyphenated version is the spec's one bet against dpkg-source/lintian strictness — it warns, not fails; fallback to the quilt variant is documented in Task 5. (2) The Ubuntu/Arch release jobs are only truly exercised on the Task 10 tag push; Tasks 2–6 give high confidence but not proof. Task 9 (build.yml on main) is the first full compile.
