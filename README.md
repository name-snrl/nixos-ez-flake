# Introduction

The `nixos-ez-flake` consists of a two functions to help you work with imports
in modular configurations. Organize modules for home-manager, flake-parts,
NixOS, or any other configuration based on the NixOS module system into a file
structure, and then import them based on attrset with the same structure. Only
two functions:

- **mkModuleTree** creates an attribute set that is a representation of the file
  structure, and the values are file paths. If you find this function not
  powerful enough, I recommend you to check out
  [haumea](https://github.com/nix-community/haumea). This library allows you to
  do the same thing when using the `path loader`, but is a more powerful
  replacement. Also, if you're interested in this library, I recommend checking
  out its author's [configuration](https://github.com/figsoda/cfg).
- **importsFromAttrs** is used to generate a list of paths from an attribute set
  of paths (exactly what `mkModuleTree` returns). The returned list can be
  passed as a value for
  [imports](https://nixos.org/manual/nixos/unstable/#sec-importing-modules).
  This function is passed to the `specialArgs` argument of the `nixosSystem`
  function in [mkConfigurations](#mkConfigurations), this allows you to get it
  from arguments in any module in your configuration.

You can find an example in the [templates](/templates/nixos-configuration) or
check out the
[author's configuration](https://github.com/name-snrl/nixos-configuration).

# Cautions and requirements for beginners

- You have already read about NixOS and know what it is. You realize that Nix
  and NixOS have a high learning curve.
- You realize that you will eventually have to learn a number of abstractions
  and a new programming language. Although you can use NixOS as a black box,
  your user experience will never be complete.
- You are familiar with `git` and in case of anything, you can do a `git revert`
  of the commit that updated your dependencies and caused the configuration to
  break.
- You are familiar with dependency managers that use lock files to pin the
  dependency list.

# Getting Started

Create a repository from the template and follow the steps described in the
template's [readme](/templates/nixos-configuration/README.md).

## You already have nix

```bash
git init nixos-configuration &&
cd nixos-configuration &&
nix --extra-experimental-features 'flakes nix-command' flake init -t github:name-snrl/nixos-ez-flake &&
git add -A &&
git commit -m 'init'
```

## You don't have nix

```bash
git clone https://github.com/name-snrl/nixos-ez-flake.git &&
mv nixos-ez-flake/templates/nixos-configuration . &&
rm -rf nixos-ez-flake &&
cd nixos-configuration &&
git init &&
git add -A &&
git commit -m 'init'
```

# Common use cases

Suppose you have created a module tree from a directory with the following
structure and placed it in the `moduleTree` variable in your flake's outputs:

```
├── flake-parts
│   ├── configurations.nix
│   ├── overlays.nix
│   ├── perSystem.nix
│   ├── shell.nix
│   └── templates.nix
├── home-manager
│   └── profiles
│       └── common
│           ├── bat.nix
│           ├── environment.nix
│           ├── git.nix
│           └── shell
│               ├── fish.nix
│               ├── nushell.nix
│               ├── starship.nix
│               └── zoxide.nix
└── nixos
    ├── configurations
    │   ├── liveCD
    │   │   └── default.nix
    │   ├── t14g1
    │   │   ├── default.nix
    │   │   └── hw-config.nix
    │   └── t440s
    │       ├── default.nix
    │       └── hw-config.nix
    └── profiles
        ├── auth.nix
        ├── boot.nix
        └── desktop
            ├── console.nix
            ├── default.nix
            ├── fonts.nix
            ├── input-method.nix
            ├── kde.nix
            ├── sddm.nix
            └── sway
                ├── default.nix
                ├── display-control.nix
                ├── qt.nix
                ├── systemd-integration.nix
                └── xdg-autostart.nix
```

## import all files from a specific directory

```nix
# import all from nixos/profiles/desktop
{ inputs, ... }: {
  imports = importsFromAttrs {
    modules = inputs.self.moduleTree.nixos.profiles.desktop;
  };
}
```

## import all but one file

```nix
# this will import the following files:
# - nixos/profiles/auth.nix
# - nixos/profiles/boot.nix
# - nixos/profiles/desktop/input-method.nix
{ inputs, ... }: {
  imports = importsFromAttrs {
    modules = inputs.self.moduleTree.nixos.profiles;
    imports = {
      desktop = {
        _reverse = true;
        input-method = false;
      };
    };
  };
}
```

# Library Reference

### mkModuleTree

Creates an attribute set that is a representation of the file structure. All
`default.nix` files will represented as `self`. Reads only directories and files
with `.nix` extension.

Arguments:

- `dir` directory from which create attribute set is created.\
  Type:
  `path`\
  Required: `true`

Example:

```bash
> tree -a modules/profiles/system/
modules/profiles/system/
├── boot.nix
├── desktop
│   ├── default.nix
│   ├── fonts.nix
│   ├── sway
│   │   ├── default.nix
│   │   ├── display-control.nix
│   │   ├── qt.nix
│   │   ├── systemd-integration.nix
│   │   └── xdg-autostart.nix
│   └── xdg-portal.nix
├── environment.nix
├── hardware
│   ├── battery.nix
│   ├── bluetooth.nix
│   ├── default.nix
│   └── sound.nix
├── locale.nix
├── networking
│   ├── default.nix
│   ├── tor.nix
│   └── wireless.nix
├── nix.nix
└── servers
    └── openssh.nix
```

```nix
nixos-ez-flake.mkModuleTree ./modules/profiles/system
```

```nix
{
  boot = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/boot.nix;
  desktop = {
    fonts = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/fonts.nix;
    self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/default.nix;
    sway = {
      display-control = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/sway/display-control.nix;
      qt = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/sway/qt.nix;
      self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/sway/default.nix;
      systemd-integration = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/sway/systemd-integration.nix;
      xdg-autostart = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/sway/xdg-autostart.nix;
    };
    xdg-portal = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/xdg-portal.nix;
  };
  environment = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/environment.nix;
  hardware = {
    battery = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/battery.nix;
    bluetooth = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/bluetooth.nix;
    self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/default.nix;
    sound = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/sound.nix;
  };
  locale = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/locale.nix;
  networking = {
    self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/networking/default.nix;
    tor = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/networking/tor.nix;
    wireless = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/networking/wireless.nix;
  };
  nix = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/nix.nix;
  servers = {
    openssh = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/servers/openssh.nix;
  };
}
```

### importsFromAttrs

Maps a filtering attribute set (`imports`) to `modules` and returns a list of
paths.

Arguments:

- `importByDefault` whether all modules should be imported by default.\
  Type:
  `boolean`\
  Required: `false`\
  Default: `true`

- `modules` attribute set to be filtered.\
  Type: `attribute set`\
  Required:
  `true`

- `imports` An attribute set that defines which modules should be imported. May
  contain special values:

  - `_reverse` must be a boolean, if `true` then all values in the current
    attribute set will be reversed.
  - `_reverseRecursive` same as the previous, but changes values recursively.

  This can be useful when you want to disable importing all but one file, and
  `importByDefault` is set to `true` (this is the default). You don't want to
  write `<name> = false` for all 99 files out of 100 in your directory, do
  you?\
  **IMPORTANT**, the structure of this attribute set must match the
  structure of the `modules`.\
  Type: `attribute set`\
  Required:
  `false`\
  Default: `{ }`

Example:

```nix
importsFromAttrs {
  importByDefault = true;
  modules = mkModuleTree ./modules/profiles/system; # same as in `mkModuleTree` example
  imports = {
    desktop.sway = false; # disable import of the entire directory
    networking.self = false; # disable import of the default.nix
    servers.openssh = false; # diasable import of the openssh.nix
  };
}
```

```nix
[
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/boot.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/fonts.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/default.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/desktop/xdg-portal.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/environment.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/battery.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/bluetooth.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/default.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/hardware/sound.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/locale.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/networking/tor.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/networking/wireless.nix
  /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/profiles/system/nix.nix
]
```

# TODO

- [x] add an internal flag `_reverse` for `imports` to
  [importsFromAttrs](#importsFromAttrs), which will change the global value of
  `importByDefault` for a particular directory. This is necessary to import only
  one file from a directory, enabling it instead of disabling all others.
