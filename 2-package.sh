#!/usr/bin/env bash
# Package a Godot-exported binary and .pck into a SailfishOS RPM.
#
# Before running:
#   1. Export your game from Godot using the Linux/X11 export preset with the
#      arm64 template built by 1-build-template.sh. Set the export path to
#      build/harbour-APPNAME (no extension) — Godot will produce both the
#      binary and the .pck file.
#   2. Fill in the APP_NAME variable below.
#   3. Copy/edit template/ to match your app (spec, desktop, profile, icons).

set -euo pipefail

# ── Configure ─────────────────────────────────────────────────────────────────
APP_NAME="harbour-mygame"       # must match your spec/desktop/profile filenames
SFOS_VERSION="5.1.0.11"
# ─────────────────────────────────────────────────────────────────────────────

REPO="$(cd "$(dirname "$0")" && pwd)"
BUILD_DIR="${REPO}/build"
PKG_DIR="${REPO}/sfos-pkg"
OUT_DIR="${REPO}/RPMS"

mkdir -p "${PKG_DIR}" "${OUT_DIR}"

cp "${BUILD_DIR}/${APP_NAME}"     "${PKG_DIR}/"
cp "${BUILD_DIR}/${APP_NAME}.pck" "${PKG_DIR}/"
cp "template/${APP_NAME}.spec"    "${PKG_DIR}/"

docker run --rm \
  -v "${PKG_DIR}":/build \
  -v "${OUT_DIR}":/output \
  "coderus/sailfishos-platform-sdk:${SFOS_VERSION}" \
  /bin/bash -c "
    set -e; cd /build
    rpmbuild -bb ${APP_NAME}.spec --target aarch64 \
      --define '_builddir /build' --define '_rpmdir /output'
  "

echo "Done — RPM in ${OUT_DIR}/"
