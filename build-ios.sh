#!/bin/sh
DEV_TOOLS=/Applications/Xcode.app/Contents/Developer
PLATFORM_IOS=${DEV_TOOLS}/Platforms/iPhoneOS.platform
PLATFORM_IOS_SIM=${DEV_TOOLS}/Platforms/iPhoneSimulator.platform
SDK_IOS_VERSION="7.0"
MIN_IOS_VERSION="6.1"
OUTPUT_DIR="universal-ios"

build_target () {
    local platform=$1
    local sdk=$2
    local arch=$3
    local triple=$4
    local builddir=$5

    mkdir -p "${builddir}"
    pushd "${builddir}"
    export CC="${DEV_TOOLS}"/Toolchains/XcodeDefault.xctoolchain/usr/bin/clang
    export CFLAGS="-arch ${arch} -isysroot ${sdk} -miphoneos-version-min=${MIN_IOS_VERSION}"

    ../configure --host=${triple} && make
    popd
}

# Build all targets
# build_target "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/" armv7 arm-apple-darwin10 armv7-ios
# build_target "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/" armv7s arm-apple-darwin10 armv7s-ios
build_target "${PLATFORM_IOS}" "${PLATFORM_IOS}/Developer/SDKs/iPhoneOS${SDK_IOS_VERSION}.sdk/" arm64 aarch64-apple-darwin10 arm64-ios
# build_target "${PLATFORM_IOS_SIM}" "${PLATFORM_IOS_SIM}/Developer/SDKs/iPhoneSimulator${SDK_IOS_VERSION}.sdk/" i386 i386-apple-darwin10 i386-ios-sim

# Create universal output directories
mkdir -p "${OUTPUT_DIR}"
mkdir -p "${OUTPUT_DIR}/include"
mkdir -p "${OUTPUT_DIR}/include/armv7"
mkdir -p "${OUTPUT_DIR}/include/armv7s"
mkdir -p "${OUTPUT_DIR}/include/arm64"
mkdir -p "${OUTPUT_DIR}/include/i386"

# Create the universal binary
# lipo -create armv7-ios/.libs/libffi.a arm64-ios/.libs/libffi.a i386-ios-sim/.libs/libffi.a -output "${OUTPUT_DIR}/libffi.a"
lipo -create arm64-ios/.libs/libffi.a  -output "${OUTPUT_DIR}/libffi.a"

# Copy in the headers
copy_headers () {
    local src=$1
    local dest=$2

    # Fix non-relative header reference
    sed 's/<ffitarget.h>/"ffitarget.h"/' < "${src}/include/ffi.h" > "${dest}/ffi.h"
    cp "${src}/include/ffitarget.h" "${dest}"
}

# copy_headers armv7-ios "${OUTPUT_DIR}/include/armv7"
# copy_headers armv7s-ios "${OUTPUT_DIR}/include/armv7s"
copy_headers arm64-ios "${OUTPUT_DIR}/include/arm64"
# copy_headers i386-ios-sim "${OUTPUT_DIR}/include/i386"

# Create top-level header
(
cat << EOF
#ifdef __arm__
  #include <arm/arch.h>
  #ifdef _ARM_ARCH_7
    #include "include/armv7/ffi.h"
  #endif
#elif defined(__i386__)
  #include "include/i386/ffi.h"
#endif
EOF
) > "${OUTPUT_DIR}/ffi.h"
