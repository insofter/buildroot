#############################################################
#
# icd
#
#############################################################

ICD_VERSION = 1.0
ICD_SOURCE = icd-$(ICD_VERSION).tar.bz2
ICD_SITE = http://www.insofter.pl
ICD_DEPENDENCIES = sqlite libroxml libcurl

$(eval $(call CMAKETARGETS,package,icd))
