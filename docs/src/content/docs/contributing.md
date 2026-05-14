---
title: Contributing
description: How to report bugs, run tests, and contribute to import-tree.
---

All contributions are welcome. PRs are checked by CI.

## Run Tests

Load development environment from `./shell.nix`

```sh
just ci
```

## Format Code

```sh
just fmt
```

## Bug Reports

Open an [issue](https://github.com/denful/import-tree/issues) with a minimal reproduction.

If possible, include a failing test case: the test suite is in `tests.nix` and the test tree fixtures are in `tree/`.

## Documentation

The documentation site lives under `./docs/`. It uses [Starlight](https://starlight.astro.build/).

To run locally:

```sh
just docs
```
