# Build Error Analysis - Missing Symbol Links

## Problem Statement
After rebasing `ronnyf/missing-prototype-warnings` branch onto latest main, the build fails with undefined symbol errors:

```
ERROR: modpost: "rwnx_skb_align_8bytes" [aic8800_fdrv/aic8800_fdrv.ko] undefined!
ERROR: modpost: "rwnx_init_cmd_array" [aic8800_fdrv/aic8800_fdrv.ko] undefined!
ERROR: modpost: "rwnx_free_cmd_array" [aic8800_fdrv/aic8800_fdrv.ko] undefined!
ERROR: modpost: "rwnx_cmd_free" [aic8800_fdrv/aic8800_fdrv.ko] undefined!
```

## Root Cause Analysis

### Function Declarations vs Definitions

**In `rwnx_main.c` (line 556):**
```c
static void rwnx_skb_align_8bytes(struct sk_buff *skb) {
```
- Function is defined as `static` (internal linkage, only visible within this file)

**In `rwnx_rx.c` (line 112):**
```c
void rwnx_skb_align_8bytes(struct sk_buff *skb);
```
- Forward declaration without `static` (external linkage expected)

**In `rwnx_msg_tx.c` (lines 23-25):**
```c
static struct rwnx_cmd *rwnx_cmd_malloc(void);
static void rwnx_cmd_free(struct rwnx_cmd *cmd);
static int rwnx_init_cmd_array(void);
static void rwnx_free_cmd_array(void);
```
- All forward declarations are `static`

**In `rwnx_main.c` (lines 580-581):**
```c
int rwnx_init_cmd_array(void);
void rwnx_free_cmd_array(void);
```
- Forward declarations without `static`

### The Conflict

The functions are defined as `static` (internal linkage) but referenced with external linkage in other files. This is a classic C language issue:

- `static` functions have internal linkage - they're only visible within their compilation unit (.c file)
- Non-static declarations without definition in the same file create an expectation of external linkage
- When the function is actually `static`, the compiler/linker can't resolve the reference

### Why Did PR #7 Build Successfully?

PR #7 (`3e4f5de`) was merged to main and appears to have the same structure, yet it builds. Possible explanations:

1. **Different source versions** - The original source before PR #7 may have had these functions non-static
2. **Build artifacts cached** - Previous build state may have influenced compilation order
3. **Different compiler versions** - GCC vs Clang may handle this differently
4. **Header include order differences** - The forward declarations may come from a different header in the file

## Solution Options

### Option 1: Remove `static` from all definitions (Recommended)
Remove `static` keyword from:
- `rwnx_skb_align_8bytes()` in rwnx_main.c
- `rwnx_init_cmd_array()` in rwnx_msg_tx.c  
- `rwnx_free_cmd_array()` in rwnx_msg_tx.c
- `rwnx_cmd_free()` in rwnx_msg_tx.c

This makes them available for cross-file use as intended by the forward declarations.

### Option 2: Add `static` to all forward declarations
Add `static` to forward declarations in files that reference these functions:
- rwnx_rx.c (line 112)
- main.c (lines 580-581)

But this would require changing the forward declarations to match the static definitions, which means either:
- Making them local to each file (copy each function in each file)
- Moving them to headers and making them truly static inline

### Option 3: Use `EXPORT_SYMBOL` for cross-module use
Add EXPORT_SYMBOL for functions that need to be available across files:
```c
EXPORT_SYMBOL(rwnx_skb_align_8bytes);
```

## Recommended Action

**Remove `static` from function definitions** since the codebase clearly intends these functions to be called from multiple files (evidenced by forward declarations in other files).

This requires:
1. Remove `static` from rwnx_main.c:556
2. Remove `static` from rwnx_msg_tx.c:208, 218, 233
3. Ensure forward declarations match definitions

## Files to Modify

- `drivers/aic8800/aic8800_fdrv/rwnx_main.c` - Remove `static` from rwnx_skb_align_8bytes
- `drivers/aic8800/aic8800_fdrv/rwnx_msg_tx.c` - Remove `static` from rwnx_cmd_free, rwnx_init_cmd_array, rwnx_free_cmd_array

## Note on Rebase

The branch was successfully rebased onto `origin/main` commit `3e4f5de`. The only substantive difference is one line where a `printk(KERN_CRIT ...)` was converted to `AICWFDBG(LOGERROR, ...)`, which is correct per the goal of this PR.
