#!/usr/bin/env bash
# Build the Godot SailfishOS arm64 export template from the AuroraOS fork.
#
# Why this exists: pre-built Godot templates link against glibc 2.32+, but
# SailfishOS ships glibc ≤2.31. Building inside the SailfishOS Platform SDK
# cross-compiles against the SailfishOS sysroot so the binary runs on-device.
#
# The savegame/godot fork adds AuroraOS/SailfishOS Wayland support to
# platform=linuxbsd via an "auroraos=yes" SCons flag. This enables the
# qt_surface_extension Wayland protocol (needed for the lipstick compositor),
# disables X11, and adds AURORAOS_ENABLED compile defines.
#
# Output: godot-templates/linux_arm64
#
# Requirements: Docker, git, ~10 GB free disk, ~1 h build time

set -euo pipefail

# ── Configure ─────────────────────────────────────────────────────────────────
GODOT_TAG="${GODOT_TAG:-4.4.1-auroraos-4}"   # tag from https://github.com/savegame/godot
SFOS_VERSION="${SFOS_VERSION:-5.1.0.11}"     # coderus/sailfishos-platform-sdk tag, pulled automatically
# ─────────────────────────────────────────────────────────────────────────────

GODOT_REPO="https://github.com/savegame/godot.git"
SFOS_TARGET="SailfishOS-${SFOS_VERSION}-aarch64"
SDK_IMAGE="coderus/sailfishos-platform-sdk:${SFOS_VERSION}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SRC_DIR="${SCRIPT_DIR}/godot-src"
OUT_DIR="${SCRIPT_DIR}/godot-templates"
BINARY_NAME="godot.linuxbsd.template_release.arm64"

if [[ ! -d "${SRC_DIR}/.git" ]]; then
  echo "Cloning AuroraOS Godot fork at ${GODOT_TAG}…"
  git clone --depth 1 --branch "${GODOT_TAG}" "${GODOT_REPO}" "${SRC_DIR}"
else
  echo "Using existing source at ${SRC_DIR}"
fi

mkdir -p "${OUT_DIR}"

INNER_SCRIPT="$(mktemp /tmp/godot-sfos-build-XXXXXX.sh)"
trap 'rm -f "${INNER_SCRIPT}"' EXIT

cat > "${INNER_SCRIPT}" << 'INNEREOF'
#!/bin/bash
set -e

SFOS_TARGET="${SFOS_TARGET}"
BINARY_NAME="${BINARY_NAME}"

echo "=== Installing SCons ==="
if ! command -v scons &>/dev/null; then
    python3 -m pip install --quiet scons 2>/dev/null || \
    (python3 -m ensurepip --upgrade && python3 -m pip install --quiet scons 2>/dev/null) || \
    zypper --non-interactive install -y scons
fi
export PATH="${HOME}/.local/bin:${PATH}"

echo "=== Installing wayland-scanner (host side) ==="
zypper --non-interactive install -y wayland-tools 2>/dev/null || \
zypper --non-interactive install -y wayland 2>/dev/null || true

echo "=== Installing build deps into ${SFOS_TARGET} sysroot ==="
sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install \
        wayland-devel libxkbcommon-devel glib2-devel pkgconfig SDL2-devel \
    || true

sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install libGLESv2-devel libEGL-devel \
    2>/dev/null || \
sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install mesa-llvmpipe-libGLESv2-devel \
    2>/dev/null || true

sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install \
        mesa-llvmpipe-libwayland-egl-devel 2>/dev/null || \
sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install \
        libwayland-egl-devel 2>/dev/null || \
sb2 -t "${SFOS_TARGET}" -R -m sdk-install \
    zypper --non-interactive install \
        wayland-egl-devel 2>/dev/null || true

echo "=== Cross-compiling Godot for aarch64 ==="
cd /home/mersdk/godot

sb2 -t "${SFOS_TARGET}" \
    scons platform=linuxbsd auroraos=yes arch=arm64 target=template_release \
          opengl3=yes vulkan=no \
          x11=no wayland=yes \
          use_sowrap=no use_static_cpp=no \
          module_openxr_enabled=no \
          optimize=size debug_symbols=no \
          -j"$(nproc)"

echo "=== Copying output ==="
cp "bin/${BINARY_NAME}" /home/mersdk/output/linux_arm64
chmod 755 /home/mersdk/output/linux_arm64

SIZE=$(du -sh /home/mersdk/output/linux_arm64 | cut -f1)
echo "Template built: /home/mersdk/output/linux_arm64 (${SIZE})"
INNEREOF

chmod 755 "${INNER_SCRIPT}"

chmod -R a+rwX "${SRC_DIR}" 2>/dev/null || true
mkdir -p "${SRC_DIR}/bin"
mkdir -p "${OUT_DIR}"
chmod a+rwx "${SRC_DIR}/bin" "${OUT_DIR}" 2>/dev/null || true

if docker image inspect "${SDK_IMAGE}" &>/dev/null; then
    echo "Using local image ${SDK_IMAGE}"
else
    echo "Pulling ${SDK_IMAGE}…"
    docker pull "${SDK_IMAGE}"
fi

echo "Building inside Platform SDK (${SDK_IMAGE})…"
echo "This will take ~1 hour."
echo ""

docker run --rm \
  --privileged \
  -e SFOS_TARGET="${SFOS_TARGET}" \
  -e BINARY_NAME="${BINARY_NAME}" \
  -v "${SRC_DIR}":/home/mersdk/godot \
  -v "${OUT_DIR}":/home/mersdk/output \
  -v "${INNER_SCRIPT}":/tmp/build.sh:ro \
  "${SDK_IMAGE}" \
  /bin/bash /tmp/build.sh

echo ""
echo "Done: ${OUT_DIR}/linux_arm64"
echo ""
echo "In your Godot project, set this as your Linux export template path."
