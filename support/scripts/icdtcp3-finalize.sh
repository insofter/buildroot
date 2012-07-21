#!/bin/sh

TARGET_DIR=$1
version=${BR2_VERSION_FULL}

>${TARGET_DIR}/etc/issue cat << EOF

Welcome to icdtcp3 (${version})

EOF

