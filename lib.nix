{ lib, ... }:
{
  flake = with lib; rec {
    mkModuleTree =
      dir:
      mapAttrs' (
        name: type:
        if type == "directory" then
          nameValuePair name (mkModuleTree (dir + "/${name}"))
        else if name == "default.nix" then
          nameValuePair "self" (dir + "/${name}")
        else
          nameValuePair (removeSuffix ".nix" name) (dir + "/${name}")
      ) (filterAttrs (name: type: type == "directory" || hasSuffix ".nix" name) (builtins.readDir dir));

    importsFromAttrs =
      {
        importByDefault ? true,
        modules,
        imports ? { },
      }:
      let
        imports0 =
          if importByDefault then
            recursiveUpdate (mapAttrsRecursive (_: _: true) modules) imports
          else
            imports;

        # function that handles `_reverse` and `_reverseRecursive` values
        applyReverse =
          inputAttrs:
          let
            specials = [
              "_reverseRecursive"
              "_reverse"
            ];
            attrs = mapAttrsRecursive (
              setPath: value:
              throwIfNot (isBool value)
                "importsFromAttrs: the value of the '${concatStringsSep "." setPath}' attribute in 'imports' must be boolean"
                (
                  if inputAttrs ? _reverseRecursive then
                    if intersectLists setPath specials == [ ] then !value else value
                  else
                    value
                )
            ) inputAttrs;
            update =
              _: value:
              if isAttrs value then
                applyReverse value
              else if inputAttrs ? _reverse then
                !value
              else
                value;
          in
          throwIf (inputAttrs._reverse or false && inputAttrs._reverseRecursive or false)
            "importsFromAttrs: 'imports' can't contain '_reverse' and '_reverseRecursive' at the same level"
            removeAttrs
            (mapAttrs update attrs)
            specials;

        # convert 'imports' to values from 'modules' or nulls depending on the value
        convertedImports = mapAttrsRecursive (
          setPath: value:
          throwIfNot (hasAttrByPath setPath modules)
            "importsFromAttrs: the value of the '${concatStringsSep "." setPath}' attribute must exist in 'imports' and 'modules'"
            (if value then getAttrFromPath setPath modules else null)
        ) (applyReverse imports0);
      in
      collect (value: !(isAttrs value || value == null)) convertedImports;

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
            (entryPoint + "/${name}")
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
