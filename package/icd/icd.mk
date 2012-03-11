#############################################################
#
# icd
#
#############################################################

ICD_VERSION = 0.0-49-g0b0c139-dirty
ICD_SOURCE = icd-$(ICD_VERSION).tar.bz2
ICD_SITE = http://www.insofter.pl
ICD_DEPENDENCIES = sqlite libroxml libcurl

$(eval $(call CMAKETARGETS,package,icd))
