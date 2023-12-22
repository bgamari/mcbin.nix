{
  inputs.nixpkgs.url = "github:bgamari/nixpkgs/a33c5c90eb94c0cb7d736d5ecc2d625a47fcc64a";

  outputs = inputs@{ self, nixpkgs, ... }: {
    nixosConfigurations.default = nixpkgs.lib.nixosSystem {
      system = "aarch64-linux";
      modules = [
        ./configuration.nix
      ];
    };
  };
}
