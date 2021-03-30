#!/bin/bash
echo "Creating bootstrap for all archs"
: '
echo "Building proot..."
cd ../external/proot/

./build.sh

echo "Building minitar..."
cd ../minitar
./build.sh
'
mkdir -p  build
cd build
rm -rf *
cp -r ../../external/proot/build/* .

build_bootstrap () {
	echo "Packing bootstrap for arch $1"
	
	case $1 in
	arm64)
		PROOT_ARCH="aarch64"
		ANDROID_ARCH="arm64-v8a"
		;;
	armhf)
		PROOT_ARCH="armv7a"
		ANDROID_ARCH="armeabi-v7a"
		;;
	amd64)
		PROOT_ARCH="x86_64"
		ANDROID_ARCH="x86"
		;;
	i386)
		PROOT_ARCH="i686"
		ANDROID_ARCH="x86_64"
		;;
	*)
		echo "Invalid arch"
		;;
	esac
	cd root-$PROOT_ARCH
	cp ../../../external/minitar/build/libs/$ANDROID_ARCH/minitar root/bin/minitar

	# separate binaries for platforms < android 5 not supporting 64bit
	if [[ "$1" == "armhf" || "$1" == "i386" ]]; then
		cp -r ../root-${PROOT_ARCH}-pre5/root root-pre5
		cp root/bin/minitar root-pre5/bin/minitar
	fi
	
	curl -o rootfs.tar.xz -L "https://us.images.linuxcontainers.org/images/alpine/3.13/$1/default/20210330_13:00/rootfs.tar.xz"
	cp ../../run-bootstrap.sh .
	cp ../../install-bootstrap.sh .
	zip -r bootstrap-$PROOT_ARCH.zip root root-pre5 rootfs.tar.xz run-bootstrap.sh install-bootstrap.sh
	mv bootstrap-$PROOT_ARCH.zip ../
	echo "Packed bootstrap $1"
	cd ..
}

build_bootstrap arm64
build_bootstrap armhf
build_bootstrap amd64
build_bootstrap i386