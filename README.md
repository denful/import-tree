<p align="right">
  <a href="https://dendritic.oeiuwq.com/sponsor"><img src="https://img.shields.io/badge/sponsor-denful-white?logo=githubsponsors&logoColor=white&labelColor=%23FF0000" alt="Sponsor Vic"/>
  </a>
  <a href="https://dendritic.oeiuwq.com"> <img src="https://img.shields.io/badge/Dendritic-Nix-informational?logo=nixos&logoColor=white" alt="Dendritic Nix"/> </a>
  <a href="LICENSE"> <img src="https://img.shields.io/github/license/denful/import-tree" alt="License"/> </a>
  <a href="https://github.com/denful/import-tree/actions">
  <img src="https://github.com/denful/import-tree/actions/workflows/test.yml/badge.svg" alt="CI Status"/> </a>
</p>

> `import-tree` and [denful](https://bsky.app/profile/oeiuwq.bsky.social)'s [dendritic libs](https://dendritic.oeiuwq.com) made for you with Love++ and AI--. If you like my work, consider [sponsoring](https://dendritic.oeiuwq.com/sponsor)

# 🌲🌴 import-tree 🎄🌳

> Recursively import [Nix modules](https://nix.dev/tutorials/module-system/) from a directory, with a simple, extensible API.

## Features

🌳 Works with NixOS, nix-darwin, home-manager, flake-parts, NixVim, etc.\
🌲 Callable as a deps-free Flake or nix lib.\
🌴 Sensible defaults and configurable behaviour.\
🌵 Chain `.filter`, `.match`, `.map` for precise file selection.\
🎄 Extensible: `.addAPI` to create domain-specific instances.\
🌿 Built to enable the [Dendritic Pattern](https://github.com/mightyiam/dendritic) on both stable/unstable Nix.\
🌱 [Growing](https://github.com/search?q=language%3ANix+import-tree&type=code) [community](https://denful.github.io/dendrix/Dendrix-Trees.html) [adoption](https://github.com/denful/flake-file)

## Quick Start

The following examples show how to import all module files.
By default, paths having `/_` are ignored. See API documentation for advanced usage.

> Related projects: [denful/flake-file](https://github.com/denful/flake-file), [denful/with-inputs](https://github.com/denful/with-inputs)

### Dendritic flake-parts

```nix
# flake.nix
{
  inputs.import-tree.url = "github:denful/import-tree";
  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; }
   (inputs.import-tree ./modules);
}
```

### Dendritic flake without flake-parts

```nix
# flake.nix
{
  inputs.import-tree.url = "github:denful/import-tree";
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

  outputs = inputs:
   (inputs.nixpkgs.lib.evalModules {
      specialArgs.inputs = inputs;
      modules = [ (inputs.import-tree ./modules)  ];
   }).config;
}
```

### Dendritic Nix (non-flakes, stable Nix)

This example uses [with-inputs](https://github.com/denful/with-inputs) to provide flake-file inputs from [npins](https://github.com/andir/npins) sources.

```nix
# default.nix
let
  sources = import ./npins;
  with-inputs = import sources.with-inputs sources {};
  outputs = inputs:
   (inputs.nixpkgs.lib.evalModules {
      specialArgs.inputs = inputs;
      modules = [ (inputs.import-tree ./modules)  ];
   }).config;
in
with-inputs outputs
```

## Documentation

📖 **[Full documentation](https://import-tree.oeiuwq.com)** — guides, API reference, and examples.

## Testing

`import-tree` uses [`checkmate`](https://github.com/denful/checkmate) for testing:

```sh
nix flake check github:denful/checkmate --override-input target path:.
```
