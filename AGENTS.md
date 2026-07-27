# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## What this is

A build-and-packaging toolkit (not an app) that turns a Godot 4 project into an installable SailfishOS RPM. There is no source code to compile here and no test/lint suite — the "code" is three shell/YAML pipelines plus an RPM packaging scaffold. All heavy lifting runs inside the `coderus/sailfishos-platform-sdk` Docker image, which is pulled automatically.

## Pipeline (the big picture)

The flow is two scripts with a manual Godot export in between:

1. **`1-build-template.sh`** → produces a Godot *export template* (`godot-templates/linux_arm64`). It clones the `savegame/godot` fork and does a **scratchbox2 (`sb2`) cross-compile** inside the SDK container: an x86 host builds an aarch64 binary against the SailfishOS sysroot (`scons platform=linuxbsd auroraos=yes arch=arm64 ...`). This is why it needs the SDK, not just a compiler. Done once per (Godot tag × SFOS release).
2. **Export step (Godot editor, or headless in the `barichello/godot-ci` image):** use that template in a Linux/X11 export preset — arm64, `embed_pck=false` — to emit `build/harbour-APPNAME` + `.pck`. See README Step 2.
3. **`2-package.sh`** → stages the exported binary + `.pck` and the whole `template/` scaffold into `sfos-pkg/`, then wraps them into an aarch64 RPM by running `rpmbuild -bb` inside the same SDK image.

`.github/workflows/build-templates.yml` runs step 1 in CI as a matrix over SFOS releases (5.0/5.1/5.2) and publishes each `linux_arm64-sfos<version>` binary as a GitHub Release asset on `v*` tag pushes (`workflow_dispatch` builds artifacts only, for testing).

## Commands

```bash
# Build the export template (env vars override the in-script defaults)
GODOT_TAG=4.4.1-auroraos-4 SFOS_VERSION=5.1.0.11 ./1-build-template.sh

# Package an already-exported game into an RPM (edit APP_NAME/SFOS_VERSION at top first)
./2-package.sh

# Publish templates via CI: push a version tag
git tag v4.4.1 && git push origin v4.4.1
```

`SFOS_VERSION` must be a published `coderus/sailfishos-platform-sdk` tag.

## Non-obvious constraints (hard-won; don't regress these)

- **Match the SDK release to the target device release** — and not only for glibc. A template built with the 5.0 SDK *rendered incorrectly* on a 5.1 device (portrait orientation not applied); the Wayland/orientation path is compiled against the sysroot. See README "SailfishOS version compatibility". CI builds one template per release for exactly this reason.
- **`project.godot` orientation must be an integer** (`window/handheld/orientation=1`), never the string `"portrait"` — the string casts to `0` (landscape) and the game renders broken. Documented in README "Critical Godot project setting".
- **RPM spec quirks** (`template/harbour-mygame.spec`): strip is disabled (`__strip /bin/true`) because the binary is pre-built and stripped on a cross-arch host; `Requires: SDL2` only — do **not** add `libEGL`/`libGLESv2`, they come from the hybris GPU stack and aren't RPM capabilities (declaring them breaks install).
- **Sailjail profile** must `noblacklist` the hybris paths (`/system`, `/vendor`, `/odm`, droid-hybris) or the GLES/EGL driver won't load.
- **`.desktop` Exec** launches with `--rendering-driver opengl3_es --main-pack .../<app>.pck` (device only exposes GLES, not desktop GL). This is why the export must keep `embed_pck=false` and be named exactly `APP_NAME`.
- **Container-user file ownership**: `rpmbuild` runs as `mersdk` inside the SDK image, so `sfos-pkg/` and `RPMS/` must be `chmod a+rwX` before the run, and the RPMs it writes come back owned by uid 100000 (don't `chmod -R` over them from the host — it fails).

## Conventions

- **Placeholder name is `harbour-mygame`** everywhere in `template/` (filenames + file contents) and `APP_NAME` in `2-package.sh`. To adapt for a real app, rename all of these consistently; the Harbour store requires a `harbour-*` prefix.
- **AuroraOS naming:** keep "AuroraOS" only where it names the upstream `savegame/godot` fork or its `auroraos=yes` build flag (and the `4.4.1-auroraos-4` tag). Everywhere project-facing, use "SailfishOS".
- **Release tags** are `v<godot-version>` (e.g. `v4.4.1`), with a `-N` suffix for rebuilds of the same Godot version — not mirrors of the upstream fork tag.
