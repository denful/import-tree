{ lib, ... }:
{
  options.foo = lib.mkOption { default = foo; };
}
