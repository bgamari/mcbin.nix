{ lib, pkgs, config, ... }:

let
  kernel = {
    boot.kernelPackages = pkgs.linuxPackages_6_6;

    boot.kernelPatches = [
      {
        name = "mbin-config";
        patch = null;
        extraConfig = ''
          # Doesn't build
          CRYPTO_AEGIS128_SIMD n

          NF_TABLES_BRIDGE m
          MDIO_I2C y
          MVMDIO y
          OF_MDIO y
          PHY_MVEBU_CP110_COMPHY y
          MVPP2 y
          MVPP2_PTP y
          SFP y
          MARVELL_10G y
        '';
      }
    ];

    sdImage.compressImage = false;
    services.journald.storage = "volatile";
  };

  bootloader = {
    hardware.deviceTree = {
      enable = true;
      name = "marvell/armada-8040-mcbin.dtb";
    };

    boot.loader.grub.enable = false;
    nixpkgs.overlays = [ (self: super: {
      uboot = self.callPackage ./uboot-marvell.nix {};
      marvell-bl1 = self.callPackage ./bl1 {
        ubootBin = "${self.uboot}/u-boot.bin";
      };
    }) ];

    sdImage.firmwareSize = 256;
    sdImage.populateFirmwareCommands = ''
      # Create a partition for BL1
      echo "Installing BL1..."
      sfdisk --append $img <<EOF
          label: dos

          start=4096, type=da
      EOF
      eval $(partx $img -o START,SECTORS --nr 3 --pairs)
      echo $START, $SECTORS
      dd conv=notrunc if=${pkgs.marvell-bl1}/flash-image.bin of=$img seek=$START
      eval $(partx $img -o START,SECTORS --nr 1 --pairs)
    '';
  };

in {
  imports = [
    bootloader
    kernel
  ];
}
