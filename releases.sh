#!/usr/bin/env bash

# releases.sh
# My other repositories: https://github.com/carls0n/
# My website: https://openbsd.mywire.org
# Bash script to check for current release of OpenBSD. Download latest OpenBSD release in ISO or IMG format.
# OpenBSD releases are usually released in May and November.
# A list of current mirrors is located at https://www.openbsd.org/ftp.html

mirror=cdn.openbsd.org # default mirror
arch=$(uname -m) # default - use this computers architecture
image=img # default installation image - img for writing bootable USB sticks.

function usage {
echo "script to check for and download new OpenBSD releases"
echo "Usage: releases [-cadvimrpn] [options]"
echo "-c  check for new version"
echo "-v  override newest version number"
echo "-a  architecture - override default i.e i386, arm64"
echo "-i  installation image - override default img with iso"
echo "-d  download the selected installation image"
echo "-m  use mirror i.e mirrors.mit.edu or mirrors.ocf.berkeley.edu"
echo "-r  resume interrupted download"
echo "-p  prefer ipv6 [ 4 is default, 6 is optional ]"
echo "-n  image name - change default to \"miniroot\" or \"floppy\""
}

function get_args {
   [ $# -eq 0 ] && usage && exit
   while getopts ":da:i:v:rcm:p:n:h" arg; do
   case $arg in
   d) download=1;;
   a) arch="$OPTARG";;
   i) image="$OPTARG" ;;
   v) version="$OPTARG";;
   r) resume=1;;
   c) current=1;;
   m) mirror="$OPTARG";;
   p) prefer="$OPTARG";;
   h) usage && exit;;
   n) name="$OPTARG";;
   esac
   done
}

prefer="4"
name="install"

if [[ $(uname -s) != "OpenBSD" ]]
then 
printf "This script is intended to be used with a current OpenBSD installation.\n"
exit
fi

installed=$(uname -r)
version=$(bc <<< "$installed+0.1")

arch="$(uname -m)"
format=$(printf install$version | sed 's/\.//g'; printf .$image)

function check_current {
type -P curl 1>/dev/null
[ "$?" -ne 0 ] && echo "curl is required to check for new releases." && exit
if [[ $current == 1 && $download != 1 ]]; then
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
   if [ -z $image ]; then echo use the -i flag and image format. iso or img
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
   wget -q -c --inet$prefer-only --show-progress https://$mirror/pub/OpenBSD/$version/$arch/$format
   wget -q -c --inet$prefer-only https://$mirror/pub/OpenBSD/$version/$arch/SHA256.sig
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format; fi
   elif [[ $download == "1" ]]; then
   if curl -s --ipv$prefer https://$mirror/pub/OpenBSD/$version/$arch/ | grep -q $format
   then
   wget -q --inet$prefer-only --show-progress https://$mirror/pub/OpenBSD/$version/$arch/$format
   wget -q --inet$prefer-only https://$mirror/pub/OpenBSD/$version/$arch/SHA256.sig
   signify -Cp /etc/signify/openbsd-$filename-base.pub -x SHA256.sig $format
   rm SHA256.sig   
   else printf "Version $version is not available\n"
fi
fi
exit
}

get_args $@
check_current
#check_flags
download
