
include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-config-mode-adv-stats
PKG_VERSION:=1

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  TITLE:=Toggle adv-stats
    DEPENDS:=+gluon-config-mode-core
    endef

$(eval $(call BuildPackage,$(PKG_NAME)))
