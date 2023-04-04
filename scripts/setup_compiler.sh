#!/bin/bash

checkExe(){
    if [[ "$1" == "" ]]; then
        return 1
    fi
    if type $1 &> /dev/null; then
        return 1
    else
        return 0
    fi
}

exeIsValid(){
    checkExe $1
    if [[ $? == 0 ]]; then
        echo "[ERROR] please install $1 tools and set shell environment PATH to find it"
        exit 1
    fi
}

setAndroidNDK() {
     if [[ "${ANDROID_NDK_HOME}" != "" ]]; then
         INNER_ANDROID_NDK_ROOT=${ANDROID_NDK_HOME}
     fi
     if [[ "${ANDROID_NDK_ROOT}" != "" ]]; then
         INNER_ANDROID_NDK_ROOT=${ANDROID_NDK_ROOT}
     fi
     if [[ "${INNER_ANDROID_NDK_ROOT}" != "" ]]; then
        if [[ ${host} =~ macos ]]; then
            export PATH=${INNER_ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/darwin-x86_64/bin:$PATH
        elif [[ ${host} =~ windows ]]; then
            export PATH=${INNER_ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/windows-x86_64/bin:$PATH
        else
            export PATH=${INNER_ANDROID_NDK_ROOT}/toolchains/llvm/prebuilt/linux-x86_64/bin:$PATH
        fi
     fi
}

androidNDKIsValid(){
    checkExe $1
    if [[ $? == 0 ]]; then
        echo "[ERROR] please install Android NDK, and set shell environment ANDROID_NDK_ROOT or ANDROID_NDK_HOME to find it."
        if [[ ${host} =~ windows ]]; then
            echo "you may also need to add ANDROID_NDK_ROOT\\toolchains\\llvm\\prebuilt\\windows-x86_64\\bin to PATH variable."
        fi
        exit 1
    fi
}

host_system=""
system_info=`uname -a`
if [[ ${system_info} =~ Linux ]]; then
    host_system="linux"
fi
if [[ ${system_info} =~ MINGW ]]; then
    host_system="windows"
fi
if [[ ${system_info} =~ Darwin ]]; then
    host_system="macos"
fi
if [[ "${host_system}" == "" ]]; then
    echo "[ERROR] can not recognize host system information(${system_info}), we currently support Linux/Windows/MacOS."
    exit 1
fi
host_hardware=""
if [[ ${system_info} =~ "x86_64" || ${system_info} =~ "amd64" || ${system_info} =~ "i686" ]]; then
    host_hardware="x86_64"
fi
if [[ ${system_info} =~ "aarch64" || ${system_info} =~ "arm64" ]]; then
    host_hardware="aarch64"
fi
if [[ ${system_info} =~ "armv7" ]]; then
    host_hardware="armv7"
fi
if [[ "${host_hardware}" == "" ]]; then
    echo "[ERROR] can not recognize host hardware information(${system_info}), we currently support x86_64/amd64/aarch64/armv7."
    exit 1
fi
host="${host_system}-${host_hardware}"
if [[ ${target} =~ ${host} ]]; then
    host=$target
fi
if [[ "${target}" == "" ]]; then
     target=${host}
fi

CONFIGURE_OPTIONS=""
CCFLAGS=""
if [[ "${CC}" == "" ]]; then
    CC=gcc
fi
if [[ "${CXX}" == "" ]]; then
    CXX=g++
fi
if [[ "${STRIP}" == "" ]]; then
    STRIP=strip
fi
if [[ "${AR}" == "" ]]; then
    AR=ar
fi
if [[ "${RANLIB}" == "" ]]; then
    RANLIB=ranlib
fi
if [[ "${READELF}" == "" ]]; then
    READELF=readelf
fi

if [[ "${target}" =~ "android" ]]; then
    setAndroidNDK
fi
if [[ "${target}" =~ "android-aarch64" ]]; then
    CC="clang --target=aarch64-linux-android21"
    CXX="clang++ --target=aarch64-linux-android21"
    STRIP=aarch64-linux-android-strip
    AR=aarch64-linux-android-ar
    RANLIB=aarch64-linux-android-ranlib
    READELF=aarch64-linux-android-readelf
    checkExe ${AR}
    if [[ $? == 0 ]]; then
        STRIP=llvm-strip
        AR=llvm-ar
        RANLIB=llvm-ranlib
        READELF=llvm-readelf
    fi
    CONFIGURE_OPTIONS="--host=arm-linux --enable-neon"
    CCFLAGS="${CCFLAGS} --target=aarch64-linux-android21"
    androidNDKIsValid ${AR}
fi
if [[ "${target}" == "android-armv7" ]]; then
    CC="clang --target=armv7a-linux-androideabi21"
    CXX="clang++ --target=armv7a-linux-androideabi21"
    STRIP=arm-linux-androideabi-strip
    AR=arm-linux-androideabi-ar
    RANLIB=arm-linux-androideabi-ranlib
    READELF=arm-linux-androideabi-readelf
    checkExe ${AR}
    if [[ $? == 0 ]]; then
        STRIP=llvm-strip
        AR=llvm-ar
        RANLIB=llvm-ranlib
        READELF=llvm-readelf
    fi
    CONFIGURE_OPTIONS="--host=arm-linux "
    CCFLAGS="${CCFLAGS} --target=armv7a-linux-androideabi21"
    androidNDKIsValid ${AR}
fi
if [[ "${target}" == "android-x86_64" ]]; then
    CC="clang --target=x86_64-linux-android21"
    CXX="clang++ --target=x86_64-linux-android21"
    STRIP=x86_64-linux-android-strip
    AR=x86_64-linux-android-ar
    RANLIB=x86_64-linux-android-ranlib
    READELF=x86_64-linux-android-readelf
    checkExe ${AR}
    if [[ $? == 0 ]]; then
        STRIP=llvm-strip
        AR=llvm-ar
        RANLIB=llvm-ranlib
        READELF=llvm-readelf
    fi
    CONFIGURE_OPTIONS="--host=x86-linux"
    CCFLAGS="${CCFLAGS} --target=x86_64-linux-android21"
fi
if [[ "${target}" =~ "ios-aarch64" || "${target}" == "ios-armv7" ]]; then
    if [[ ${host} =~ macos ]]; then
        if [[ "${IOS_SDK_ROOT}" == "" ]]; then
            IOS_SDK_ROOT=/Applications/Xcode.app/Contents/Developer/Platforms/iPhoneOS.platform/Developer/SDKs/iPhoneOS.sdk
        fi
        if [[ ! -d ${IOS_SDK_ROOT} ]]; then
            echo "[ERROR] please set shell environment variable IOS_SDK_ROOT to iPhoneOS.sdk"
            exit 1
        fi
        CC=/usr/bin/clang
        CXX=/usr/bin/clang++
        STRIP=/usr/bin/strip
        AR=/usr/bin/ar
        RANLIB=/usr/bin/ranlib
        READELF=/usr/bin/readelf
        if [[ "${target}" =~ "ios-aarch64" ]]; then
            CCFLAGS="${CCFLAGS} -arch arm64"
        else
            CCFLAGS="${CCFLAGS} -arch armv7"
        fi
        CCFLAGS="${CCFLAGS} -isysroot ${IOS_SDK_ROOT}"
    else
        CC=arm-apple-darwin11-clang
        CXX=arm-apple-darwin11-clang++
        STRIP=arm-apple-darwin11-strip
        AR=arm-apple-darwin11-ar
        RANLIB=arm-apple-darwin11-ranlib
        READELF=arm-apple-darwin11-readelf
    fi
    CONFIGURE_OPTIONS="--host=arm-apple-darwin11"
fi
if [[ "${target}" == "linux-aarch64" || "${target}" == "linux-aarch64_v9" ]]; then
    CC=aarch64-linux-gnu-gcc
    CXX=aarch64-linux-gnu-g++
    STRIP=aarch64-linux-gnu-strip
    AR=aarch64-linux-gnu-ar
    RANLIB=aarch64-linux-gnu-ranlib
    READELF=aarch64-linux-gnu-readelf
    CONFIGURE_OPTIONS="--host=arm-linux"
fi
if [[ ${target} =~ linux-arm ]]; then
    CONFIGURE_OPTIONS="--host=arm-linux "
fi
if [[ "${target}" == "linux-arm_himix100" ]]; then
    CC=arm-himix100-linux-gcc
    CXX=arm-himix100-linux-g++
    STRIP=arm-himix100-linux-strip
    AR=arm-himix100-linux-ar
    RANLIB=arm-himix100-linux-ranlib
    READELF=arm-himix100-linux-readelf
    CONFIGURE_OPTIONS="--host=arm-linux "
fi
if [[ "${target}" == "linux-arm_musleabi" ]]; then
    CC=arm-linux-musleabi-gcc
    CXX=arm-linux-musleabi-g++
    STRIP=arm-linux-musleabi-strip
    AR=arm-linux-musleabi-ar
    RANLIB=arm-linux-musleabi-ranlib
    READELF=arm-linux-musleabi-readelf
    CONFIGURE_OPTIONS="--host=arm-linux "
fi
if [[ ${host} =~ linux ]]; then
    if [[ "${target}" == "windows-x86_64" || "${target}" == "windows-x86_64_avx2" ]]; then
        CC=x86_64-w64-mingw32-gcc
        CXX=x86_64-w64-mingw32-g++
        STRIP=x86_64-w64-mingw32-strip
        AR=x86_64-w64-mingw32-ar
        RANLIB=x86_64-w64-mingw32-ranlib
        READELF=x86_64-w64-mingw32-readelf
        CONFIGURE_OPTIONS="--host=x86_64-windows "
    fi
fi
if [[ "${target}" == "windows-aarch64" ]]; then
    CC=aarch64-w64-mingw32-gcc
    CXX=aarch64-w64-mingw32-g++
    STRIP=aarch64-w64-mingw32-strip
    AR=aarch64-w64-mingw32-ar
    RANLIB=aarch64-w64-mingw32-ranlib
    READELF=aarch64-w64-mingw32-readelf
    CONFIGURE_OPTIONS="--host=aarch64-windows "
fi
if [[ "${target}" == "windows-armv7" ]]; then
    CC=armv7-w64-mingw32-gcc
    CXX=armv7-w64-mingw32-g++
    STRIP=armv7-w64-mingw32-strip
    AR=armv7-w64-mingw32-ar
    RANLIB=armv7-w64-mingw32-ranlib
    READELF=armv7-w64-mingw32-readelf
    CONFIGURE_OPTIONS="--host=armv7-windows "
fi

MAKE=make
CMAKE_GENERATOR="Unix Makefiles"
if [[ ${host} =~ windows ]]; then
    MAKE=mingw32-make
    CMAKE_GENERATOR="MinGW Makefiles"
fi

CMAKE_OPTIONS="${CMAKE_OPTIONS}"
if [[ "${host}" != "${target}" ]]; then
    if [[ ${target} =~ generic ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_NAME=Generic"
    fi
    if [[ ${target} =~ linux ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_NAME=Linux"
    fi
    if [[ ${target} =~ android ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_NAME=Linux -DANDROID=ON"
    fi
    if [[ ${target} =~ ios ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_NAME=Darwin -DCMAKE_SYSTEM_VERSION=1 -DUNIX=True -DAPPLE=True"
        if [[ ${host} =~ macos ]]; then
            CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_OSX_SYSROOT=${IOS_SDK_ROOT}"
        fi
    fi
    if [[ ${target} =~ windows ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_NAME=Windows -DWIN32=True"
    fi
    if [[ ! ${use_neon} =~ "off" && ( ${target} =~ armv7 || ${target} =~ arm_himix100 || ${target} =~ arm_musleabi ) ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_PROCESSOR=armv7-a"
        if [[ ! ${target} =~ blank ]]; then
            CCFLAGS="${CCFLAGS} -mfpu=neon-vfpv4"
            if [[ ${target} =~ hardfp ]]; then
                CCFLAGS="-mfloat-abi=hardfp ${CCFLAGS}"
            elif [[ ${target} =~ hard || ${target} =~ windows ]]; then
                CCFLAGS="-mfloat-abi=hard ${CCFLAGS}"
            else
                CCFLAGS="-mfloat-abi=softfp ${CCFLAGS}"
            fi
            if [[ ${target} =~ armv7ve ]]; then
                CCFLAGS="-march=armv7ve ${CCFLAGS} -mcpu=cortex-a7"
            else
                CCFLAGS="-march=armv7-a ${CCFLAGS}"
            fi
        fi
    fi
    if [[ ${target} =~ aarch64 ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_PROCESSOR=aarch64"
    fi
    if [[ ${target} =~ x86_64 ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_SYSTEM_PROCESSOR=x86_64"
    fi
fi
if [[ ${target} =~ blank && ${CC} =~ " " ]]; then
    CCFLAGS=`echo ${CC#* }`
fi
if [[ ! ${target} =~ "android" ]]; then
    if [[ ${JNI_ROOT} == "" && ${JAVA_HOME} != "" && -d ${JAVA_HOME} ]]; then
        CMAKE_OPTIONS="${CMAKE_OPTIONS} -DJNI_ROOT=${JAVA_HOME}"
    fi
fi

exeIsValid ${CC}
exeIsValid ${CXX}
exeIsValid ${STRIP}
exeIsValid ${AR}
exeIsValid ${RANLIB}
exeIsValid cmake
exeIsValid ${MAKE}

export CC="${CC}"
export CXX="${CXX}"
export AR="${AR}"
export STRIP="${STRIP}"
export MAKE="${MAKE}"
export READELF="${READELF}"
export CONFIGURE_OPTIONS="${CONFIGURE_OPTIONS}"
export CMAKE_GENERATOR="${CMAKE_GENERATOR}"
export CMAKE_OPTIONS="${CMAKE_OPTIONS} -DCMAKE_STRIP=`which ${STRIP}` -DCMAKE_RANLIB=`which ${RANLIB}`"
export CFLAGS="${CFLAGS} ${CCFLAGS}"
export CXXFLAGS="${CXXFLAGS} ${CCFLAGS}"
