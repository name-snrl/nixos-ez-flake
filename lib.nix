{ lib, ... }:
{
  flake = with lib; rec {
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
        importByDefault ? true,
        modules,
        imports ? { },
      }:
      let
        modulesToList =
          xs:
          flatten (
            mapAttrsToList (
              _: value:
              if isAttrs value then
                modulesToList value
              else if value == null then
                { }
              else
                throwIfNot (types.path.check value) "importsFromAttrs: 'modules' must be an attribute set of paths"
                  value
            ) xs
          );
        convertedImports = mapAttrsRecursive (
          setPath: value:
          throwIfNot (isBool value && hasAttrByPath setPath modules)
            "importsFromAttrs: the value of the '${concatStringsSep "." setPath}' attribute in 'imports' must be boolean and exist in modules"
            (if value then getAttrFromPath setPath modules else null)
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

    mkConfigurations =
      {
        configurations,
        inputs,
        globalImports ? [ ],
      }:
      mapAttrs (
        name: modules:
        nixosSystem {
          specialArgs = {
            inherit inputs importsFromAttrs;
          };
          modules =
            importsFromAttrs { inherit modules; } ++ [ { networking.hostName = name; } ] ++ globalImports;
        }
      ) configurations;
  };
}
