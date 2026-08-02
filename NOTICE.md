# NOTICE

This repository packages and redistributes upstream software published by the
[OpenJS Foundation](https://openjsf.org) and the Node.js contributors. The
Apache-2.0 license in [`LICENSE`](LICENSE) covers the OCX pipeline files
authored here. It does **not** cover any upstream-derived asset — each
package's redistributed bytes carry their own license, recorded below.

Each package's logo is reproduced for catalog identification only, under
nominative fair use. The marks remain the property of their respective owners
and no endorsement is implied.

| Package | GHCR path | Upstream SPDX |
|---|---|---|
| `node` | `ghcr.io/ocx-contrib/nodejs/node` | `MIT` |

---

## `node`

Upstream: <https://nodejs.org> (source: <https://github.com/nodejs/node>)
Published to `ghcr.io/ocx-contrib/nodejs/node`.

| Component | SPDX | Holder |
|---|---|---|
| Node.js runtime (`node`) | **MIT** | Copyright Node.js contributors |
| npm / npx (`lib/node_modules/npm`) | **Artistic-2.0** | Copyright npm, Inc. and Contributors |
| corepack (`lib/node_modules/corepack`) | **MIT** | Copyright Corepack contributors |

Permissive; redistribution of the compiled binaries is granted provided the
copyright and permission notices are retained. Every mirrored archive ships
upstream's own `LICENSE` file **byte-for-byte at the bundle root**, so the
notice travels with the bytes.

That `LICENSE` is a ~2900-line aggregate: the MIT grant for Node.js itself,
followed by the notices of every component Node statically links or vendors —
V8 (BSD-3-Clause), libuv (MIT), OpenSSL (Apache-2.0), zlib, c-ares, llhttp,
ICU (Unicode-3.0), undici, ngtcp2, simdutf and others, all permissive. That
aggregate is also why `gh api repos/nodejs/node/license` answers `NOASSERTION`
— GitHub's classifier cannot reduce it to one id — while the project's own
license is unambiguously MIT. The mirror's
`org.opencontainers.image.licenses` annotation records `MIT` accordingly.

The Node.js and npm names and logos are used for catalog identification under
nominative fair use; the Node.js mark is a trademark of the OpenJS Foundation.

No modifications are made to any upstream artifact in this repository; they are
republished byte-for-byte inside an OCX bundle.
