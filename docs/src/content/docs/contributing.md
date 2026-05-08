---
title: Contributing
description: How to report bugs, run tests, and contribute to import-tree.
---

All contributions are welcome. PRs are checked by CI.

## Run Tests

`import-tree` uses [checkmate](https://github.com/denful/checkmate) for testing:

```sh
nix flake check github:denful/checkmate --override-input target path:.
```

## Format Code

```sh
nix run github:denful/checkmate#fmt
```

## Bug Reports

Open an [issue](https://github.com/denful/import-tree/issues) with a minimal reproduction.

If possible, include a failing test case — the test suite is in `checkmate/modules/tests.nix` and the test tree fixtures are in `checkmate/tree/`.

## Documentation

The documentation site lives under `./docs/`. It uses [Starlight](https://starlight.astro.build/).

To run locally:

```sh
cd docs && pnpm install && pnpm run dev
```
