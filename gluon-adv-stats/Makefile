
include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-adv-stats
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Provides a uci value to respondd
    DEPENDS:=+gluon-core +respondd
    endef

$(eval $(call BuildPackage,$(PKG_NAME)))
