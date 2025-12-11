#!/bin/sh
# find_susfs_version.sh <out-dir>
# Try to read SUSFS_VERSION from out/source/include/linux/susfs.h first.
OUTDIR=${1:-out}

# 1) out/source include (most reliable after build)
if [ -f "$OUTDIR/source/include/linux/susfs.h" ]; then
    ver=$(grep -oP '^#\s*define\s+SUSFS_VERSION\s+"?\K[^"]+' "$OUTDIR/source/include/linux/susfs.h" 2>/dev/null | head -n1)
    if [ -n "$ver" ]; then
        printf '%s\n' "${ver#_}"
        exit 0
    fi
fi

# 2) workspace include (fallback)
if [ -f "include/linux/susfs.h" ]; then
    ver=$(grep -oP '^#\s*define\s+SUSFS_VERSION\s+"?\K[^"]+' include/linux/susfs.h 2>/dev/null | head -n1)
    if [ -n "$ver" ]; then
        printf '%s\n' "${ver#_}"
        exit 0
    fi
fi

# 3) try to find printed info lines (Kbuild output present in out)
line=$(grep -m1 -R -I -E 'KernelSU(-SusFS)? Version|SukiSU(-Ultra)? version' "$OUTDIR" 2>/dev/null | head -n1)
if [ -n "$line" ]; then
    val=$(echo "$line" | grep -oE 'v[0-9]+(\.[0-9]+){1,}' | head -n1)
    if [ -n "$val" ]; then
        printf '%s\n' "${val#_}"
        exit 0
    fi
fi

# 4) fallback: try to parse source header lines referenced by Kbuild (less likely)
# search for SUSFS_VERSION pattern in out/source tree
assign=$(grep -RIn --line-number -E 'SUSFS_VERSION[[:space:]]*[:?+]?=' "$OUTDIR" 2>/dev/null | head -n1)
if [ -n "$assign" ]; then
    rhs=$(echo "$assign" | sed -E 's/.*=[[:space:]]*//; s/^[[:space:]]*//; s/[[:space:]].*$//')
    rhs=${rhs#_}
    if [ -n "$rhs" ]; then
        # try to extract vX.Y(.Z)
        val=$(echo "$rhs" | grep -oE 'v[0-9]+(\.[0-9]+){1,}' | head -n1)
        if [ -n "$val" ]; then
            printf '%s\n' "${val#_}"
            exit 0
        fi
        printf '%s\n' "$rhs"
        exit 0
    fi
fi

# 5) final fallback
printf 'v0.0.0\n'
exit 0
