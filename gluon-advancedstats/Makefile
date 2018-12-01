include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-advancedstats
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-advancedstats
  DEPENDS:=+gluon-core +libgluonutil +gluon-respondd
  TITLE:=Lets the user decide whether to record the advanced statistics.
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
