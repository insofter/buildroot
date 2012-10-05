#!/bin/bash


cd /home/insofter/projects/icd

if ! git status | grep  -q "nothing to commit" 
then
  echo Commit icd!
  exit 1
fi

VER=`git describe`
INF=`git log --format=%s -1 | sed 's/[^a-zA-Z0-9 ]//g; s/  / /g'`


cd /home/insofter/projects/buildroot

git checkout icdtcp3-2011.11 || exit 1

if ! git status | grep  -q "nothing to commit"
then
  echo Commit buildroot!
  exit 1
fi

if ! [ -e .config ]
then
  make icdtcp3_defconfig
fi

mv .config .config.old

cat .config.old | grep -v "BR2_ICD_CUSTOM_GIT_VERSION" > .config

echo 'BR2_ICD_CUSTOM_GIT_VERSION="'$VER'"' >> .config

make savedefconfig

cp defconfig configs/icdtcp3_defconfig

git add configs/icdtcp3_defconfig

MSG="icd="$VER" ++"$INF

if [ `echo $MSG | wc -c` -gt 48 ]
then
  MSG=`echo "icd="$VER" ++"$INF | cut --bytes=1-45`"...++"
else
  MSG=`echo "icd="$VER" ++"$INF | cut --bytes=1-48`"++"
fi

git commit -m "$MSG"


