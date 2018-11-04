include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-show-mac
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/gluon-config-mode-show-mac
  SECTION:=gluon
  CATEGORY:=Freifunk Muenster
  TITLE:=Shows the primary MAC on the reboot page
  DEPENDS:=gluon-config-mode-core +gluon-mesh-vpn-tunneldigger +gluon-config-mode-mesh-vpn
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./luasrc/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
