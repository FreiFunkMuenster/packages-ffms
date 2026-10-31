include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-statistics
PKG_VERSION:=3
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-config-mode-statistics
  TITLE:=Toggle the tracking of advanced statistics
  DEPENDS:=+gluon-config-mode-core +gluon-advancedstats
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
