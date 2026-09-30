include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-domain-changer
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-domain-changer
  DEPENDS:=+gluon-core +ecdsautils @GLUON_MULTIDOMAIN
  TITLE:=Allows community administrators to change domain and location settings by remote
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
