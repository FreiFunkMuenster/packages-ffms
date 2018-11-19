include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-respondd-ffmsl
PKG_VERSION:=2
PKG_BUILD_DIR := $(BUILD_DIR)/$(PKG_NAME)

include $(TOPDIR)/../package/gluon.mk

define Package/gluon-respondd-ffmsl
  PROVIDES:=gluon-respondd
  TITLE:=Provides node information to the network
  DEPENDS:=+gluon-core +libplatforminfo +libgluonutil +libuci +ubus +respondd
endef

$(eval $(call BuildPackageGluon,$(PKG_NAME)))
