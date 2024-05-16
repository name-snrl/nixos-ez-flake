{ lib, inputs, ... }:
{
  flake = {
    nixosConfigurations = inputs.nixos-ez-flake.mkConfigurations {
      inherit inputs;
      inherit (inputs.self.moduleTree.nixos) configurations;
      globalImports = [ ];
    };
    # Example of an overlay that adds an underline colors patch to the foot terminal
    #overlays.default = final: prev: {
    #  foot = prev.foot.overrideAttrs (oa: {
    #    __contentAddressed = true;
    #    patches = [
    #      (final.fetchpatch {
    #        url = "https://codeberg.org/dnkl/foot/pulls/1099.patch";
    #        hash = "sha256-4B+PanJqBC3hANgSYXwXeGO19EBdVMyyIgGawpaIMxE=";
    #      })
    #    ];
    #    mesonFlags = oa.mesonFlags ++ [ "-Dext-underline=enabled" ];
    #  });
    #};
  };
}
