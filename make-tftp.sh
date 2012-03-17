#!/bin/sh

print_usage()
{
>&2 cat <<EOF

Usage: ${program_name} [-o|--output-dir DIR]
  [-h|--help] [-v|--version]

Exports binary files to tftp folder.
The tftp directory can be specified by -o|--output-dir parameter.
If not provided then ICDTCP3_TFTP_DIR environment variable is read.
If neighter the parameter nor the environment varaible is set an error
is returned.

  -o|--output-dir tftp directory
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

program_name=`basename "$0"`
version=`git describe | sed -e 's/+/-/g'`
output_dir="${ICDTCP3_TFTP_DIR}"

options=`getopt -o ohv --long output,help,version -- "$@"`
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

test "x$1" = "x" || error "Parsing parametes failedi at '$1'"

test "x${output_dir}" != "x" || error "Neighter -o|--output_dir parameter \
nor ICDTCP3_TFTP_DIR environment variable is specified"

info "Synchronizing 'uImage'..."
rsync -a "./output/images/uImage" "${output_dir}/"
test $? -eq 0 || error "Syncronizing 'uImage' failed"

info "Synchronizing 'rootfs.ubifs'..."
rsync -a "./output/images/rootfs.ubifs" "${output_dir}/"
test $? -eq 0 || error "Synchronizing 'tootfs.ubifs' failed"

info "Creating 'data.ubifs'..."
mkfs.ubifs -r output/target/mnt/data -m 2048 -e 258048 -c 4000 -x none \
 -o ${output_dir}/data.ubifs
test $? -eq 0 || error "Creating 'data.ubifs' failed"

info "done"

exit 0

