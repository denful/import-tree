{ lib, ... }:
{
  options.foo = lib.mkOption { default = foo; };
  options.scoped = lib.mkOption { default = builtins.scoped; };
  options.__nixPath = lib.mkOption { default = __nixPath; };
  options.nixPath = lib.mkOption { default = builtins.nixPath; };
}
