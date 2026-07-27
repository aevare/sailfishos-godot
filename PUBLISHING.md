# Publishing guide

Steps to publish the godot-sfos repo and its pre-built assets to GitHub.

Replace `GITHUB_USER` with your GitHub username or organisation name throughout.

---

## 1. Create the GitHub repo

Go to github.com, create a new repository named `godot-sfos` (public).

Then push the local code:

```bash
cd ~/Workspace/godot-sfos
git init
git add .
git commit -m "Initial release"
git remote add origin https://github.com/GITHUB_USER/godot-sfos.git
git branch -M main
git push -u origin main
```

---

## 2. Publish the template binaries via CI

The template binaries are built and attached to a GitHub Release automatically by
the [`build-templates.yml`](.github/workflows/build-templates.yml) workflow — no
manual compiling or uploading. Just push a version tag:

```bash
cd ~/Workspace/godot-sfos
git tag v4.4.1-auroraos-4      # tag names the Godot version + AuroraOS fork tag
git push origin v4.4.1-auroraos-4
```

The workflow then, for each supported SailfishOS release (5.0 / 5.1 / 5.2):

1. Cross-compiles the export template inside the `coderus/sailfishos-platform-sdk`
   Docker image (same as running `1-build-template.sh` locally).
2. Uploads each result as `linux_arm64-sfos<version>`.
3. Creates the Release for the tag with all binaries attached.

To test a build without publishing, use the **Run workflow** button (the
`workflow_dispatch` trigger) — it uploads the binaries as run artifacts and does
**not** create a release. You can override the Godot tag and the set of SFOS
versions there.

> The SailfishOS Platform SDK image does not need re-hosting — the build pulls
> `coderus/sailfishos-platform-sdk` from Docker Hub, which is public and kept
> current across releases.
