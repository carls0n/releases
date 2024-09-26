#!/usr/bin/env bash

# getbsd.sh
# My other repositories: https://github.com/carls0n/
# My main website: https://openbsd.mywire.org
# Bash script to check for current release of OpenBSD. Download latest OpenBSD release in ISO or IMG format.
# OpenBSD releases are usually released in May and November.
# A list of current mirrors is located at https://www.openbsd.org/ftp.html

mirror=cdn.openbsd.org # default mirror

function usage {
echo "script to check for and download new OpenBSD releases"
echo "Usage: releases [-advimrpn] [options]"
echo "-v  OpenBSD version number"
echo "-a  architecture - i.e i386, arm64"
echo "-i  installation image - override default img with iso"
echo "-d  download the selected installation image"
echo "-m  use mirror i.e mirrors.mit.edu or mirrors.ocf.berkeley.edu"
echo "-r  resume interrupted download"
echo "-p  prefer ipv6 [ \"4\" is default, \"6\" is optional ]"
echo "-n  image name - change default to \"miniroot\" or \"floppy\""
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts ":da:i:v:rm:n:hp:" arg; do
   case $arg in
   d) download=1;;
   p) prefer="$OPTARG";;
   a) arch="$OPTARG";;
   i) image="$OPTARG" ;;
   v) version="$OPTARG";;
   r) resume=1;;
   m) mirror="$OPTARG";;
   h) usage && exit;;
   n) name="$OPTARG";;
   esac
   done
}

prefer="4"

function check_release {
type -P curl 1>/dev/null
[ "$?" -ne 0 ] && echo "curl is required to check for new releases." && exit
if [[ $download != 1 ]]; then
if curl -s --ipv$prefer https://$mirror/pub/OpenBSD/$version/$arch/ | grep -q $(printf $name$version | sed 's/\.//g'; printf .$image)
then
printf "OpenBSD version $version is ready for download\n"
else printf "OpenBSD version $version is not available\n"
fi
fi
}

function check_flags {
   if [ -z "$arch" ]; then echo use the -a flag and architecture
   exit; fi
   if [ -z "$version" ]; then echo use the -v flag adnd the version
   exit; fi
 if [ -z "$image" ]; then echo use the -i for image \(img or iso\)
   exit; fi
 if [ -z "$name" ]; then echo use the -n for image name. i.e, install,  miniroot
   exit; fi
}

function download {   
   type -P wget 1>/dev/null
   [ "$?" -ne 0 ] && echo "wget is required to download images." && exit
   format=$(printf $name$version | sed 's/\.//g'; printf .$image)
   filename=$(echo $format | sed "s/$name//" | cut -d . -f 1)
   if [[ $resume == 1 ]] ; then
   if curl -s --ipv$prefer https://$mirror/pub/OpenBSD/$version/$arch/ | grep -q $format
   then
   wget -q -c --show-progress https://$mirror/pub/OpenBSD/$version/$arch/$format
   wget -q -c https://$mirror/pub/OpenBSD/$version/$arch/SHA256.sig
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format; fi
   elif [[ $download == "1" ]]; then
   if curl -s https://$mirror/pub/OpenBSD/$version/$arch/ | grep -q $format
   then
   wget -q --show-progress https://$mirror/pub/OpenBSD/$version/$arch/$format
   wget -q https://$mirror/pub/OpenBSD/$version/$arch/SHA256.sig
   if [[ $(uname -s) != "OpenBSD" ]]; then echo signature can only be verified on OpenBSD && exit
   elif [[ $(uname -s) == "OpenBSD" ]]; then
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format
   rm SHA256.sig   
   else printf "Version $version is not available\n"
fi
fi
fi
exit
}

get_args $@
check_flags
check_release
download


