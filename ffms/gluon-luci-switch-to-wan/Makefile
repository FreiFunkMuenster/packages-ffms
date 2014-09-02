include $(TOPDIR)/rules.mk

PKG_NAME := gluon-luci-switch-to-wan
PKG_VERSION := 1

PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(INCLUDE_DIR)/package.mk

define Package/gluon-luci-switch-to-wan
  SECTION:=gluon
  CATEGORY:=Gluon
  TITLE:=Option to bridge the switch to the WAN port
  DEPENDS:=+gluon-core
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Configure
endef

define Build/Compile
endef

define Package/gluon-luci-switch-to-wan/install
	$(CP) ./files/* $(1)/
endef

$(eval $(call BuildPackage,gluon-luci-switch-to-wan))