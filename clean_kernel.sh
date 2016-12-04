#!/bin/bash
clear

LANG=C

# location
KERNELDIR=$(readlink -f .);
RAMDISK_TMP=ramdisk_tmp
RAMDISK_DIR=ramdisk_source
DEFCONFIG=exynos7580-a7xelteskt_defconfig

CLEANUP()
{
	# begin by ensuring the required directory structure is complete, and empty
	echo "Initialising................."

	echo "Cleaning READY dir......."
	sleep 1;
	rm -rf "$KERNELDIR"/READY/boot
	rm -rf "$KERNELDIR"/READY/*.img
	rm -rf "$KERNELDIR"/READY/*.zip
	rm -rf "$KERNELDIR"/READY/*.sh
	rm -f "$KERNELDIR"/.config
	#### Cleanup bootimg_tools now #####
	echo "Cleaning bootimg_tools from unneeded data..."
	sleep 1;
	echo "Deleting kernel Image named 'kernel' in bootimg_tools dir....."
	rm -f "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/kernel
	sleep 1;
	echo "Deleting all files from ramdisk dir in bootimg_tools if it exists"
	if [ ! -d "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk ]; then
		mkdir -p "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk 
		chmod 777 "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk
	else
		rm -rf "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk/*
	fi;
	sleep 1;
	echo "Deleted all files from ramdisk dir in bootimg_tools";

	
	mkdir -p "$KERNELDIR"/READY/
	
	echo "Clean all files from temporary"
	if [ ! -d ../"$RAMDISK_TMP" ]; then
		mkdir ../"$RAMDISK_TMP"
		chown root:root ../"$RAMDISK_TMP"
		chmod 777 ../"$RAMDISK_TMP"
	else
		rm -rf ../"$RAMDISK_TMP"/*
	fi;

	echo "Make RELEASE directory if it doesn't exist and clean it if it exists"
	if [ ! -d ../RELEASE ]; then
		mkdir ../RELEASE
	else
		rm -rf ../RELEASE/*
	fi;


	# force regeneration of .dtb and Image files for every compile
	rm -f arch/arm64/boot/*.dtb
	rm -f arch/arm64/boot/*.cmd
	rm -f arch/arm64/boot/Image

}
CLEANUP;

CLEAN_KERNEL()
{
	echo "Mrproper and clean running"
	sleep 1;
	make ARCH=arm64 mrproper;
	make clean;

	# clean ccache
	read -t 10 -p "clean ccache, 10sec timeout (y/n)?";
	if [ "$REPLY" == "y" ]; then
		ccache -C;
	fi;
}
CLEAN_KERNEL;
