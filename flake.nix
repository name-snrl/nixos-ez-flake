{
  description = ''
    Two simple functions to help you work with imports in configurations that use
    the NixOS module system, such as home-manager, flake-parts, nix-darwin, etc.
  '';

  inputs.flake-parts.url = "github:hercules-ci/flake-parts";

  outputs =
    inputs@{ flake-parts, ... }:
    (flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./lib.nix
        ./templates
      ];
    });
}
