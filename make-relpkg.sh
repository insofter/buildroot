#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name} [-b|--base-dir DIR]
  [-h|--help] [-v|--version]

Creates icdtcp3 release package, a bzipped archive containging all flashable
binaries plus version header. This tool expects ICDTCP3_SCRIPTS_DIR,
ICDTCP3_WORKING_DIR and ICDTCP3_BUILD_DIR  environment variables to be defined.

  -d|--release-dir      release directory where to put resulting archive
  -h|--help             show this information
  -v|--version          show version information

EOF
}

print_version()
{
>&2 cat <<EOF

${program_name} ${version}
Copyright (c) 2011-2012 Tomasz Rozensztrauch

EOF
}

info() 
{
  echo "${program_name}: $1" >&2
}

error() 
{
  echo "${program_name}: Error! $1" >&2
  if [ "$2" != "noexit" ]; then
    exit 1;
  fi
}

script_version()
{
  # Go to scripts directory in order to find out the script version
  if [ "x${ICDTCP3_SCRIPTS_DIR}" != "x" ]; then
    cd "${ICDTCP3_SCRIPTS_DIR}"
    if [ $? -eq 0 ]; then
      printf "%s" `git describe --dirty`
    else
      printf "?"
    fi
  else
    printf "?"
  fi
}

program_name=`basename "$0"`
version=$(script_version)

options=`getopt -o p:b:c:hv --long host-dir:,base-dir:,config-dir:,help,version -- "$@"`
test $? -eq 0 || error "Parsing parameters failed"
eval set -- "$options"
while true ; do
  case "$1" in
    -p|--host-dir) host_dir=`eval cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid host directory"; shift 2 ;;
    -b|--base-dir) base_dir=`eval cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid base directory"; shift 2 ;;
    -c|--config-dir) config_dir=`eval cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid config directory"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    -v|--version) print_version; exit 0 ;;
    --) shift; break ;;
    *) error "Parsing parameters failed at '$1'" ;;
  esac
done

test "x$1" = "x" || error "Parsing parameters failed at '$1'"

test "x${host_dir}" != "x" || error "Parsing parameters failed. Missing host-dir option"
test "x${base_dir}" != "x" || error "Parsing parameters failed. Missing base-dir option"
test "x${config_dir}" != "x" || error "Parsing parameters failed. Missing config-dir option"

package_version=`git describe --dirty | grep -oe "icdtcp3-.*" | sed -e 's/icdtcp3-//'`
test -n "${package_version}" || error "Reading package version failed"
package_version="v${package_version}"
prefix="icdtcp3"

temp_dir=`mktemp -d`
test $? -eq 0 || error "Creating temporary directory '${temp_dir}' failed"

info "Building '${prefix}-${package_version}' package"

info "Creating package header..."
info "version=${package_version}"
echo "version=${package_version}" > "${temp_dir}/header"
icd_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_ICD_CUSTOM_GIT_VERSION="\([^"]*\).*$/\1/p'`
test -n "${icd_version}" || error "Reading icd version failed"
info "version-icd=${icd_version}"
echo "version-icd=${icd_version}" >> "${temp_dir}/header"
at91bootstrap_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_TARGET_AT91BOOTSTRAP_CUSTOM_GIT_VERSION="\([^"]*\).*$/\1/p'`
test -n "${at91bootstrap_version}" || error "Reading at91bootstrap version failed"
echo "at91bootstrap=at91bootstrap.bin" >> "${temp_dir}/header"
info "at91bootstrap-version=${at91bootstrap_version}"
echo "at91bootstrap-version=${at91bootstrap_version}" >> "${temp_dir}/header"
uboot_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_TARGET_UBOOT_VERSION="*\([^"]*\).*$/\1/p'`
test -n "${uboot_version}" || error "Reading u-boot version failed"
echo "u-boot=u-boot.bin" >> "${temp_dir}/header"
info "u-boot-version=${uboot_version}"
echo "u-boot-version=${uboot_version}" >> "${temp_dir}/header"
uimage_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_LINUX_KERNEL_VERSION="*\([^"]*\).*$/\1/p'`
test -n "${uimage_version}" || error "Reading uimage version failed"
echo "uimage=uImage" >> "${temp_dir}/header"
info "uimage-version=${uimage_version}"
echo "uimage-version=${uimage_version}" >> "${temp_dir}/header"
rootfs_version=`git describe --dirty`
test -n "${rootfs_version}" || error "Reading rootfs version failed"
echo "rootfs=rootfs.ubifs" >> "${temp_dir}/header"
info "rootfs-version=${rootfs_version}"
echo "rootfs-version=${rootfs_version}" >> "${temp_dir}/header"

info "Copying files..."
rsync -a "${base_dir}/images/"  "${temp_dir}"
test $? -eq 0 || error "Copying package files failed"

info "Creating 'data.ubifs'..."
#"${host_dir}/usr/sbin/mkfs.ubifs" -r "${base_dir}/target/mnt/data" -m 2048 -e 258048 -c 4000 -x none \
"${host_dir}/usr/sbin/mkfs.ubifs" -r "${base_dir}/target/home" -m 2048 -e 258048 -c 4000 -x none \
 -o "${temp_dir}/data.ubifs"
test $? -eq 0 || error "Creating 'data.ubifs' failed"
echo "data=data.ubifs" >> "${temp_dir}/header"
info "data-version=${rootfs_version}"
echo "data-version=${rootfs_version}" >> "${temp_dir}/header"

info "Creating archive '${base_dir}/images/${prefix}-${package_version}.tar.bz2'..."
cd "${temp_dir}"
test $? -eq 0 || error "Changing directory to '${temp_dir}' failed"
tar -cjf "${base_dir}/images/${prefix}-${package_version}.tar.bz2" *
test $? -eq 0 || \
  error "Creating bzipped tar archive '${base_dir}/images/${prefix}-${package_version}.tar.bz2' failed"

info "Done"

cd
rm -R "${temp_dir}"

exit 0

