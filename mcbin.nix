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
    kernel_addr=0x20000000
    kernel_image=Image
    devicetree_addr=0x10000000
    devicetree_image=armada-8040-mcbin.dtb
    ramdisk_image=initrd
    bootcmd=${pkgs.lib.concatStringsSep " && " bootCmds}
  '';

  kernel = {
    nixpkgs.overlays = [ (self: super: {
      linux-marvell-armada = (import ./marvell-kernel.nix);
    }) ];

    #boot.kernelPackages = pkgs.linuxPackagesFor pkgs.linux-marvell-armada.4_4;
    #boot.kernelPackages = pkgs.linuxPackages_5_2;
    boot.kernelPackages = pkgs.linuxPackagesFor (pkgs.buildLinux rec {
      version = "5.4-rc1";
      modDirVersion = "5.4.0-rc1";
      defconfig = "defconfig";
      enableParallelBuilding = true;
      extraConfig = "";
      kernelPatches = [];
      src = pkgs.fetchurl {
        #url = "mirror://kernel/linux/kernel/v5.x/linux-${version}.tar.xz";
        url = "https://git.kernel.org/torvalds/t/linux-${version}.tar.gz";
        sha256 = "1a9h0g249b3aznn6jz92y5vpr02v921mgf72rj0nbblcfhrimzk9";
      };
    });

    boot.kernelPatches = [
      {
        name = "mbin-config";
        patch = null;
        extraConfig = ''
          # Doesn't build
          CRYPTO_AEGIS128_SIMD n

          NF_TABLES_BRIDGE m
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

    sdImage.firmwareSize = 128;

    sdImage.populateFirmwareCommands = 
      let
        kernel = config.boot.kernelPackages.kernel;
      in ''
        # Create a partition for BL1
        echo "Installing BL1..."
        sfdisk --append $img <<EOF
            label: dos

            start=4096, type=da
        EOF
        eval $(partx $img -o START,SECTORS --nr 3 --pairs)
        dd conv=notrunc if=${pkgs.marvell-bl1}/flash-image.img of=$img seek=$START count=$SECTORS

        cp ${kernel}/Image ./firmware
        cp ${kernel}/dtbs/marvell/armada-8040-mcbin.dtb ./firmware
        cp ${config.system.build.toplevel}/initrd firmware/initrd
        cat <<'EOF' >firmware/uEnv.txt
        ${uEnv}
        EOF
      '';
  };

  bootloader =
    let
      bootPart = "/boot/firmware";
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
