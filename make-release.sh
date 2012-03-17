#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name} [-o|--output-dir OUTPUT_DIR] [-O|--build-dir BUILD_DIR]
  [-h|--help] [-v|--version]

Exports binary files to release directory appending version information
to each file. The release directory can be specified by -o|--output-dir
parameter. If the parameter is not provided then ICDTCP3_RELEASE_DIR
environment variable is used. If neighter of them is set then current 
directory is used. When the project build directory is diffent than
the source directory (out-of-source build) then the build directory
may be provided in -O|--build-dir parameter. The script must be
executed from source top directory.

  -o|--output-dir release directory
  -O|--build-dir  project build directory
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

program_name=`basename "$0"`
version=`git describe | sed -e 's/^v//' -e 's/+/-/g'`
kernel_version=`cat .config | sed -n -e 's/^BR2_LINUX_KERNEL_VERSION="\([^"]*\)".*$/\1/p'`

if [ "x${ICDTCP3_RELEASE_DIR}" != "x" ]; then
  output_dir="${ICDTCP3_RELEASE_DIR}"
else
  output_dir=`pwd`
fi

build_dir=`pwd`

options=`getopt -o o:O:hv --long output-dir:,build-dir:,help,version -- "$@"`
eval set -- "$options"
while true ; do
  case "$1" in
    -o|--output-dir) output_dir=`cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid output directory specified"; shift 2 ;;
    -O|--build-dir) build_dir=`cd "$2" && pwd`;
       test $? -eq 0 || error "Invalid build directory specified"; shift 2 ;;
    -h|--help) print_usage; exit 0 ;;
    -v|--version) print_version; exit 0 ;;
    --) shift; break ;;
    *) error "Parsing parameters failed at '$1'" ;;
  esac
done

test "x$1" = "x" || error "Parsing parameters failed at '$1'"

info "Synchronizing 'uImage'..."
rm -f "${output_dir}"/uImage*
rsync -a "${build_dir}/output/images/uImage" "${output_dir}/uImage-${kernel_version}"
test $? -eq 0 || error "Synchronizing 'uImage' failed"

info "Synchronizing 'rootfs.ubifs'..."
rm -f "${output_dir}"/rootfs*
rsync -a "${build_dir}/output/images/rootfs.ubifs" "${output_dir}/rootfs-${version}.ubifs"
test $? -eq 0 || error "Synchronizing 'rootfs.ubifs' failed"

info "Creating 'data.ubifs'..."
rm -f "${output_dir}"/data*
mkfs.ubifs -r "${build_dir}/output/target/mnt/data" -m 2048 -e 258048 -c 4000 -x none \
 -o "${output_dir}/data-${version}.ubifs"
test $? -eq 0 || error "Creating 'data.ubifs' failed"

info "Done"

exit 0

