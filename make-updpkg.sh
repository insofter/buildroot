#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name} [-o|--output-dir DIR]
  [-h|--help] [-v|--version]

Builds an update package for icdtcp3 device.
The output directory can be specified by -o|--output-dir parameter.
If not provided then ICDTCP3_RELEASE_DIR environment variable is read.
If neighter the parameter nor the environment varaible is set
an error is returned.

  -o|--output-dir output directory
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


# add_image
#  $1 image_name
#  $2 image_compression
#  $3 output_dir
add_image()
{
  local image_name image_compression output_dir
  local image_ifile image_ofile image_size
  local compressor

  image_name="$1"
  image_ifile="$2"
  image_ofile="$3"
  image_compression="$4"
  output_dir="$5"

  image_size=`stat --format=%s ${image_ifile}`
  test $? -eq 0 || { error_msg "stat '${image_ifile}' failed"; return 1; }
 
  # Figure out what compression tool to use
  case "${image_compression}" in
    none) compressor="cat" ;;
    gzip) compressor="gzip -c" ;;
    bzip2) compressor="bzip2 -c" ;;
    lzma) compressor="lzma -c" ;;
    *) error "Invalid or unsupported compression '${image_compression}'" "noexit"
      return 1 ;;
  esac

  # Copy image to output location and compress
  ${compressor} "${image_ifile}" > "${output_dir}/${image_ofile}"
  test $? -eq 0 || { error "Compressing '${image_name}' failed" "noexit"; return 1; }

  # Update output header file
  echo "${image_name}=${image_ofile}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }
 
  echo "${image_name}-size=${image_size}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }

  echo "${image_name}-compression=${image_compression}" >> "${output_dir}/header"
  test $? -eq 0 || { error "Updating header failed" "noexit"; return 1; }

  return 0
}

program_name=`basename "$0"`
version=`git describe | sed -e 's/+/-/g'`
short_version=`git describe | sed -e 's/^[^+]*+\(.*\)$/\1/'`
kernel_version=`cat .config | sed -n -e 's/^BR2_LINUX_KERNEL_VERSION="\([^"]*\)".*$/\1/p'`
output_dir="${ICDTCP3_RELEASE_DIR}"

options=`getopt -o o:hv --long output-dir:,help,version -- "$@"`
eval set -- "$options"
while true ; do
  case "$1" in
    -o|--output-dir) output_dir=`cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid output directory specified"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    -v|--version) print_version; exit 0 ;;
    --) shift; break ;;
    *) error "Parsing parameters failed at '$1'" ;;
  esac
done

test "x$1" = "x" || error "Parsing parametes failed at '$1'"

test "x${output_dir}" != "x" || error "Neighter -o|--output_dir parameter \
nor ICDTCP3_RELEASE_DIR environment variable is specified"

cd "output/images"
test $? -eq 0 || error "cd to 'output/images' directory failed"

tmp_dir=`mktemp -d`

info "Creating icdtcp3 update package"
info "Package version: ${short_version}"
echo "version=${short_version}" > "${tmp_dir}/header"

info "Adding uImage..."
add_image "uImage" "uImage" "uImage-${kernel_version}" "none" "${tmp_dir}"
test $? -eq 0 || error "Adding uImage failed"

info "Adding rootfs..."
add_image "rootfs" "rootfs.ubifs" "rootfs-${version}.ubifs.lzma" "lzma" "${tmp_dir}"
test $? -eq 0 || error "Adding rootfs failed"

info "Creating archive..."
cd "${tmp_dir}"
test $? -eq 0 || error "cd '${tmp_dir}' failed"
tar -cf "${output_dir}/${short_version}.img" *
test $? -eq 0 || error "Creating archive failed"

info "Done"

# Get out of the tmp folder and discard it
cd
rm -R "${tmp_dir}"

exit 0

