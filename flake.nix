{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      #crossSystem.system = "aarch64-linux";
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        "${nixpkgs}/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix"
      ];
    };
  };
}
