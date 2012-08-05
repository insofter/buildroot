#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name}  [-d|--release-dir DIR]
  [-h|--help] [-v|--version]

Creates icdtcp3 update package, an archive with compressed binary images
if linux kernel and rootfs. This tool expects ICDTCP3_SCRIPTS_DIR,
ICDTCP3_WORKING_DIR and ICDTCP3_BUILD_DIR  environment variables to be defined.

  -d|--release-dir      release directory where to put resulting archive
  -h|--help       show this information
  -v|--version    show version information

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

add_image()
{
  local image_name image_version image_ifile image_ofile 
  local image_compression output_dir size compressor

  image_name="$1"
  image_version="$2"
  image_ifile="$3"
  image_ofile="$4"
  image_compression="$5"
  output_dir="$6"

  size=`stat --format=%s ${image_ifile}`
  test $? -eq 0 || { error "stat '${image_ifile}' failed" noexit; return 1; }
 
  # Figure out what compression tool to use
  case "${image_compression}" in
    none) compressor="cat" ;;
    gzip) compressor="gzip -c" ;;
    bzip2) compressor="bzip2 -c" ;;
    lzma) compressor="lzma -c" ;;
    *) error "Invalid or unsupported compression '${image_compression}'" noexit
      return 1 ;;
  esac

  # Copy image to output location and compress
  ${compressor} "${image_ifile}" > "${output_dir}/${image_ofile}"
  test $? -eq 0 || { error "Compressing '${image_name}' failed" "noexit"; return 1; }

  # Update output header file
  echo "${image_name}=${image_ofile}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }

  echo "${image_name}-version=${image_version}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }
 
  echo "${image_name}-size=${size}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }

  echo "${image_name}-compression=${image_compression}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }

  return 0
}

program_name=`basename "$0"`
version=$(script_version)

options=`getopt -o b:c:hv --long base-dir:,config-dir:,help,version -- "$@"`
test $? -eq 0 || error "Parsing parameters failed"
eval set -- "$options"
while true ; do
  case "$1" in
    -b|--base-dir) base_dir=`eval cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid release directory"; shift 2 ;;
    -c|--config-dir) config_dir=`eval cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid release directory"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    -v|--version) print_version; exit 0 ;;
    --) shift; break ;;
    *) error "Parsing parameters failed at '$1'" ;;
  esac
done

test "x$1" = "x" || error "Parsing parameters failed at '$1'"

if [ "x${base_dir}" = "x" ]; then
  base_dir=`pwd`
fi

if [ "x${config_dir}" = "x" ]; then
  config_dir=`pwd`
fi

package_version=`git describe --dirty | grep -oe "icdtcp3-.*" | sed -e 's/icdtcp3-//'`
test -n "${package_version}" || error "Reading package version failed"
package_version="v${package_version}"
prefix="icdtcp3"

temp_dir=`mktemp -d`
test $? -eq 0 || error "Creating temporary directory '${temp_dir}' failed"

info "Building '${prefix}-${package_version}' update package"

info "Creating package header..."
info "version=${package_version}"
echo "version=${package_version}" > "${temp_dir}/header"
icd_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_ICD_CUSTOM_GIT_VERSION="\([^"]*\).*$/\1/p'`
test -n "${icd_version}" || error "Reading icd version failed"
info "version-icd=${icd_version}"
echo "version-icd=${icd_version}" >> "${temp_dir}/header"

info "Adding uImage..."
uimage_version=`cat "${config_dir}/.config" | \
  sed -n -e 's/^BR2_LINUX_KERNEL_VERSION="*\([^"]*\).*$/\1/p'`
test -n "${uimage_version}" || error "Reading uimage version failed"
info "uimage-version=${uimage_version}"
add_image "uImage" "${uimage_version}" "${base_dir}/images/uImage" "uImage" "none" "${temp_dir}"
test $? -eq 0 || error "Adding uImage failed"

info "Adding rootfs..."
rootfs_version=`git describe --dirty`
test -n "${rootfs_version}" || error "Reading rootfs version failed"
info "rootfs-version=${rootfs_version}"
add_image "rootfs" "${rootfs_version}" "${base_dir}/images/rootfs.ubifs" "rootfs.ubifs.lzma" "lzma" "${temp_dir}"
test $? -eq 0 || error "Adding rootfs failed"

info "Creating archive '${base_dir}/images/${prefix}-${package_version}.img'..."
cd "${temp_dir}"
test $? -eq 0 || error "Changing directory to '${temp_dir}' failed"
tar -cf "${base_dir}/images/${prefix}-${package_version}.img" *
test $? -eq 0 || \
  error "Creating tar archive '${release_dir}/${prefix}-${package_version}.img' failed"

info "Done"

cd
rm -R "${temp_dir}"

exit 0

