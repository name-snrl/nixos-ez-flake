{ inputs, ... }:
{
  flake.nixosConfigurations = inputs.nixos-ez-flake.mkHosts {
    inherit inputs;
    entryPoint = ./.;
  };
}
