# mirror-nodejs

OCX mirror for [Node.js](https://nodejs.org). One repository, one spec
directory per package.

| Package | Spec | Publishes to | Announced as | Upstream SPDX |
|---|---|---|---|---|
| [node](https://github.com/nodejs/node) | [`node/mirror.yml`](node/mirror.yml) | `ghcr.io/ocx-contrib/nodejs/node` | `ocx.sh/nodejs/node` | `MIT` |

Each upstream release is discovered, re-bundled, smoke-tested per
`(version, platform)` and only then pushed with cascade tags, after which the
result is announced into the OCX index.

> This repository previously published the same upstream to the flat coordinate
> `ocx.sh/nodejs`. `nodejs/node` is the grouped successor, and mirrors
> upstream's own coordinates — the OpenJS Foundation org is `nodejs` and the
> binary is `node`.

Node ships **no GitHub release assets** — the tarballs live on the nodejs.org
CDN and the release list is a JSON index at `https://nodejs.org/dist/index.json`
— so `node/scripts/generate.py` fetches that index and reshapes it into a
`url_index`. The script uses
[`ocx-mirror-sdk`](https://github.com/ocx-sh/ocx-mirror-sdk), pinned to a
published wheel via PEP 723 inline metadata; `uv` is its runtime and is pinned
in [`ocx.toml`](ocx.toml).

## Layout

```
mirror-base.yml         repo-wide policy every spec inherits via `extends:`
node/
├── mirror.yml          the spec — never at the repo root
├── metadata.json       bundle interface (+ metadata-windows.json override)
├── CATALOG.md          → ocx package describe
├── logo.svg / logo.png describe assets, 512px PNG
├── scripts/generate.py url_index generator
└── tests/smoke.star    Starlark smoke test
```

`LICENSE` and `NOTICE.md` are shared at the root. Logos are **not** — a
repo-root `logo.*` sits in no workflow's `paths:` filter, so replacing it would
publish nothing until some unrelated edit happened to fire.

⚠️ `extends:` is a **shallow** merge of top-level keys. A spec that restates
`platforms:` to change one runner drops every `containers:` entry with it, and
nothing reds — the legs simply stop existing, and every `os.features` claim
goes back to being asserted rather than verified. Restate a block in full or
not at all.

## Platforms

Six platform entries: both Linux arches, both macOS arches and both Windows
arches.

| Key | Asset | Requires | Container legs |
|---|---|---|---|
| `linux/{amd64,arm64}+libc.glibc` | `node-v<ver>-linux-{x64,arm64}.tar.xz` | a glibc loader | `ubuntu:24.04`, `fedora:40` |
| `darwin/{amd64,arm64}` | `node-v<ver>-darwin-{x64,arm64}.tar.gz` | — | — |
| `windows/{amd64,arm64}` | `node-v<ver>-win-{x64,arm64}.zip` | — | — |

`os.features` states what an artifact **requires of the host**, not how it was
built. The official Linux builds are **dynamically glibc-linked** — `bin/node`
carries `PT_INTERP /lib64/ld-linux-x86-64.so.2` and needs `libstdc++.so.6` and
`libgcc_s.so.1` — so both Linux keys carry `+libc.glibc`. The flat layout's
bare keys were a false universality claim: an empty `os.features` also matches
musl hosts, where these binaries cannot load at all. The measurement is
recorded above the `assets:` block in [`node/mirror.yml`](node/mirror.yml), and
the ubuntu + fedora container legs in `mirror-base.yml` are what turn the claim
into evidence. There is no alpine leg — a glibc build cannot load under musl,
and the renderer rejects an alpine leg on a glibc key outright.

There is deliberately **no `+libc.musl`**. `nodejs.org/dist` publishes zero musl
builds; the only source is `unofficial-builds.nodejs.org`, whose arm64 coverage
is version-gated, whose integrity material is an unsigned `SHASUMS256.txt` on
the same host, and which offers no retention guarantee.

## Archive shape

`strip_components: 1` removes the `node-v<version>-<platform>/` wrapper on every
platform. On unix that leaves `bin/`, `lib/`, `include/` and `share/` side by
side, and side by side is load-bearing: `bin/npm`, `bin/npx` and `bin/corepack`
are **relative symlinks** into `../lib/node_modules/…`, so they stay unbroken
only because `lib/` extracts alongside `bin/`. (Verified in the built bundle:
they survive as symlinks, and `node/tests/smoke.star` runs `npm --version` to
prove the link plus its `#!/usr/bin/env node` shebang resolve.)

The Windows zip has **no `bin/` at all** — `node.exe`, `npm.cmd`, `npx.cmd` and
`node_modules/` sit at the archive root — which is why windows routes through
`node/metadata-windows.json` with a bare `${installPath}` on PATH.

## The binaries claim

`mirror-base.yml` sets `bin_scan: off` and both metadata files hand-list
`binaries: ["node", "npm", "npx", "corepack"]`. It cannot be otherwise: the
scan only looks *below* an `${installPath}/<dir>` PATH entry, and the load gate
checks **every** metadata file a spec's `metadata:` block can select. Windows's
entry is a bare `${installPath}`, so `auto`/`verify` is rejected at spec load
with exit 65. Keeping the archive wrapper on Windows (`strip_components: 0`)
would not help either — Node's wrapper is `node-v<version>-win-x64/`, a
version-dependent name no static metadata file can point PATH at.

## Editing

| File | Edit | Regenerate after |
|------|------|------------------|
| `mirror-base.yml`, `node/mirror.yml` | hand | yes — see below |
| `node/{metadata*.json,CATALOG.md,logo.*}` | hand | — |
| `node/tests/smoke.star`, `node/scripts/*` | hand | — |
| `.github/workflows/*.yml` | **generated — never hand-edit** | re-run when a spec changes |

```bash
ocx-mirror package pipeline generate ci --spec node/mirror.yml
```

**Name every spec.** `--spec` *appends* rather than replaces, so a command
naming a subset silently stops rendering the rest while staying green — and the
drift guard reds on a generated workflow the current spec set no longer
produces.

`verify-generated.yml` exits 65 on drift. If a generated workflow is wrong, the
spec or the renderer template is wrong — fix it there and regenerate.

Run `direnv allow` once to put the pinned toolchain on `PATH`, and invoke
`ocx-mirror` directly — never `ocx run -- ocx-mirror`, which pins
`OCX_BINARY_PIN` to the bootstrap `ocx` and false-reds the nested push.

### Bumping the SDK pin

Edit the `[tool.uv.sources]` block at the top of `node/scripts/generate.py` to
point at a newer wheel:

```toml
ocx-mirror-sdk = { url = "https://github.com/ocx-sh/ocx-mirror-sdk/releases/download/vX.Y.Z/ocx_mirror_sdk-X.Y.Z-py3-none-any.whl" }
```

## Required secrets

| Secret | Use |
|--------|-----|
| `OCX_ANNOUNCE_TOKEN` | opens the index pull request from the `ocx-contrib/index` fork |
| `OCX_MIRROR_DISCORD_HOOK` | notify-stage Discord webhook URL |

(Inherited from the `ocx-contrib` org with visibility ALL. GHCR pushes use the
run's own `GITHUB_TOKEN` — no registry secret needed.)

## License

Apache-2.0 — see [`LICENSE`](LICENSE). Upstream assets are out of scope; each
package's redistribution license is recorded in [`NOTICE.md`](NOTICE.md).
