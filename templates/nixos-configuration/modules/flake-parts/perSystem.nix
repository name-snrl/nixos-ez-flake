{
  systems = [
    "x86_64-linux"
    "aarch64-linux"
    "aarch64-darwin"
    "x86_64-darwin"
  ];
  perSystem =
    # what `inputs'` is https://flake.parts/module-arguments#inputs
    { pkgs, inputs', ... }:
    {
      #packages.default = inputs'.foo.packages.bar;
      #
      #devShells.default =
      #  with pkgs;
      #  mkShellNoCC {
      #    packages = [
      #      # your packages here
      #    ];
      #  };
    };
}
