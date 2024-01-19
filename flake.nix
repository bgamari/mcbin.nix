{
  inputs.nixpkgs.url = "github:nixos/nixpkgs/nixos-23.11";

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      #crossSystem.system = "aarch64-linux";
      system = "x86_64-linux";
      modules = [
        ./configuration.nix
        "${nixpkgs}/nixos/modules/installer/sd-card/sd-image-aarch64-installer.nix"
      ];
    };
    packages.x86_64-linux.system = self.nixosConfigurations.default.config.system.build.toplevel;
    packages.x86_64-linux.sd-image = self.nixosConfigurations.default.config.system.build.sdImage;
  };
}
