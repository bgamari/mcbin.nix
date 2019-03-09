{pkgs, config, ...}: 

let
  bootCmds = [
    "echo Copying Linux from SD to RAM..."
    "mmc dev 1"
    "ext4load mmc 1:1 \${kernel_addr} \${kernel_image}"
    "ext4load mmc 1:1 \${devicetree_addr} \${devicetree_image}"
    "ext4load mmc 1:1 \${ramdisk_addr} \${ramdisk_image}"
    "setenv bootargs console=ttyS0,115200n8 root=/dev/mmcblk0p2 init=\${toplevel}/init \${extra_kernel_args}"
    "bootm \${kernel_addr} \${devicetree_addr} \${ramdisk_addr}]"
  ];

  uEnv = ''
    toplevel=${config.system.build.toplevel}
    extra_kernel_args=
    kernel_addr=0x2000000
    kernel_image=Image
    devicetree_addr=0x1000000
    devicetree_image=armada-8040-mcbin.dtb
    ramdisk_image=initrd
    bootcmd=${pkgs.lib.concatStringsSep " && " bootCmds}
  '';

  kernel = {
    nixpkgs.overlays = [ (self: super: {
      btrfs-progs = super.btrfs-progs.override { python3 = null; };
      linux-marvell-armada = (import ./marvell-kernel.nix);
    }) ];
    #boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-marvell-armada.4_4;

    boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.buildLinux {
      version = "5.0.0";
      extraMeta.branch = "5.0";
      kernelPatches = [];
      src = pkgs.fetchFromGitHub {
        owner = "torvalds";
        repo = "linux";
        rev = "1c163f4c7b3f621efff9b28a47abb36f7378d783";
        sha256 = "1rzv1yfn8niib69dn6vpp24byck566a2fha48swd7ra20r0yhfgb";
      };
    });

    boot.kernelPatches = [
      {
        name = "mbin-config";
        patch = null;
        extraConfig = ''
          MDIO_I2C y
          MVMDIO y
          OF_MDIO y
          PHY_MVEBU_CP110_COMPHY y
          MVPP2 y
          SFP y
          MARVELL_10G y
        '';
      }
    ];

    sdImage.createBootPartition = 
      let
        kernel = config.boot.kernelPackages.kernel;
      in ''
        cp ${}
        cp ${kernel}/Image boot/
        cp ${kernel}/dtbs/marvell/armada-8040-mcbin.dtb boot/
        cp ${config.system.build.toplevel}/initrd boot/initrd
        cat <<'EOF' >boot/uEnv.txt
        ${uEnv}
        EOF
      '';
  };

  bootloader =
    let
      bootPart = "/boot";
      deviceTree = "dtbs/marvell/armada-8040-mcbin.dtb";
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
