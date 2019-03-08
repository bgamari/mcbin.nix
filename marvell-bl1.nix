{ stdenv, fetchFromGitHub, buildPackages, openssl, ubootBin }:

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
    rev = "c6c529ea3d905a28cc77331964c466c3e2dc852e";
    sha256 = "02r13r7qffbcm85ibmq13z5g0a4sxn05ak6a4s61nswww1y89hyd";
  };

  atf = fetchFromGitHub {
    name = "atf";
    owner = "MarvellEmbeddedProcessors";
    repo = "atf-marvell";
    rev = "1f8ca7e01d4ac7023aea0eeb4c8a4b98dcf05760";
    sha256 = "1ldiak6x7agdfqkx0x8zz96653kg9pjsahjnxl3159xa66b4fn2l";
  };

  ddr = fetchFromGitHub {
    name = "ddr";
    owner = "MarvellEmbeddedProcessors";
    repo = "mv-ddr-marvell";
    rev = "618dadd1491eb2f7b2fd74313c04f7accddae475";
    sha256 = "1zj4xg6cmlq13yy2h68z4jxsq6vr7wz5ljm15f26g3cawq7545xq";
  };

in stdenv.mkDerivation {
  name = "atf";
  srcs = [ mss atf ddr ];
  sourceRoot = "atf";
  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;
  nativeBuildInputs = [ openssl ];
  patches = [ ./atf-fix-openssl-includes.patch ];
  postPatch = ''
    # the mv_ddr build system tries to create mv_ddr_build_message.c
    chmod ugo+w ../ddr
    # move mv_ddr into place
    cp -R ../ddr drivers/marvell/mv_ddr
  '';
  buildFlags = [
    "USE_COHERENT_MEM=0" "LOG_LEVEL=20" "PLAT=a80x0_mcbin"
    "BL33=${ubootBin}"
    "SCP_BL2=../mss/mrvl_scp_bl2.img"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "HOSTCC=${buildPackages.stdenv.cc}/bin/gcc"
    "V=1"
    "OPENSSL_INCLUDES=-I${buildPackages.openssl.dev}/include"
    "OPENSSL_LIBS=-L${buildPackages.openssl.out}/lib"
    "all" "fip"
  ];
  #buildPhase = ''
  #  make $buildFlags all
  #  make $buildFlags OPENSSL_INCLUDES="-I${buildPackages.openssl.dev}/include" fip
  #'';
  installPhase = ''
    mkdir -p $out
    cp -r build/a80x0_mcbin/release/* $out
  '';
}
