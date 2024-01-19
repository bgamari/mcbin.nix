{ stdenv, fetchFromGitHub, buildPackages, git, openssl, ubootBin }:

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

  atf = fetchGit {
    name = "atf";
    url = "https://git.trustedfirmware.org/TF-A/trusted-firmware-a.git";
    rev = "9ac42bf2637c1bbd566a39a48da49611e2f2f08c";
  };

  ddr = fetchFromGitHub {
    name = "ddr";
    owner = "MarvellEmbeddedProcessors";
    repo = "mv-ddr-marvell";
    rev = "bfcf62051be835f725005bb5137928f7c27b792e";
    hash = "sha256-6+ioAhYs005o1SgJEurzTkZSNd7c06gdL9Lm8I5VcZ4=";
    leaveDotGit = true;
  };

in stdenv.mkDerivation {
  name = "atf";
  srcs = [ mss atf ddr ];
  sourceRoot = "atf";
  hardeningDisable = [ "all" ];
  enableParallelBuilding = true;
  nativeBuildInputs = [ git openssl ];
  buildInputs = [ openssl ];
  prePatch = ''
    # the mv_ddr build system tries to create mv_ddr_build_message.c
    chmod ugo+w ../ddr
    # move mv_ddr into place
    cp -R ../ddr drivers/marvell/mv_ddr
    git -C drivers/marvell/mv_ddr rev-parse --show-cdup
  '';
  patches = [
    ./atf-fix-openssl-includes.patch
    ./fix-openssl-bin-path.patch
    ./disable-mmio-array-bounds.patch
  ];
  buildFlags = [
    "USE_COHERENT_MEM=0" "LOG_LEVEL=20" "PLAT=a80x0_mcbin"
    "BL33=${ubootBin}"
    "SCP_BL2=../mss/mrvl_scp_bl2.img"
    "CROSS_COMPILE=${stdenv.cc.targetPrefix}"
    "HOSTCC=${buildPackages.stdenv.cc}/bin/gcc"
    "V=1"
    "OPENSSL_BIN_PATH=${buildPackages.openssl.bin}/bin"
    "OPENSSL_INCLUDES=-I${buildPackages.openssl.dev}/include"
    "OPENSSL_LIBS=-L${buildPackages.openssl.out}/lib"
    "MV_DDR_PATH=drivers/marvell/mv_ddr"
    #"MV_DDR_PATH=${ddr}"
    "mrvl_flash" "fip"
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
