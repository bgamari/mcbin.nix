# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, nixos, lib, ... }:

{
  imports =
    [ # Include the results of the hardware scan.
      ./hardware-configuration.nix
      ./mcbin.nix
          # Build config.system.build.sdImage
      (import ./nixpkgs/nixos/modules/installer/cd-dvd/sd-image-aarch64.nix)
    ];

  /*nixpkgs.crossSystem = {
    config = "aarch64-unknown-linux-gnu";
    system = "aarch64-linux";
  };*/
  nixpkgs.crossSystem = 
    let base = (import ./nixpkgs/lib).systems.examples.aarch64-multiplatform;
    in 
      base // {
        platform = base.platform // { kernelTarget = "Image"; };
        system = "aarch64-linux";
      };
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];
  environment.noXlibs = true;
  fonts.fontconfig.enable = false;
  services.udisks2.enable = false;
  security.rngd.enable = false;
  security.polkit.enable = false;
  documentation.enable = false;
  documentation.info.enable = false;
  documentation.man.enable = false;
  programs.command-not-found.enable = false;
  users.users.root.initialHashedPassword = "";

  environment.systemPackages = with pkgs; [
    vim ethtool
  ];

  nixpkgs.overlays = [ (self: super: {
    # p11-kit testsuite is broken
    p11-kit = super.p11-kit.overrideAttrs (oldAttrs: { doCheck = false; });
  }) ];

  sound.enable = false;
  hardware.enableAllFirmware = false;

  networking.hostName = "mbin";
  networking.useNetworkd = true;
  networking.useDHCP = false;
  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.addresses = true;
    publish.domain = true;
  };
  
  fileSystems."/mnt/ext" = {
    device = "/dev/sda1";
    neededForBoot = true;
  };

  #fileSystems."/nix" = {
  #  device = "/mnt/ext/nix";
  #  options = [ "bind" ];
  #  neededForBoot = true;
  #};
}
