{ buildLinux }:

let
  kernel = args: 
    self.buildLinux (rec {
      modDirVersion = args.version;
      enableParallelBuilding = true;
      kernelPatches = [];
      defconfig = "mvebu_v8_lsp_defconfig";
      extraConfig = ''
        MTD_NAND_CAFE N
      '';
        #ARMV8_DEPRECATED Y
    } // args);
in {
  4_14 = kernel {
    src = self.fetchFromGitHub {
      owner = "MarvellEmbeddedProcessors";
      repo = "linux-marvell";
      rev = "e5eb5621863c2566b58c2ac0c2bc9edfd895420d";
      sha256 = "1m2qn1hvpfa5n7zn9g0cabayjwvx7w5l99bajsgn73z7xwfx85n7";
    };
    version = "4.14.22-armada-18.09.3";
  };

  4_4 = kernel {
    src = self.fetchFromGitHub {
      owner = "MarvellEmbeddedProcessors";
      repo = "linux-marvell";
      rev = "e5eb5621863c2566b58c2ac0c2bc9edfd895420d";
      sha256 = "1m2qn1hvpfa5n7zn9g0cabayjwvx7w5l99bajsgn73z7xwfx85n7";
    };
    version = "4.14.22-armada-18.09.3";
  };
}
