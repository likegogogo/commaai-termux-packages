TERMUX_PKG_HOMEPAGE=https://www.qt.io/
TERMUX_PKG_DESCRIPTION="A cross-platform application and UI framework"
TERMUX_PKG_LICENSE="LGPL-3.0"
TERMUX_PKG_MAINTAINER="Leonid Pliushch <leonid.pliushch@gmail.com>"
_MAJOR_VERSION=5.12
TERMUX_PKG_VERSION=${_MAJOR_VERSION}.8
TERMUX_PKG_REVISION=28
#TERMUX_PKG_SRCURL="http://master.qt.io/archive/qt/${TERMUX_PKG_VERSION%.*}/${TERMUX_PKG_VERSION}/single/qt-everywhere-src-${TERMUX_PKG_VERSION}.tar.xz"
#TERMUX_PKG_SRCURL="https://ftp.osuosl.org/pub/blfs/conglomeration/qt5/qt-everywhere-src-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SRCURL="http://www.mirrorservice.org/sites/download.qt-project.org/official_releases/qt/${_MAJOR_VERSION}/${TERMUX_PKG_VERSION}/single/qt-everywhere-src-${TERMUX_PKG_VERSION}.tar.xz"
TERMUX_PKG_SHA256=9142300dfbd641ebdea853546511a352e4bd547c4c7f25d61a40cd997af1f0cf
TERMUX_PKG_DEPENDS="libc++, libicu, openssl"
TERMUX_PKG_BUILD_IN_SRC=true
TERMUX_PKG_NO_STATICSPLIT=true

TERMUX_PKG_RM_AFTER_INSTALL="
bin/fixqt4headers.pl
bin/syncqt.pl
lib/qt/mkspecs/termux-cross
"

termux_step_pre_configure () {
    if [ "${TERMUX_ARCH}" = "arm" ]; then
        ## -mfpu=neon causes build failure on ARM.
        CFLAGS="${CFLAGS/-mfpu=neon/} -mfpu=vfp"
        CXXFLAGS="${CXXFLAGS/-mfpu=neon/} -mfpu=vfp"
    fi

    ## Create qmake.conf suitable for cross-compiling.
    sed \
        -e "s|@TERMUX_CC@|${TERMUX_HOST_PLATFORM}-clang|" \
        -e "s|@TERMUX_CXX@|${TERMUX_HOST_PLATFORM}-clang++|" \
        -e "s|@TERMUX_AR@|${TERMUX_HOST_PLATFORM}-ar|" \
        -e "s|@TERMUX_NM@|${TERMUX_HOST_PLATFORM}-nm|" \
        -e "s|@TERMUX_OBJCOPY@|${TERMUX_HOST_PLATFORM}-objcopy|" \
        -e "s|@TERMUX_PKGCONFIG@|${TERMUX_HOST_PLATFORM}-pkg-config|" \
        -e "s|@TERMUX_STRIP@|${TERMUX_HOST_PLATFORM}-strip|" \
        -e "s|@TERMUX_CFLAGS@|${CPPFLAGS} ${CFLAGS}|" \
        -e "s|@TERMUX_CXXFLAGS@|${CPPFLAGS} ${CXXFLAGS}|" \
        -e "s|@TERMUX_LDFLAGS@|${LDFLAGS}|" \
        "${TERMUX_PKG_BUILDER_DIR}/qmake.conf" > "${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross/qmake.conf"

    cp -r "${TERMUX_PKG_BUILDER_DIR}/eglfs_surfaceflinger/" "${TERMUX_PKG_SRCDIR}/qtbase/src/plugins/platforms/eglfs/deviceintegration"
}

termux_step_configure () {
    export PKG_CONFIG_SYSROOT_DIR="${TERMUX_PREFIX}"
    unset CC CXX LD CFLAGS LDFLAGS

    "${TERMUX_PKG_SRCDIR}"/configure -v \
        -L/data/data/com.termux/files/usr/lib \
        -I/data/data/com.termux/files/usr/include \
        -opensource \
        -confirm-license \
        -release \
        -xplatform termux-cross \
        -optimized-qmake \
        -no-rpath \
        -no-use-gold-linker \
        -prefix "${TERMUX_PREFIX}" \
        -docdir "${TERMUX_PREFIX}/share/doc/qt" \
        -headerdir "${TERMUX_PREFIX}/include/qt" \
        -archdatadir "${TERMUX_PREFIX}/lib/qt" \
        -datadir "${TERMUX_PREFIX}/share/qt" \
        -sysconfdir "${TERMUX_PREFIX}/etc/xdg" \
        -examplesdir "${TERMUX_PREFIX}/share/doc/qt/examples" \
        -plugindir "$TERMUX_PREFIX/libexec/qt" \
        -nomake tests \
        -nomake examples \
        -skip qt3d \
        -skip qtactiveqt \
        -skip qtandroidextras \
        -skip qtcanvas3d \
        -skip qtcharts \
        -skip qtconnectivity \
        -skip qtdatavis3d \
        -skip qtdoc \
        -skip qtgamepad \
        -skip qtgraphicaleffects \
        -skip qtmacextras \
        -skip qtnetworkauth \
        -skip qtpurchasing \
        -skip qtquickcontrols \
        -skip qtquickcontrols2 \
        -skip qtremoteobjects \
        -skip qtscript \
        -skip qtsensors \
        -skip qtserialbus \
        -skip qtserialport \
        -skip qtspeech \
        -skip qttools \
        -skip qtvirtualkeyboard \
        -skip qtwayland \
        -skip qtwebchannel \
        -skip qtwebengine \
        -skip qtwebglplugin \
        -skip qtwebsockets \
        -skip qtwinextras \
        -skip qtxmlpatterns \
        -skip x11extras \
        -no-accessibility \
        -no-glib \
        -no-eventfd \
        -icu \
        -qt-pcre \
        -qt-zlib \
        -qt-freetype \
        -ssl \
        -openssl-linked \
        -no-cups \
        -no-dbus \
        -no-system-proxies \
        -qt-harfbuzz \
        -opengl \
        -no-vulkan \
        -egl \
        -eglfs \
        -no-gbm \
        -no-kms \
        -no-linuxfb \
        -no-mirclient \
        -no-libudev \
        -no-libinput \
        -no-mtdev \
        -no-tslib \
        -gif \
        -ico \
        -sql-sqlite \
        -qt-libpng \
        -qt-libjpeg
}

termux_step_make() {
    make -j "${TERMUX_MAKE_PROCESSES}"
}

termux_step_make_install() {
    make install

    #######################################################
    ##
    ##  Save host-compiled Qt dev tools for
    ##  later use (e.g. cross-compiling Qt application).
    ##
    #######################################################

    cd "${TERMUX_PKG_SRCDIR}/qtbase" && {
        cp -a bin bin.host
    }

    #cd "${TERMUX_PKG_SRCDIR}/qttools" && {
    #    mkdir -p bin.host
    #    cp -a bin/{lconvert,lrelease,lupdate,qtattributionsscanner} bin.host/
    #}

    #######################################################
    ##
    ##  Compiling necessary libraries for target.
    ##
    #######################################################

    ## libQt5Bootstrap.a (qt5-base)
    cd "${TERMUX_PKG_SRCDIR}/qtbase/src/tools/bootstrap" && {
        make clean

        "${TERMUX_PKG_SRCDIR}/qtbase/bin/qmake" \
            -spec "${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross"

        make -j "${TERMUX_MAKE_PROCESSES}"
        install -Dm644 ../../../lib/libQt5Bootstrap.a "${TERMUX_PREFIX}/lib/libQt5Bootstrap.a"
        install -Dm644 ../../../lib/libQt5Bootstrap.prl "${TERMUX_PREFIX}/lib/libQt5Bootstrap.prl"
    }

    # libQt5QmlDevTools.a (qt5-declarative)
    cd "${TERMUX_PKG_SRCDIR}/qtdeclarative/src/qmldevtools" && {
        make clean

        "${TERMUX_PKG_SRCDIR}/qtbase/bin/qmake" \
            -spec "${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross"

        make -j "${TERMUX_MAKE_PROCESSES}"
        install -Dm644 ../../lib/libQt5QmlDevTools.a "${TERMUX_PREFIX}/lib/libQt5QmlDevTools.a"
        install -Dm644 ../../lib/libQt5QmlDevTools.prl "${TERMUX_PREFIX}/lib/libQt5QmlDevTools.prl"
    }

    # libQt5PacketProtocol.a (qt5-declarative)
    cd "${TERMUX_PKG_SRCDIR}/qtdeclarative/src/plugins/qmltooling/packetprotocol" && {
        make clean

       "${TERMUX_PKG_SRCDIR}/qtbase/bin/qmake" \
            -spec "${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross"

        make -j "${TERMUX_MAKE_PROCESSES}"
        install -Dm644 ../../../../lib/libQt5PacketProtocol.a "${TERMUX_PREFIX}/lib/libQt5PacketProtocol.a"
        install -Dm644 ../../../../lib/libQt5PacketProtocol.prl "${TERMUX_PREFIX}/lib/libQt5PacketProtocol.prl"
    }

    ## qt5-base tools
    for i in moc qlalr qvkgen uic rcc; do
        pushd ${TERMUX_PKG_SRCDIR}/qtbase/src/tools/$i
        make clean
        ${TERMUX_PKG_SRCDIR}/qtbase/bin/qmake -spec ${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross
        sed -i "s@-lpthread@@g" Makefile
        make -j$(nproc)
        install -Dm700 "../../../bin/${i}" "${TERMUX_PREFIX}/bin/${i}"
        popd
    done
    unset i

    #######################################################
    ##
    ##  Compiling necessary programs for target.
    ##
    #######################################################

    # Qt Declarative utilities.
    for i in qmlcachegen qmlimportscanner qmllint qmlmin; do
        cd "${TERMUX_PKG_SRCDIR}/qtdeclarative/tools/${i}" && {
            make clean

            "${TERMUX_PKG_SRCDIR}/qtbase/bin/qmake" \
                -spec "${TERMUX_PKG_SRCDIR}/qtbase/mkspecs/termux-cross"

            make -j "${TERMUX_MAKE_PROCESSES}"
            install -Dm700 "../../bin/${i}" "${TERMUX_PREFIX}/bin/${i}"
        }
    done

    # Unpacking prebuilt qmake from archive.
    cd "${TERMUX_PKG_SRCDIR}" && {
        tar xf "${TERMUX_PKG_BUILDER_DIR}/termux-prebuilt-qmake.txz"
        install \
            -Dm700 "./termux-prebuilt-qmake/bin/termux-${TERMUX_HOST_PLATFORM}-qmake" \
            "${TERMUX_PREFIX}/bin/qmake"
    }

    #######################################################
    ##
    ##  Fixes & cleanup.
    ##
    #######################################################

    ## Drop QMAKE_PRL_BUILD_DIR because reference the build dir.
    find "${TERMUX_PREFIX}/lib" -type f -name '*.prl' \
        -exec sed -i -e '/^QMAKE_PRL_BUILD_DIR/d' "{}" \;

    ## Remove *.la files.
    find "${TERMUX_PREFIX}/lib" -iname \*.la -delete

    ## Set qt spec path suitable for target.
    sed -i \
        's|/lib/qt//mkspecs/termux-cross"|/lib/qt/mkspecs/termux"|g' \
        "${TERMUX_PREFIX}/lib/cmake/Qt5Core/Qt5CoreConfigExtrasMkspecDir.cmake"
}

termux_step_create_debscripts() {
    ## FIXME: Qt should be built with fontconfig somehow instead
    ## of using direct path to fonts.
    ## Currently, using post-installation script to create symlink
    ## from /system/bin/fonts to $PREFIX/lib/fonts if possible.
    cp -f "${TERMUX_PKG_BUILDER_DIR}/postinst" ./
}

termux_step_post_massage() {
    #######################################################
    ##
    ##  Restoring utilities compiled for host.
    ##
    #######################################################

    ## qt5-tools
    #for i in lconvert lrelease lupdate qtattributionsscanner; do
    #    install \
    #        -Dm755 "${TERMUX_PKG_SRCDIR}/qttools/bin.host/${i}" \
    #        "${TERMUX_PREFIX}/bin/${i}"
    #done

    ## Restore qt spec path used for cross compiling.
    sed -i \
        's|/lib/qt/mkspecs/termux"|/lib/qt/mkspecs/termux-cross"|g' \
        "${TERMUX_PREFIX}/lib/cmake/Qt5Core/Qt5CoreConfigExtrasMkspecDir.cmake"
}
