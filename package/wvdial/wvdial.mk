WVDIAL_VERSION = 1.60
WVDIAL_SOURCE = wvdial-$(WVDIAL_VERSION).tar.gz
WVDIAL_SITE = http://alumnit.ca/download
WVDIAL_INSTALL_STAGING = YES
WVDIAL_DEPENDENCIES = wvstreams host-pkg-config
WVDIAL_CFLAGS = $(TARGET_CFLAGS) -Wno-write-strings -Wno-unused-result -fpermissive
WVDIAL_MAKE=$(MAKE1)

define WVDIAL_BUILD_CMDS
  $(TARGET_MAKE_ENV) $(MAKE) CFLAGS="$(WVDIAL_CFLAGS)" CXX=$(TARGET_CXX) CC=$(TARGET_CC) LD=$(TARGET_LD) AR="$(TARGET_AR)" -C $(@D)
endef

define WVDIAL_INSTALL_TARGET_CMDS
  $(INSTALL) -m 0755 $(@D)/wvdial $(@D)/wvdialconf ${TARGET_DIR}/usr/bin
endef

$(eval $(call GENTARGETS))

