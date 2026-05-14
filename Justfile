system := `nix-instantiate --eval --raw -E builtins.currentSystem`

help:
  just -l

ci:
  just fmt -- --ci --no-cache
  just test

fmt *args:
  nix run github:denful/checkmate#fmt --override-input target path:. {{args}}

test *args:
  nix flake check github:denful/checkmate --override-input target . {{args}}

