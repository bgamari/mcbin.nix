{pkgs, config, ...}: 

let
  kernel = {
    nixpkgs.overlays = [ (self: super: {
      linux-marvell-armada = self.buildLinux rec {
        src = self.fetchFromGitHub {
          owner = "MarvellEmbeddedProcessors";
          repo = "linux-marvell";
          rev = "e5eb5621863c2566b58c2ac0c2bc9edfd895420d";
          sha256 = "1m2qn1hvpfa5n7zn9g0cabayjwvx7w5l99bajsgn73z7xwfx85n7";
        };
        modDirVersion = "4.14.22-armada-18.09.3";
        version = modDirVersion;
        enableParallelBuilding = true;
        kernelPatches = [];
        defconfig = "mvebu_v8_lsp_defconfig";
        extraConfig = ''
          MTD_NAND_CAFE N
        '';
          #ARMV8_DEPRECATED Y
      };
    }) ];
    #boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-marvell-armada;

    boot.kernelPackages = pkgs.linuxPackages_4_18;
  };

  bootloader =
    let
      bootPart = "/boot";
      deviceTree = "dtbs/marvell/armada-8040-mcbin.dtb";

      bootCmds = [
        "echo Copying Linux from SD to RAM..."
        "mmcinfo"
        "setenv devicetree_addr 0x1000000"
        "setenv kernel_addr 0x2000000"
        "setenv initrd_addr 0x6000000"
        "ext4load mmc 1:3 \${kernel_addr} \${kernel_image}"
        "ext4load mmc 1:3 \${devicetree_addr} \${devicetree_image}"
        "ext4load mmc 1:3 \${initrd_addr} \${initrd_image}"
        "setenv bootargs earlycon=uart8250,mmio32,0xf0512000 console=ttyS0,115200n8 root=/dev/mmcblk1p3 init=\${toplevel}/init \${extra_kernel_args}"
        "booti $kernel_addr $initrd_addr $fdt_addr"
      ];

      uEnv = ''
        toplevel=$toplevel
        kernel_image=kernel
        devicetree_image=devicetree.dtb
        initrd_image=initrd
        bootcmd=${pkgs.lib.concatStringsSep " && " bootCmds}
      '';

    in {
      system.boot.loader.id = "u-boot";
      boot.loader.grub.enable = false;
      nixpkgs.overlays = [ (self: super: {
        uboot = self.callPackage ./uboot-marvell.nix {};
        uEnv = uEnv;
        marvell-bl1 = self.callPackage ./marvell-bl1.nix {
          ubootBin = "${self.uboot}/u-boot.bin";
        };
      }) ];

      system.build.installBootLoader = pkgs.writeScript "update-uboot.sh" ''
        #!${pkgs.stdenv.shell}
        toplevel=$1
        if [ ! -f $toplevel/init ]; then
          echo "Invalid toplevel; expected to find /init"
          exit 1
        fi

        archive() {
          if [ -f $1 ]; then mv $1 $1.old; fi
        }

        archive ${bootPart}/kernel
        archive ${bootPart}/initrd
        archive ${bootPart}/devicetree.dtb

        cp -L $toplevel/kernel ${bootPart}/kernel
        cp -L $toplevel/${deviceTree} ${bootPart}/devicetree.dtb
	${pkgs.ubootTools}/bin/mkimage -A arm64 -O linux -T ramdisk -C gzip -d $toplevel/initrd ${bootPart}/initrd
        echo "Bootloader updated."
        
        #${pkgs.ubootTools}/bin/fw_printenv || ( echo "Failed to print u-boot configuration"; exit 1 )
        #${pkgs.ubootTools}/bin/fw_setenv toplevel $toplevel
      '';
    };

in {
  imports = [ bootloader kernel ];
}
