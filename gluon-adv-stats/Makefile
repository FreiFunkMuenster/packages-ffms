include $(TOPDIR)/rules.mk

PKG_NAME:=gluon-adv-stats
PKG_VERSION:=1

include ../gluon.mk

define Package/gluon-adv-stats
  TITLE:=Provides a uci value to respondd
    DEPENDS:=+gluon-core +respondd
    endef

$(eval $(call BuildPackageGluon,gluon-adv-stats))
