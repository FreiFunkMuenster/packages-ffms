include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-rfkill-disable
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-rfkill-disable
  TITLE:=Disables the wifi on/off button
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
