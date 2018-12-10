{ fetchFromGitHub, buildUBoot }:

buildUBoot {
  name = "uboot-marvell";
  defconfig = "mvebu_mcbin-88f8040_defconfig";
  targetPlatforms = [ "aarch64-linux" ];
  filesToInstall = [ "u-boot.bin" ];
  postConfigure = ''
    cat >> .config << EOF
    CONFIG_SYS_BOOTM_LEN=0x1000000000
    EOF
  '';
  #src = fetchFromGitHub {
  #  owner = "MarvellEmbeddedProcessors";
  #  repo = "u-boot-marvell";
  #  rev = "8fe403172c58440bcfbb3724242301c0108eff5b";
  #  sha256 = "1g2mq9xfw9jp0s4m0gqnk9xbq5x8z91s9fkpayizx6nni91gwn4v";
  #};
}
