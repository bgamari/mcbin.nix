# Edit this configuration file to define what should be installed on
# your system.  Help is available in the configuration.nix(5) man page
# and in the NixOS manual (accessible by running ‘nixos-help’).

{ config, pkgs, nixos, lib, ... }:

{
  imports =
    [ ./mcbin.nix
    ];

  nixpkgs.crossSystem = lib.systems.examples.aarch64-multiplatform;
  boot.supportedFilesystems = lib.mkForce [ "ext4" "vfat" ];
  environment.noXlibs = true;
  fonts.fontconfig.enable = false;
  services.udisks2.enable = false;
  security.polkit.enable = false;
  documentation.enable = false;
  documentation.info.enable = false;
  documentation.man.enable = false;
  programs.command-not-found.enable = false;
  users.users.root.initialHashedPassword = "";

  environment.systemPackages = with pkgs; [
    vim ethtool htop
  ];

  sound.enable = false;
  hardware.enableAllFirmware = false;

  networking.hostName = "mbin";
  networking.useNetworkd = true;
  networking.useDHCP = false;
  systemd.network = {
    networks."eth0" = {
      matchConfig.Name = "eth0";
      DHCP = "yes";
    };
    networks."eth2" = {
      matchConfig.Name = "eth2";
      DHCP = "yes";
    };
  };

  services.journald.storage = "volatile";
  services.openssh.enable = true;
  services.avahi = {
    enable = true;
    nssmdns = true;
    publish.enable = true;
    publish.addresses = true;
    publish.domain = true;
  };

  nix.settings.extra-experimental-features = [ "nix-command" "flakes" ];
  nix.settings.trusted-users = [ "root" "ben" ];
  
  fileSystems."/mnt/ext" = {
    device = "/dev/sda1";
    neededForBoot = false;
  };

  system.stateVersion = "23.11";
}
