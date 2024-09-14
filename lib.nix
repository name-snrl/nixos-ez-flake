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
        specials = [
          "_reverseRecursive"
          "_reverse"
        ];

        validate =
          let
            header = "\nimportsFromAttrs:";
            recurse =
              setPath: imports:
              throwIf (imports._reverse or false && imports._reverseRecursive or false)
                ''
                  ${header}
                    '${concatStringsSep "." setPath}' contains '_reverse' and
                    '_reverseRecursive' at the same time, this is not allowed.
                ''
                mapAttrs
                (
                  name: value:
                  let
                    path = setPath ++ singleton name;
                  in
                  throwIfNot (elem name specials || hasAttrByPath (remove "imports" path) modules)
                    ''
                      ${header}
                        '${concatStringsSep "." path}' doesn't exist in 'modules',
                        all values in 'imports' must exist in 'modules'.
                    ''
                    (
                      if isAttrs value then
                        recurse path value
                      else
                        throwIfNot (isBool value) ''
                          ${header}
                              '${concatStringsSep "." path}' is not a boolean,
                              all values in 'imports' must be boolean.
                        '' value
                    )
                )
                imports;
          in
          recurse [ "imports" ];

        extend =
          throwIfNot (isBool importByDefault)
            "importsFromAttrs: the value of the 'importByDefault' must be boolean"
            recursiveUpdate
            (mapAttrsRecursive (_: _: importByDefault) modules);

        # function that handles `_reverse` and `_reverseRecursive` values
        applyReverse =
          inputAttrs:
          let
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
          removeAttrs (mapAttrs update attrs) specials;

        # convert 'imports' to values from 'modules' or nulls depending on the value
        convertToModules = mapAttrsRecursive (
          setPath: value: if value then getAttrFromPath setPath modules else null
        );
      in
      pipe imports [
        validate
        extend
        applyReverse
        convertToModules
        (collect (value: !(isAttrs value || value == null)))
      ];
  };
}
