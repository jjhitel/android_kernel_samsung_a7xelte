#!/bin/bash
clear

LANG=C

###### PREREQUISITES #######

# What you need installed to compile
# gcc, gpp, cpp, c++, g++, lzma, lzop, ia32-libs flex
# If on 64bit Linux, install gcc multilib

### info on how to start this autobuild ###
# Project structure
# --project_root/ #### can have any name
# -----ramdisk_source/ ## defined by RAMDISK_TMP var
# -----ramdisk_tmp/ ## defined by RAMDISK_DIR var
# -----kernel_source/ #### can have any name
# -----android-toolchain/
# -----RELEASE/

## TOOLCHAIN INFO ##
# You just need to have correct folder structure and run this script.
# Everything will be auto-built

## FLASHABLE ZIP ##
# Flashable zip will be located in project_root/RELEASE directory
# and will have name Kernel-a7xelteskt.zip

# location defines
KERNELDIR=$(readlink -f .);
RAMDISK_TMP=ramdisk_tmp
RAMDISK_DIR=ramdisk_source
DEFCONFIG=a7xelte_00_defconfig


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
	echo "Deleting kernel Image named 'kernel' in bootimg_tools dir....."
	rm -f "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/kernel
	echo "Deleting all files from ramdisk dir in bootimg_tools if it exists"
	if [ ! -d "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk ]; then
		mkdir -p "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk 
		chmod 777 "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk
	else
		rm -rf "$KERNELDIR"/bootimg_tools/boot_a7xelteskt/ramdisk/*
	fi;
	echo "Deleted all files from ramdisk dir in bootimg_tools";
	
	echo "Clean all files from temporary and make ramdisk_tmp if it doesn´t exist"
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
	rm -f arch/arm64/boot/*.cmd
	rm -f arch/arm64/boot/Image
	rm -f arch/arm64/boot/Image

}


BUILD_NOW()
{
	if [ ! -f "$KERNELDIR"/.config ]; then
		echo "Copying arch/arm64/configs/$DEFCONFIG to .config"
		cp arch/arm64/configs/"$DEFCONFIG" .config
	else
		rm -f "$KERNELDIR"/.config
		echo "Copying arch/arm64/configs/$DEFCONFIG to .config"
		cp arch/arm64/configs/"$DEFCONFIG" .config
	fi;

	# we don't build modules, so no need to delete them
	########

	### CPU thread usage
	# Idea by savoca
	NR_CPUS=$(grep -c ^processor /proc/cpuinfo)

	if [ "$NR_CPUS" -le "2" ]; then
		NR_CPUS=4;
		echo "Building kernel with 4 CPU threads";
	else
		echo "Building kernel with $NR_CPUS CPU threads";
	fi;

	# build Image
	time make ARCH=arm64 CROSS_COMPILE=../android-toolchain/bin/aarch64-linux-gnu- Image.gz-dtb -j ${NR_CPUS}

	stat "$KERNELDIR"/arch/arm64/boot/Image || exit 1;

	# copy all ramdisk files to ramdisk temp dir.
	cp -a ../"$RAMDISK_DIR"/* ../"$RAMDISK_TMP"/

	# remove empty directory placeholders from tmp-initramfs
	for i in $(find ../"$RAMDISK_TMP"/ -name EMPTY_DIRECTORY); do
		rm -f "$i";
	done;

	if [ -e "$KERNELDIR"/arch/arm64/boot/Image ]; then
		cp arch/arm64/boot/Image bootimg_tools/boot_a7xelteskt/kernel
		cp .config READY/view_only_config

		# copy all ramdisk files to ramdisk temp dir.
		cp -a ../"$RAMDISK_TMP"/* bootimg_tools/boot_a7xelteskt/ramdisk/
		
		### Now I have ramdisk and kernel (Image) and dtb dt.img in bootimg_tools
		### Also I have img_info which is kept every recompile for parsing mkbootimg parameters
		
		# Build boot.img and move it to READY dir
		echo "Move boot.img to READY/boot.img"
		cd bootimg_tools
		./mkboot boot_a7xelteskt ../READY/boot.img
		# Make flashable zip
		cd ../READY
		zip -r Kernel-a7xelteskt.zip * >/dev/null
		mv Kernel-a7xelteskt.zip ../../RELEASE/


		# Add proper timestamps to default.prop in ramdisk

		DATE=$(date)
		DATEUTC=$(date +%s)

		sed -i "s/ro.bootimage.build.date=.*/ro.bootimage.build.date=${DATE}/g" ../../"$RAMDISK_DIR"/default.prop
		sed -i "s/ro.bootimage.build.date.utc=.*/ro.bootimage.build.date.utc=${DATEUTC}/g" ../../"$RAMDISK_DIR"/default.prop

	else
		# with red-color
		echo -e "\e[1;31mKernel STUCK in BUILD! no zImage exist\e[m"
	fi;

}

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

echo "Initializing auto-build script......."
sleep 1;
CLEANUP;
echo "Build now starting"
BUILD_NOW;
exit;
