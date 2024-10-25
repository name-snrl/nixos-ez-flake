{ config, ... }:
let
  cfgPath = "~/nixos-configuration";
in
{
  environment.shellAliases = {
    jnp = "cd ${config.nixpkgs.flake.source}";
    nboot = "nixos-rebuild boot --use-remote-sudo --flake ${cfgPath}";
    nswitch = "nixos-rebuild switch --use-remote-sudo --flake ${cfgPath}";
    nupdate = "nix flake update --commit-lock-file --flake ${cfgPath}";
    # https://github.com/NixOS/nix/issues/8508
    nclear = "sudo nix-collect-garbage --delete-old && nix-collect-garbage --delete-old";
  };
}
