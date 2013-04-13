#!/bin/bash

case "$1" in
  icd)
    REPO=icd
    CONFIG_TAG=BR2_ICD_CUSTOM_GIT_VERSION
    ;;

  linux)
    REPO=linux
    CONFIG_TAG=BR2_LINUX_KERNEL_CUSTOM_GIT_VERSION
    SHORTSEARCH="v3.1.4-icdtcp3"
    SHORTREPLACE="{icd}"
    ;;

  u-boot)
    REPO=u-boot
    CONFIG_TAG=BR2_TARGET_UBOOT_CUSTOM_GIT_VERSION
    SHORTSEARCH="v2011.12-icdtcp3"
    SHORTREPLACE="{icd}"
    ;;

  *)
    echo "Brak wybranego repozytorium"
    exit 1
    ;;

esac



cd ${ICDTCP3_DIR}/$REPO

if ! git status | grep  -q "nothing to commit" 
then
  echo Commit ${REPO}!
  exit 1
fi

if [ "$SHORTSEARCH" != "" ];
then
  SHORTVER=`git describe | sed "s/${SHORTSEARCH}/${SHORTREPLACE}/g"`
else
  SHORTVER=`git describe`
fi

VER=`git describe`
INF=`git log --format=%s -1 | sed 's/[^a-zA-Z0-9 ]//g; s/  / /g'`


cd ${ICDTCP3_DIR}/buildroot

git checkout icdtcp3-2011.11 || exit 1

if ! git status | grep  -q "nothing to commit"
then
  echo Commit buildroot!
  exit 1
fi

if [ -e .config ]   
then
  mv .config .config.old
fi
make icdtcp3_defconfig

mv .config .config.tmp

cat .config.tmp | grep -v $CONFIG_TAG > .config

echo "$CONFIG_TAG"'="'$VER'"' >> .config

make savedefconfig

cp defconfig configs/icdtcp3_defconfig

git add configs/icdtcp3_defconfig

MSG="$REPO="$SHORTVER" ++"$INF

if [ `echo $MSG | wc -c` -gt 48 ]
then
  MSG=`echo "$MSG" | cut --bytes=1-65`"...++"
else
  MSG=`echo "$MSG" | cut --bytes=1-68`"++"
fi

git commit -m "$MSG"

