#!/bin/bash


cd ${ICDTCP3_DIR}/linux

if ! git status | grep  -q "nothing to commit" 
then
  echo Commit linux!
  exit 1
fi

SHORTVER=`git describe | sed 's/v3.1.4-icdtcp3/{icd}/g'`
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

cat .config.tmp | grep -v "BR2_LINUX_KERNEL_CUSTOM_GIT_VERSION" > .config

echo 'BR2_LINUX_KERNEL_CUSTOM_GIT_VERSION="'$VER'"' >> .config

make savedefconfig

cp defconfig configs/icdtcp3_defconfig

git add configs/icdtcp3_defconfig

if [ `echo $MSG | wc -c` -gt 68 ]
then
  MSG=`echo "linux="$SHORTVER" ++"$INF | cut --bytes=1-65`"...++"
else
  MSG=`echo "linux="$SHORTVER" ++"$INF | cut --bytes=1-68`"++"
fi

git commit -m "$MSG"


