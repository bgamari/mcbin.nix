{ fetchFromGitHub, fetchurl, buildUBoot }:

buildUBoot rec {
  name = "uboot-marvell";
  defconfig = "mvebu_mcbin-88f8040_defconfig";
  targetPlatforms = [ "aarch64-linux" ];
  filesToInstall = [ "u-boot.bin" ];
  postConfigure = ''
    cat >> .config << EOF
    CONFIG_SYS_BOOTM_LEN=0x1000000000
    CONFIG_DISTRO_DEFAULTS=n
    EOF
  '';
}
