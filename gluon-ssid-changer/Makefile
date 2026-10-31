include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-ssid-changer
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-ssid-changer
  DEPENDS:=+gluon-core +micrond
  TITLE:=Changes the SSID when the node has no sufficient connection to a gateway
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
