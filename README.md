# Introduction

The `nixos-ez-flake` consists of a few simple functions to help you write a
multi-host modular configuration with a file-structure based module import
system. The main feature is the ability to enable and disable imports (specific
files or entire directories) via attribute set.

Core functions:

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
  function, this allows you to get it from arguments in any module in your
  configuration.

Optional, to convert the file structure to NixOS or Home Manager (WIP)
configurations:

- **mkConfigurations** converts an attribute set from `mkModulesTree` into NixOS
  configurations using the `nixosSystem` function defined in the
  [nixpkgs flake](https://github.com/NixOS/nixpkgs/blob/master/flake.nix). Each
  top-level attribute is a configuration entry point.\
  Note:
  - The name of each subdirectory will be used to define the
    `networking.hostName` option.
  - The `nixosSystem` will be used from the nixpkgs of this flake, which means
    you must override the nixpkgs input of `nixos-ez-flake` in the nixpkgs of
    your flake:
    ```nix
    inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
      nixos-ez-flake = {
        url = "github:name-snrl/nixos-ez-flake";
        inputs.nixpkgs.follows = "nixpkgs";
      };
    };
    ```
    Otherwise, your system will be built using nixpkgs pinned in this flake

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
nixos-ez-flake.mkModuleTree ./modules/profiles/home
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

- `imports` An attribute set that defines which modules should be imported.
  **IMPORTANT**, the structure of this attribute set must match the structure of
  the `modules`.\
  Type: `attribute set`\
  Required: `false`\
  Default: `{ }`

Example:

```nix
importsFromAttrs {
  importByDefault = true;
  modules = mkModuleTree ./modules/profiles/home; # same as in `mkModuleTree` example
  imports = {
    desktop.sway = false;
    networking.self = false;
    servers = false;
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

### mkConfigurations

Similar to [mkHosts](#mkhosts-deprecated), but creates NixOS configurations from
an attribute set of paths, the top-level attributes will be converted to
hostnames and all nested modules will be imported.

- `configurations` is an attribute set of paths to be converted to
  configurations (exactly what `mkModuleTree` returns).\
  Type:
  `attribute set`\
  Required: `true`

- `Inputs` is the same as in `mkHosts`.

- `globalImports` is the same as in `mkHosts`.

Example:

```nix
let
  configurations = {
    liveCD = {
      self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/nixos/configurations/liveCD/default.nix;
    };
    t14g1 = {
      hw-config = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/nixos/configurations/t14g1/hw-config.nix;
      self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/nixos/configurations/t14g1/default.nix;
    };
    t440s = {
      hw-config = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/nixos/configurations/t440s/hw-config.nix;
      self = /nix/store/jhd491xja3gfkvd8y15q3lpf9l87z28z-source/modules/nixos/configurations/t440s/default.nix;
    };
  };
in

mkConfigurations { inherit inputs configurations; }
```

```nix
{
  liveCD = nixpkgs.lib.nixosSystem { ... };
  t14g1 = nixpkgs.lib.nixosSystem { ... };
  t440s = nixpkgs.lib.nixosSystem { ... };
}
```

### mkHosts (deprecated)

Reads the specified directory (`entryPoint`) and converts its subdirectories
into NixOS configurations using the `nixosSystem` function from the `nixpkgs`
flake. Each subdirectory will be passed to the `modules` argument of the
`nixosSystem` function, which will cause only the `default.nix` file of that
subdirectory to be imported. The names of each attribute in the returned
attribute set are the names of the subdirectories. Subdirectory names are also
used to define the `networking.hostName` option.

Arguments:

- `entryPoint` dirictory whose content will be converted.\
  Type:
  `path`\
  Required: `true`

- `inputs` flake inputs that will be passed to the `specialArgs` argument of the
  `nixosSystem` function.\
  Type: `any`\
  Required: `true`

- `globalImports` list of NixOS modules that will be imported in each
  configuration.\
  Type: `list`\
  Required: `false`\
  Default: `[ ]`

Example:

```bash
> tree hosts/
hosts/
├── default.nix
├── liveCD
│   └── default.nix
├── t14g1
│   ├── default.nix
│   └── hw-config.nix
└── t440s
    ├── default.nix
    └── hw-config.nix
```

```nix
inputs:
mkHosts {
  inherit inputs;
  entryPoint = ./hosts;
}
```

```nix
{
  liveCD = nixpkgs.lib.nixosSystem { ... };
  t14g1 = nixpkgs.lib.nixosSystem { ... };
  t440s = nixpkgs.lib.nixosSystem { ... };
}
```

# TODO

- [ ] add [Home Manager](https://github.com/nix-community/home-manager) in the
  template.
- [ ] add an internal flag `__reverse` for `imports` to
  [importsFromAttrs](#importsFromAttrs), which will change the global value of
  `importByDefault` for a particular directory. This is necessary to import only
  one file from a directory, enabling it instead of disabling all others.
