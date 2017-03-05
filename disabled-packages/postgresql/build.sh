TERMUX_PKG_HOMEPAGE=https://www.postgresql.org
TERMUX_PKG_DESCRIPTION="Object-relational SQL database"
TERMUX_PKG_MAINTAINER='Vishal Biswas @vishalbiswas'
TERMUX_PKG_VERSION=9.6.2
TERMUX_PKG_SRCURL=https://ftp.postgresql.org/pub/source/v$TERMUX_PKG_VERSION/postgresql-$TERMUX_PKG_VERSION.tar.bz2
TERMUX_PKG_SHA256=0187b5184be1c09034e74e44761505e52357248451b0c854dddec6c231fe50c9
TERMUX_PKG_DEPENDS="openssl, libcrypt, readline, libandroid-shmem"
TERMUX_PKG_EXTRA_CONFIGURE_ARGS="
USE_UNNAMED_POSIX_SEMAPHORES=1
--with-openssl
--without-gssapi
--with-readline
--with-system-tzdata=/system/usr/share/zoneinfo
"
TERMUX_PKG_EXTRA_MAKE_ARGS=" -s"

termux_step_pre_configure () {
	LDFLAGS+=" -llog"
}

termux_step_post_make_install() {
	# Sync with postgresql-contrib.subpackage.sh.
	for contrib in hstore pgcrypto pg_stat_statements; do
		(cd contrib/$contrib && make -s -j $TERMUX_MAKE_PROCESSES install)
	done
}
