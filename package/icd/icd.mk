#############################################################
#
# icd
#
#############################################################

ICD_VERSION = $(BR2_ICD_CUSTOM_GIT_VERSION)
ICD_SITE = $(BR2_ICD_CUSTOM_GIT_REPO_URL)
ICD_SITE_METHOD = git
ICD_DEPENDENCIES = sqlite libroxml libcurl

define VERSION_PATCH
	echo "$(ICD_VERSION)" > "$(@D)/VERSION"
endef

ICD_POST_PATCH_HOOKS += VERSION_PATCH

$(eval $(call CMAKETARGETS,package,icd))
