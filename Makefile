# SPDX-License-Identifier: GPL-3.0-only
#
# Copyright (C) 2021 ImmortalWrt.org

include $(TOPDIR)/rules.mk

LUCI_TITLE:=LuCI support for UnblockNeteaseMusic
LUCI_DEPENDS:=+busybox +dnsmasq-full +ipset +jsonfilter +libustream-openssl +node +uclient-fetch
LUCI_PKGARCH:=all

PKG_NAME:=luci-app-unblockneteasemusic
PKG_VERSION:=2.9
PKG_RELEASE:=2

PKG_MAINTAINER:=Tianling Shen <cnsztl@immortalwrt.org>

include $(TOPDIR)/feeds/luci/luci.mk

# call BuildPackage - OpenWrt buildroot signature
