{
  description = "Filesystem-based NixOS configuration";

  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

  outputs =
    { self, nixpkgs }:
    with nixpkgs.lib;
    rec {
      mkModuleTree =
        dir:
        mapAttrs' (
          name: type:
          if type == "directory" then
            nameValuePair name (mkModuleTree /${dir}/${name})
          else if name == "default.nix" then
            nameValuePair "self" /${dir}/${name}
          else
            nameValuePair (removeSuffix ".nix" name) /${dir}/${name}
        ) (filterAttrs (name: type: type == "directory" || hasSuffix ".nix" name) (builtins.readDir dir));

      importsFromAttrs =
        {
          importByDefault,
          modules,
          imports,
        }:
        let
          modulesToList = xs: flatten (mapAttrsToList (_: v: if isPath v then v else modulesToList v) xs);
          convertedImports = mapAttrsRecursive (
            path: value:
            throwIfNot (isBool value && hasAttrByPath path modules)
              "Check the path ${concatStringsSep "." path}, the value should be of type boolean and exist in modules"
              (if value then getAttrFromPath path modules else { })
          ) imports;
        in
        modulesToList (
          if importByDefault then recursiveUpdate modules convertedImports else convertedImports
        );

      mkHosts =
        {
          entryPoint,
          inputs,
          globalImports ? [ ],
        }:
        genAttrs (attrNames (filterAttrs (_: type: type == "directory") (builtins.readDir entryPoint))) (
          name:
          nixosSystem {
            specialArgs = {
              inherit inputs importsFromAttrs;
            };
            modules = [
              /${entryPoint}/${name}
              { networking.hostName = name; }
            ] ++ globalImports;
          }
        );
    };
}
