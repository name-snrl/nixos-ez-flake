{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs.nixpkgs.follows = "nixpkgs";
      inputs.nixpkgs-stable.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{ flake-parts, ... }:
    flake-parts.lib.mkFlake { inherit inputs; } (
      { lib, ... }:
      {
        imports = with inputs; [
          pre-commit-hooks-nix.flakeModule
          treefmt-nix.flakeModule
        ];

        systems = lib.systems.flakeExposed;

        perSystem =
          { pkgs, config, ... }:
          {
            devShells.default = pkgs.mkShellNoCC { shellHook = config.pre-commit.installationScript; };

            pre-commit.settings.hooks = {
              treefmt = {
                enable = true;
                package = config.treefmt.build.wrapper;
              };
              statix = {
                enable = true; # check. not everything can be fixed, but we need to know what
                settings.format = "stderr";
              };
            };

            treefmt = {
              projectRootFile = "flake.nix";
              programs = {
                nixfmt.enable = true;
                deadnix.enable = true;
                statix.enable = true; # fix, if possible
                mdformat.enable = true;
                mdformat.package = pkgs.mdformat.withPlugins (
                  p: with p; [
                    mdformat-gfm
                    mdformat-frontmatter
                    mdformat-footnote
                  ]
                );
              };
              settings.formatter = {
                mdformat.options = [
                  "--wrap"
                  "80"
                ];
              };
            };
          };
      }
    );
}
