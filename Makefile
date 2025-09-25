# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2019-2022 Tianling Shen <cnsztl@immortalwrt.org>

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for UnblockNeteaseMusic (JavaScript)
LUCI_DEPENDS:=+dnsmasq-full +node \
	+PACKAGE_firewall:ipset \
	+@BUSYBOX_CONFIG_FLOCK \
	@(PACKAGE_libustream-mbedtls||PACKAGE_libustream-openssl||PACKAGE_libustream-wolfssl)
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-unblockneteasemusic
PKG_VERSION:=3.3
PKG_RELEASE:=3

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

define Package/luci-app-unblockneteasemusic/conffiles
/etc/config/unblockneteasemusic
/usr/share/unblockneteasemusic/core/
/usr/share/unblockneteasemusic/core_local_ver
/usr/share/unblockneteasemusic/server.crt
/usr/share/unblockneteasemusic/server.key
endef

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
