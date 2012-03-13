#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name} [-o|--output-dir DIR]
  [-h|--help] [-v|--version]

Builds an update package for icdtcp3 device.

  -o|--output-dir output directory; default is current directory
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
  exit 1;
}


# add_image
#  $1 image_name
#  $2 image_compression
#  $3 output_dir
add_image()
{
  local image_name image_compression output_dir
  local image_file image_size file_count output_file
  local ext compressor

  image_name="$1"
  image_compression="$2"
  output_dir="$3"

  file_count=`ls -1 | grep ${image_name} | wc -l`
  if [ ${file_count} -eq 1 ]; then
    image_file=`ls -1 | grep ${image_name}`
  elif [ ${file_count} -gt 1 ]; then
    error "More than one image '${image_name}*' found."
  else
    error "No image '${image_name}*' found."
  fi

  image_size=`stat --format=%s ${image_file}`
  test $? -eq 0 || error "stat '${image_file}' failed"
 
  # Figure out what compression tool to use
  case "${image_compression}" in
    none) ext=""; compressor="cat -" ;;
    gzip) ext=".gz"; compressor="gzip -c" ;;
    bzip2) ext=".bz2"; compressor="bzip2 -c" ;;
    lzma) ext=".lzma"; compressor="lzma -c" ;;
    *) error "Invalid or unsupported compression: \
         ${image_compression}" ;;
  esac

  # Copy image to output location and compress
  output_file="${output_dir}/${image_file}${ext}"
  cat "${image_file}" | ${compressor} > "${output_file}"
  test $? -eq 0 || error "Generating output image '${output_file}' failed"

  # Update output header file
  echo "${image_name}=${image_file}${ext}" >> "${output_dir}/header"
  echo "${image_name}-size=${image_size}" >> "${output_dir}/header"
  echo "${image_name}-compression=${image_compression}" >> "${output_dir}/header"
}

program_name=`basename "$0"`
version=`git describe | sed -e 's/+/-/g'`
output_dir=`pwd` #TODO output_dir="./output/images"

options=`getopt -o hv --long help,version -- "$@"`
eval set -- "$options"
while true ; do
  case "$1" in
    -o|--output) output_dir=`cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid output directory specified"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    -v|--version) print_version; exit 0 ;;
    --) shift; break ;;
    *) error "Parsing parameters failed at '$1'" ;;
  esac
done

#TODO cd "./output/images"

tmp_dir=`mktemp -d`

#TODO Read version form ./output/target/etc/{br-version,icdtcp3-version} files
long_version="2011.11-icdtcp3-0.0-9-g190d396"
short_version="icdtcp3-0.0-9-g190d396"

# From .config
#BR2_LINUX_KERNEL_VERSION="3.1.4-icdtcp3-0.0-14-g5585722-dirty"

# From Makefile
#export BR2_VERSION:=2011.11
#TOPDIR:=$(shell pwd)
#export BR2_VERSION_FULL:=$(BR2_VERSION)$(shell $(TOPDIR)/support/scripts/setlocalversion)

info "Creating icdtcp3 update package"
info "Package version: ${version}"
echo "version=${long_version}" > "${tmp_dir}/header"

info "Adding uImage..."
add_image "uImage" "lzma" "${tmp_dir}"

info "Adding rootfs..."
add_image "rootfs" "lzma" "${tmp_dir}"

info "Creating archive..."
cd "${tmp_dir}"
test $? -eq 0 || error "cd '${tmp_dir}' failed"
tar -cf "${output_dir}/${short_version}.img" *
test $? -eq 0 || error "tar failed"

info "Done"

# Get out of the tmp folder and discard it
cd
rm -R "${tmp_dir}"

exit 0

