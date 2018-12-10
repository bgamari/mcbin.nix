{ stdenv, fetchFromGitHub, openssl, ubootBin }:

# Installation:
#
# dd if=flash-image.bin of=/dev/mmcblk1p1
# 
# See
# http://wiki.macchiatobin.net/tiki-index.php?page=Setup+alternative+boot+sources
# for details.

let
  mss = fetchFromGitHub {
    name = "mss";
    owner = "MarvellEmbeddedProcessors";
    repo = "binaries-marvell";
    rev = "14481806e699dcc6f7025dbe3e46cf26bb787791";
    sha256 = "1l7cgyzy6rbmmyb1510rvdw0fq51hjcck55d069gs36f50yxh6ka";
  };

  atf = fetchFromGitHub {
    name = "atf";
    owner = "MarvellEmbeddedProcessors";
    repo = "atf-marvell";
    rev = "711ecd32afe465b38052b5ba374c825b158eea18";
    sha256 = "0h4bby04j339cr89mgcy286kvnmj7waikv6xknpianncdagzvl7m";
  };

  ddr = fetchFromGitHub {
    name = "ddr";
    owner = "MarvellEmbeddedProcessors";
    repo = "mv-ddr-marvell";
    rev = "99d772547314f84921268d57e53d8769197d3e21";
    sha256 = "0ysmj9sj0gcbg0im4xizwfjy13nrjvrsay3hh5p42q9760ndzvkr";
  };

in stdenv.mkDerivation {
  name = "atf";
  srcs = [ mss atf ddr ];
  sourceRoot = "atf";
  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;
  buildInputs = [ openssl ];
  postPatch = ''
    # the mv_ddr build system tries to create mv_ddr_build_message.c
    chmod ugo+w ../ddr
    # move mv_ddr into place
    cp -R ../ddr drivers/marvell/mv_ddr
  '';
  buildFlags = [
    "USE_COHERENT_MEM=0" "LOG_LEVEL=20" "PLAT=a80x0_mcbin"
    "BL33=${ubootBin}"
    "SCP_BL2=../mss/mrvl_scp_bl2_mss_ap_cp1_a8040.img"
    "all" "fip"
  ];
  installPhase = ''
    mkdir -p $out
    cp -r build/a80x0_mcbin/release/* $out
  '';
}
