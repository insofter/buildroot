#############################################################
#
# icd
#
#############################################################

ICD_VERSION = 0.0-59-gdff24c3
ICD_SITE = $(ICDTCP3_GIT_ROOT)/icd
ICD_SITE_METHOD = git
ICD_DEPENDENCIES = sqlite libroxml libcurl

define VERSION_PATCH
	echo "$(ICD_VERSION)" > "$(@D)/VERSION"
endef

ICD_POST_PATCH_HOOKS += VERSION_PATCH

$(eval $(call CMAKETARGETS,package,icd))
