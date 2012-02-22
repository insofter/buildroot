#!/bin/sh

TARGET_DIR=$1
HOST_DIR=${TARGET_DIR}/../host
BINARIES_DIR=${TARGET_DIR}/../images

${HOST_DIR}/usr/sbin/mkfs.ubifs -r ${TARGET_DIR}/mnt/data \
  -m 2048 -e 258048 -c 4000 -x none -o ${TARGET_DIR}/usr/share/data.ubifs

cp ${TARGET_DIR}/usr/share/data.ubifs ${BINARIES_DIR}/
