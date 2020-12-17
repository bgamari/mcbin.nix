{ fetchFromGitHub, fetchurl, buildUBoot }:

buildUBoot rec {
  name = "uboot-marvell";
  version = "2019.10";
  defconfig = "mvebu_mcbin-88f8040_defconfig";
  targetPlatforms = [ "aarch64-linux" ];
  filesToInstall = [ "u-boot.bin" ];
  postConfigure = ''
    cat >> .config << EOF
    CONFIG_SYS_BOOTM_LEN=0x1000000000
    EOF
  '';

  src = fetchurl {
    url = "ftp://ftp.denx.de/pub/u-boot/u-boot-${version}.tar.bz2";
    sha256 = "053hcrwwlacqh2niisn0zas95zkbffw5aw5sdhixs8lmfdq60vcd";
  };

  /*
  src = fetchFromGitHub {
    owner = "MarvellEmbeddedProcessors";
    repo = "u-boot-marvell";
    rev = "c9aa92ce70d16b3d6c6291c6be69f42783a4ebc0";
    sha256 = "0g7nry9zpjxdk9dclvwkq64719cdfmcj22ybv6lhfqm7d0xqgpkn";
  };
  */
}
