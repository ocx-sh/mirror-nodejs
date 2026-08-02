# node/tests/smoke.star — stable across upstream Node.js releases.
# Asserts behavior/contract (exit codes, version digits, computed output),
# never upstream-controlled prose. See testing-practices.md.
WINDOWS = ocx.target_platform.os == ocx.os.Windows
NODE = "node.exe" if WINDOWS else "node"
NPM = "npm.cmd" if WINDOWS else "npm"

# Keep npm entirely inside the scratch dir: no ~/.npmrc read, no cache written
# to the runner's real HOME, and — with `--version` and `-e` the only commands
# run — no request to the npm registry at all.
HOME = {
    "HOME": ocx.scratch_root,
    "USERPROFILE": ocx.scratch_root,
    "XDG_CONFIG_HOME": ocx.scratch_root + "/config",
    "XDG_CACHE_HOME": ocx.scratch_root + "/cache",
    "XDG_DATA_HOME": ocx.scratch_root + "/data",
    "npm_config_cache": ocx.scratch_root + "/npm-cache",
    "npm_config_update_notifier": "false",
}

# Tier 1 + 2: liveness on the composed PATH + version shape.
r_version = ocx.run(NODE, "--version", env = HOME)
expect.ok(r_version)
expect.matches(r_version.stdout, r"\d+\.\d+\.\d+")

# Tier 3: functional behavior on hermetic input — assert the computed result.
# Inline evaluation exercises the V8 runtime, not a help short-circuit.
r_eval = ocx.run(NODE, "-e", "console.log(2 + 2)", env = HOME)
expect.ok(r_eval)
expect.contains(r_eval.stdout, "4")

# Tier 3: execute a script file and assert structured output (JSON round-trip).
ocx.write_file("hello.js", "console.log(JSON.stringify({ok: true, n: 7}))\n")
r_run = ocx.run(NODE, "hello.js", env = HOME)
expect.ok(r_run)
expect.contains(r_run.stdout, "\"ok\":true")

# Tier 3: npm is the fragile half of the bundle's `binaries` claim. On unix
# `bin/npm` is a RELATIVE symlink into `../lib/node_modules/npm/bin/npm-cli.js`
# — running it proves the link survived extraction unbroken AND that its
# `#!/usr/bin/env node` shebang resolves `node` off the same composed PATH.
# `--version` is offline; nothing here touches the npm registry.
r_npm = ocx.run(NPM, "--version", env = HOME)
expect.ok(r_npm)
expect.matches(r_npm.stdout, r"\d+\.\d+\.\d+")

# No Tier 4: metadata.json declares only PATH (proven by Tier-1 liveness).
