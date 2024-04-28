# Introduction

Generated file structure:

```bash
│   # flake based on flake-parts, you can import other flake-parts modules or
│   # add inputs here
├── flake.nix
├── hosts
│   │   # flake-parts module that generates `nixosConfigurations` using
│   │   # `nixos-ez-flake.mkHosts`, here you can add `globalImports`
│   ├── default.nix
│   │   # this directory name will be converted to a value for `networking.hostName`
│   └── host-name
│       │   # this file is the entry point for each host-configuration,
│       │   # it must contain module imports and host-specific configuration
│       └── default.nix
│   # directory whose contents will be converted to attribute set of module paths
└── modules
    └── profiles
        │   # some useful default settings for beginners, you free to remove them
        ├── aliases.nix
        └── nix.nix
```

______________________________________________________________________

A few words about [flake-parts](https://github.com/hercules-ci/flake-parts).

This library allows you to define flake outputs not only in the root flake file,
but also to create modules to do so. This makes your system even more modular.
It also take care of `system` stuff. More information can be found
[here](https://flake.parts/).

If you need to put any flake outputs right now, you can put them in the
[root flake](/flake.nix) as follows:

```nix
  outputs =
    inputs@{ nixos-ez-flake, flake-parts, ... }:
    (flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./hosts
      ];
    })
    // {
      nixosModules = nixos-ez-flake.mkModuleTree ./modules;

      # Here your outputs:

      # Utilized by `nix build`
      packages.x86_64-linux.hello = inputs.c-hello.packages.x86_64-linux.hello;

      # Same idea as overlay but a list or attrset of them.
      overlays = { exampleOverlay = inputs.self.overlay; };
    };
```

Or create a new module and put your outputs in the `flake` attribute of that
module:

```nix
{ lib, inputs, ... }:
{
  flake = {
    # Utilized by `nix build`
    packages.x86_64-linux.hello = inputs.c-hello.packages.x86_64-linux.hello;

    # Same idea as overlay but a list or attrset of them.
    overlays = { exampleOverlay = inputs.self.overlay; };
  };
}
```

Then import module in the [root flake](/flake.nix):

```nix
  outputs =
    inputs@{ nixos-ez-flake, flake-parts, ... }:
    (flake-parts.lib.mkFlake { inherit inputs; } {
      imports = [
        ./hosts
        # any other imports:
        ./PATH/TO/YOUR_MODULE.nix
      ];
    })
    // {
      # Filesystem-based attribute set of module paths
      nixosModules = nixos-ez-flake.mkModuleTree ./modules;
    };
```

______________________________________________________________________

Now let's create your first configuration or migrate an existing one to
**nixos-ez-flake**!

# You already have a configuration

- First, move all your modules to the `./modules` directory, and
  `hardware-configuration.nix` to the `./hosts/host-name` directory.
- If `hardware-configuration.nix` was created a long time ago and does not
  contain the `nixpkgs.hostPlatform` option, I would recommend recreating it
  with the command:
  ```bash
  nixos-generate-config --show-hardware-config > hosts/host-name/hardware-configuration.nix
  ```
  or set this option explicitly in the `./hosts/host-name/default.nix` file.
- Now rename the `./hosts/host-name` directory to match your host name. The
  directory name will be used to define the `networking.hostName` option, so you
  should remove this option from your configuration.
- By default all modules will be imported, disable unwanted ones in
  `./hosts/<hostName>/default.nix` using `imports` argument of
  `importsFromAttrs`.

Done! Try to switch or build your configuration:

```bash
nixos-rebuild switch --use-remote-sudo --flake
```

```bash
nix build --no-link .#nixosConfigurations.<hostName>.config.system.build.toplevel 
```

# This is your first NixOS configuration

Some must-have resources you should know about:

- [NixOS Manual](https://nixos.org/manual/nixos/unstable/), contains many
  manuals on how to configure various services, as well as the standard
  installation manual from a minimal image, which we will use, with a few
  modifications.
- [Nixpkgs packages search](https://search.nixos.org/packages), or use
  `nix search nixpkgs firefox` command.
- [Nixpkgs options search](https://search.nixos.org/options), you can also find
  them in man pages - `man configuration.nix`.

## Preparations

Instead of making configuration changes in an unfamiliar environment after
booting into a live CD, I suggest doing it right now, in a familiar environment.
So, let's write your first NixOS module, which will contain a set of key
packages and services:

- Create a new nix file in the `./modules` directory.
- See the
  [configuration section](https://nixos.org/manual/nixos/unstable/#ch-configuration)
  in the NixOS manual to enable your favorite desktop environment.
- You can search for packages and options using a search engine.

If you are not yet confident enough in your nix language skills, you can use the
example below:

```nix
{ config, pkgs, importsFromAttrs, ... }: {
  # Enable Plasma 6 with SDDM
  services = {
    desktopManager.plasma6.enable = true;
    displayManager.sddm = {
      enable = true;
      wayland.enable = true;
      wayland.compositor = "kwin";
    };
  };
  programs = {
    htop.enable = true;
    git = {
      enable = true;
      config = {
        init.defaultBranch = "master";
        user = {
          name = "name";
          email = "name@example.com";
        };
      };
    };
  };
  environment.systemPackages = with pkgs; [
    ripgrep
    fd
    file
    tree
    wget
  ];
}
```

This module will enable KDE Plasma 6 with SDDM and install programs such as
`git` and `htop`, note that you must make changes to the git configuration (name
and email). It will also install a small set of packages.

## First installation

First of all you need to
[get](https://nixos.org/manual/nixos/unstable/#sec-obtaining) and boot from a
live CD, it doesn't matter which one you choose, it won't affect the end result.
Installation will be done by executing commands through the command line
interface, whether it is a graphical terminal emulator or TTY in a minimal
image.

The installation will take place in 3 phases:

- [Networking](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-networking).
- [Partitioning and formatting](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-partitioning).
- [Installing](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
  - Partitions mounting.
  - Cloning your configuration.
  - Creating a standard configuration.
  - Make changes to the generated module.
  - Installation.

As you can see, most of the steps are described in the
[NixOS manual](https://nixos.org/manual/nixos/unstable/#sec-installation-manual).
So all you need to do is follow the manual step by step, up to point 4 in the
[installing section](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
Here you will be asked to generate a configuration, you do not need to do this,
instead follow the steps below:

- Run a shell with `git`, run `nix-shell -p git` command.
- Now let's clone your configuration to your home directory:
  ```bash
  mkdir -p /mnt/home
  mkdir -p -m 0700 /mnt/home/<username>
  git clone <urlToYourRepo> /mnt/home/<username>/nixos-configuration
  cd /mnt/home/<username>/nixos-configuration
  ```
- Generate a default configuration:
  ```bash
  nixos-generate-config --root /mnt --dir modules
  mv modules/hardware-configuration.nix hosts/<hostName>/
  git add -AN # flake commands only see files placed in the index
  ```
- Now make changes to the generated `configuration.nix` file. Follow the advice
  in step 4 of the section
  [installing section](https://nixos.org/manual/nixos/unstable/#sec-installation-manual-installing).
  **IMPORTANT**, remove `./hardware-configuration.nix` from imports in
  `configuration.nix`.
- Do the installation:
  ```bash
  # uncomment `--no-root-passwd`, if your configuration containes
  # `users.users.root.hashedPassword` option
  nixos-install --flake /mnt/home/<yourUsername>/nixos-configuration#<hostName> # --no-root-passwd
  ```
- Change the owner of your home directory
  ```bash
  nixos-enter
  chown -R <userName>:users /home/<userName>
  exit
  ```
- `reboot` if everything went well

# Basic system operation

This template contains several aliases that may be useful for system management.
Note that some of the following commands assume that your configuration is
stored in the path specified in the
[aliases profile](/modules/profiles/aliases.nix#L3):

- `jnp`, jump to your system's nixpkgs directory, this is useful for researching
  nixpkgs.
- `nupdate`, update all your flake inputs (flake dependencies) and commit those
  changes. Note: this will not update your system, only the inputs of your
  flake. You must use the `nswitch`/`nboot` commands to build and switch to the
  updated configuration.
- `nclear`, removes all old system generations and other unused derivatives from
  `/nix/store`.
- `nswitch`, build the configuration and activate it. This will restart systemd
  services, recreate package symlinks, and so on. Note that some changes cannot
  be successfully applied without a reboot.
- `nboot`, same as `nswitch`, but activates the system on the next boot.

Sometimes you may want to quickly try out an application. To do this, you can
use the following commands:

- `nix shell nixpkgs#<pkgName> nixpkgs#<otherPkg>`, run a shell in which the
  specified packages are available. This can also be used as a
  `nix shell nixpkgs#<pkgName> -c pkg-command args` to simply run a command.
- `nix run nixpkgs#<pkgName>`, this will run the main program of the package.
