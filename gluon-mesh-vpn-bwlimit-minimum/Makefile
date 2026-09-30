include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-mesh-vpn-bwlimit-minimum
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-mesh-vpn-bwlimit-minimum
  DEPENDS:=+gluon-core
  TITLE:=Enforces minimum values for the mesh VPN bandwidth limit
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
