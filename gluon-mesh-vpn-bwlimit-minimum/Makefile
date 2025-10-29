include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-mesh-vpn-bwlimit-minimum
PKG_VERSION:=1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/gluon-mesh-vpn-bwlimit-minimum
  SECTION:=gluon
  CATEGORY:=Freifunk Muensterland
  TITLE:=mesh-vpn-bwlimit-minimum
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,$(PKG_NAME)))

