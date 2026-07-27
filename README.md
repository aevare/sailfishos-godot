# godot-sfos

Scripts and packaging templates for building and distributing a Godot 4 game on SailfishOS.

Tested with **Godot 4.4.1** and **SailfishOS 5.1** on an aarch64 device.

---

## How it works

SailfishOS ships with an older glibc (≤ 2.31). Pre-built Godot export templates link against glibc 2.32+, so they fail with a symbol error on-device. The solution is to cross-compile the template inside the SailfishOS Platform SDK, which targets the SailfishOS sysroot and produces a compatible binary.

The [savegame/godot](https://github.com/savegame/godot) fork adds SailfishOS Wayland support to the `platform=linuxbsd` backend. This enables the `qt_surface_extension` Wayland protocol required by the SailfishOS lipstick compositor.

---

## Prerequisites

- Docker
- ~10 GB free disk space
- ~1 h build time (template compile)

The SailfishOS Platform SDK image is pulled automatically from Docker Hub ([`coderus/sailfishos-platform-sdk`](https://hub.docker.com/r/coderus/sailfishos-platform-sdk/tags)), which is kept up to date across releases (5.1, 5.2, …). No manual SDK build is required.

---

## Pre-built templates (download instead of building)

Each release attaches a pre-built export template per SailfishOS version, so you can skip the ~1 hour local build. Grab the asset matching **your device's SailfishOS release** from the [Releases page](../../releases):

| SailfishOS release | Asset |
|--------------------|-------|
| 5.0 | `linux_arm64-sfos5.0.0.43` |
| 5.1 | `linux_arm64-sfos5.1.0.11` |
| 5.2 | `linux_arm64-sfos5.2.0.15` |

Download the matching file, save it as `godot-templates/linux_arm64` in your checkout (or point Godot's Linux/X11 export template path straight at it), then jump to [Step 2](#step-2--export-your-game-from-godot).

> Choosing the right release matters — a template built for one release can render incorrectly on another. See [SailfishOS version compatibility](#sailfishos-version-compatibility).

These binaries are produced automatically by the [`build-templates.yml`](.github/workflows/build-templates.yml) GitHub Actions workflow.

---

## Quick start

### Step 1 — Build the Godot arm64 export template

> Skip this step if you downloaded a pre-built template above.

```bash
./1-build-template.sh
```

Set `GODOT_TAG` and `SFOS_VERSION` at the top of the script (or pass them as environment variables). `SFOS_VERSION` must be a tag published for `coderus/sailfishos-platform-sdk` — the image is pulled automatically on first run. Output: `godot-templates/linux_arm64`. This takes about an hour.

### Step 2 — Export your game from Godot

In Godot's export dialog, add a **Linux/X11** export preset. Set the custom template path to the `godot-templates/linux_arm64` file you just built. Export to `build/harbour-mygame` (no extension) — Godot will produce both the binary and the `.pck` file.

### Step 3 — Package as RPM

Rename the files in `template/` from `harbour-mygame` to your app name, edit them (see [Customising the template](#customising-the-template) below), then:

```bash
./2-package.sh
```

Set `APP_NAME` at the top of the script to match. Output: `RPMS/aarch64/harbour-mygame-1.0.0-1.aarch64.rpm`.

---

## Customising the template

Copy the `template/` folder and rename all files from `harbour-mygame` to your app name. Then edit:

| File | What to change |
|------|----------------|
| `harbour-mygame.spec` | `Name`, `Version`, `Summary`, `%description`, `%changelog` — and rename all `harbour-mygame` references |
| `harbour-mygame.desktop` | `Name`, `Comment`, `OrganizationName`, `ApplicationName` |
| `harbour-mygame.profile` | Rename only — content is the same for all Godot games |
| `icons/*.png` | Replace with your own icons at each size (86, 108, 128, 172 px) |

> **SailfishOS naming rule:** apps distributed via the Harbour store must be named `harbour-*`. If you are only sideloading or using OpenRepos you can use any name, but `harbour-` is a safe convention regardless.

---

## Critical Godot project setting

In your `project.godot`, the orientation **must** be stored as an integer, not a string:

```ini
[display]
window/handheld/orientation=1
```

Do **not** use `window/handheld/orientation="portrait"`. Godot reads this setting as an int at startup; the string `"portrait"` is cast to `0`, which equals `SCREEN_LANDSCAPE`. The SailfishOS Wayland backend then applies a 270° buffer transform, the compositor reconfigures the window to landscape dimensions, and the game renders broken (top portion only, no touch input).

Integer values:
- `0` = Landscape
- `1` = Portrait
- `2` = Reverse landscape
- `3` = Reverse portrait

---

## SailfishOS version compatibility

The template binary links against the glibc version in the SDK you build with. A binary built with the **5.1 SDK** requires `GLIBC_2.38` and will **not** run on SailfishOS 4.6 or earlier. To support older devices, build with the matching SDK version.

**Rendering, not just linking.** Matching the SDK to the target release matters beyond glibc. A template built with the **5.0 SDK** rendered incorrectly on a **5.1 device** (portrait orientation was not applied), fixed only by rebuilding against the 5.1 SDK. The SailfishOS Wayland/orientation path is compiled against the sysroot and does not stay correct across major releases — build with the SDK that matches the device's release.

---

## Platform detection in GDScript

To detect SailfishOS at runtime and adjust your UI (e.g. hide sound controls, which do not work on SailfishOS without additional setup):

```gdscript
var is_sfos := OS.get_distribution_name().to_lower().contains("sailfish")
```

---

## Credits

- [savegame/godot](https://github.com/savegame/godot) — AuroraOS/SailfishOS Godot fork
- [coderus/sailfishos-platform-sdk](https://hub.docker.com/r/coderus/sailfishos-platform-sdk) — pre-built SailfishOS Platform SDK Docker images
