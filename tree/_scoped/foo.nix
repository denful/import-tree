{ lib, ... }:
{
  options.foo = lib.mkOption { default = foo; };
  options.__nixPath = lib.mkOption { default = __nixPath; };
  options.builtins = lib.mkOption { default = builtins; };
}
