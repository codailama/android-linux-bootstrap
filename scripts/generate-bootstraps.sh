#!/bin/bash
echo "Creating bootstrap for all archs"
SCRIPTS_PATH=$PWD
echo "Building proot..."
cd ../external/proot/

./build.sh

echo "Building minitar..."
cd ../minitar
./build.sh

cd $SCRIPTS_PATH
mkdir -p build
cd build
rm -rf *
cp ../ioctlHook.c .
../build-ioctl-hook.sh

cp -r ../../external/proot/build/* .

sudo apt-get install debootstrap binfmt-support qemu-user-static

build_bootstrap () {
	echo "Packing bootstrap for arch $1"
	
	case $1 in
	arm64)
		PROOT_ARCH="aarch64"
		ANDROID_ARCH="arm64-v8a"
		MUSL_ARCH="aarch64-linux-musl"
		;;
	armhf)
		PROOT_ARCH="armv7a"
		ANDROID_ARCH="armeabi-v7a"
		MUSL_ARCH="arm-linux-musleabihf"
		;;
	amd64)
		PROOT_ARCH="x86_64"
		ANDROID_ARCH="x86_64"
		MUSL_ARCH="x86_64-linux-musl"
		;;
	i386)
		PROOT_ARCH="i686"
		ANDROID_ARCH="x86"
		MUSL_ARCH="i686-linux-musl"
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

  rm -rf bootstrap bootstrap.tar
  sudo debootstrap --foreign --arch=$1 stable bootstrap
  sudo tar -cvf bootstrap.tar bootstrap

	cp ../../run-bootstrap.sh .
	cp ../../install-bootstrap.sh .
	cp ../../add-user.sh .
	cp ../build-ioctl/ioctlHook-${MUSL_ARCH}.so ioctlHook.so
	zip -r bootstrap-$PROOT_ARCH.zip root ioctlHook.so root-pre5 bootstrap.tar run-bootstrap.sh install-bootstrap.sh add-user.sh
	mv bootstrap-$PROOT_ARCH.zip ../
	echo "Packed bootstrap $1"
	cd ..
}

build_bootstrap arm64
build_bootstrap armhf
build_bootstrap amd64
build_bootstrap i386
