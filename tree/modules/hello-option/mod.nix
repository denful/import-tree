{ lib, ... }:
{
  options.hello = lib.mkOption {
    type = lib.types.str;
    default = "goodbye";
  };
}
