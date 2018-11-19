include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-statistics
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-config-mode-statistics
  TITLE:=Toggle the tracking of advanced statistics
  SECTION:=gluon
  CATEGORY:=Gluon
  DEPENDS:=+gluon-config-mode-core
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
