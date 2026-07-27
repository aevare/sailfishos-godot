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

rm -rf "${PKG_DIR}"
mkdir -p "${PKG_DIR}/icons" "${OUT_DIR}"

# Everything the spec's %install references has to be staged here.
cp "${BUILD_DIR}/${APP_NAME}"      "${PKG_DIR}/"
cp "${BUILD_DIR}/${APP_NAME}.pck"  "${PKG_DIR}/"
cp "template/${APP_NAME}.spec"     "${PKG_DIR}/"
cp "template/${APP_NAME}.desktop"  "${PKG_DIR}/"
cp "template/${APP_NAME}.profile"  "${PKG_DIR}/"
cp template/icons/*.png            "${PKG_DIR}/icons/"

# rpmbuild runs as the container's mersdk user, so the host-owned mounts must be
# writable by it — otherwise it fails with "cannot create /output/aarch64".
# Only the directories matter: RPMs from earlier runs are owned by the container
# user and can't be chmod'ed from the host.
chmod -R a+rwX "${PKG_DIR}"
chmod a+rwx "${OUT_DIR}" "${OUT_DIR}/aarch64" 2>/dev/null || true

docker run --rm \
  -v "${PKG_DIR}":/build \
  -v "${OUT_DIR}":/output \
  "coderus/sailfishos-platform-sdk:${SFOS_VERSION}" \
  /bin/bash -c "
    set -e; cd /build
    rpmbuild -bb ${APP_NAME}.spec --target aarch64 \
      --define '_builddir /build' --define '_rpmdir /output'
  "

echo "Done — RPM in ${OUT_DIR}/aarch64/"
