#/bin/bash

LINEAGEVERSION=ridon-7.1.2
DATE=`date +%Y%m%d`
IMGNAME=$LINEAGEVERSION-$DATE-rpi3.img
IMGSIZE=4

if [ -f $IMGNAME ]; then
	echo "File $IMGNAME already exists!"
else
	echo "Creating image file $IMGNAME..."
	dd if=/dev/zero of=$IMGNAME bs=512k count=$(echo "$IMGSIZE*1024*2" | bc)
	sync
	sudo modprobe loop
	echo "Creating partitions..."
	echo -e "o\nn\np\n1\n\n+100M\nn\np\n2\n\n+1024M\nn\np\n3\n\n+256M\nn\np\n\n\nt\n1\nc\na\n1\nw\n" | /sbin/fdisk $IMGNAME
	sync
	sudo kpartx -a $IMGNAME

	DEVa=`sudo kpartx -l $IMGNAME | sed -n 1p | cut -f1 -d' '`
	if [ -z $DEVa ];then
		echo "Partitions in $IMGNAME can't be read"
  		exit
	fi
	DEVb=`sudo kpartx -l $IMGNAME | sed -n 2p | cut -f1 -d' '`

	sudo mkfs.fat -F 32 /dev/mapper/$DEVa
	sudo mkfs.ext4 /dev/mapper/$DEVb

	echo "Copying system..."
	sudo dd if=../../../out/target/product/rpi3/system.img of=/dev/mapper/$DEVb bs=1M
	echo "Copying boot..."
	mkdir -p sdcard/boot
	sync
	sudo mount /dev/mapper/$DEVa sdcard/boot
	sync
	sudo cp boot/* sdcard/boot
	sudo cp ../../../vendor/brcm/rpi3/proprietary/boot/* sdcard/boot
	sudo cp ../../../out/target/product/rpi3/obj/KERNEL_OBJ/arch/arm/boot/zImage sdcard/boot
	sudo cp -R ../../../out/target/product/rpi3/obj/KERNEL_OBJ/arch/arm/boot/dts/* sdcard/boot
	sudo cp ../../../out/target/product/rpi3/ramdisk.img sdcard/boot
	sync
	sudo umount /dev/mapper/$DEVa
	rm -rf sdcard
	sudo kpartx -d $IMGNAME
	sync
	echo "Done, created $IMGNAME!"
fi
