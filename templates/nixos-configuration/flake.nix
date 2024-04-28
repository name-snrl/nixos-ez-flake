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
    (flake-parts.lib.mkFlake { inherit inputs; } {
      systems = [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
        "x86_64-darwin"
      ];
      imports = [
        ./hosts
        # any other imports:
        # ./shell.nix
      ];
    })
    // {
      # Filesystem-based attribute set of module paths
      nixosModules = nixos-ez-flake.mkModuleTree ./modules;
    };
}
