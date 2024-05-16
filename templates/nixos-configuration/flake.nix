{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixos-ez-flake = {
      url = "github:name-snrl/nixos-ez-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ nixos-ez-flake, flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } rec {
      # Filesystem-based attribute set of module paths
      flake.moduleTree = nixos-ez-flake.mkModuleTree ./modules;
      # Import all flake-parts modules
      imports = nixos-ez-flake.importsFromAttrs { modules = flake.moduleTree.flake-parts; };
    };
}
