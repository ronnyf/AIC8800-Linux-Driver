#!/usr/bin/env bash
# Trust a repository key and resolve (optionally download) the driver package
# from it with pacman's default strict SigLevel, inside a fresh archlinux:base
# container.
#
# Usage: pacman-smoke.sh <keyfile> <server> <reponame> <key-fpr> [download]
set -euo pipefail

KEYFILE=$1
SERVER=$2
REPO_NAME=$3
KEY_FPR=$4
DOWNLOAD=${5:-0}

# The image ships a keyring but no pacman signing key; --init creates the
# ephemeral key that --lsign-key needs to mark the repository key as trusted.
pacman-key --init
pacman-key --add "$KEYFILE"
pacman-key --lsign-key "$KEY_FPR"

printf '[%s]\nServer = %s\n' "$REPO_NAME" "$SERVER" >> /etc/pacman.conf
pacman -Sy --noconfirm
pacman -Si "${REPO_NAME}/aic8800-fdrv-dkms" | head -n 8

if [ "$DOWNLOAD" = 1 ]; then
  mkdir -p /tmp/cache
  pacman -Sw --noconfirm --cachedir /tmp/cache "${REPO_NAME}/aic8800-fdrv-dkms"
  ls -l /tmp/cache/*.pkg.tar.*
fi
