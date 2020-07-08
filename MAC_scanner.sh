#!/bin/bash
DATE=$(date +%Y-%m-%d)
DATE2=$(date +%Y-%m-%d-%H:%M)

pwd=$(pwd)

if ! [ -x "$(command -v arp-scan)" ]; then
  echo 'Error: arp-scan is not installed.' >&2
  exit 1
fi
if [ -z "$1" ]; then
    echo "Enter network interface used for scan."
    echo "Example: mac_scanner.sh eth0"
    exit 1

else
    iface1=$1
fi

if [ ! -f $pwd/mac_masterlist ]; then
    echo "MAC address masterlist not found! Create a simple list of known MAC addresses titled mac_masterlist in script directory."
    exit 1
fi
mac_scan="$(command -v arp-scan)"

rm -f $pwd/mac_diff
rm -f $pwd/mac_scan_$DATE
rm -f $pwd/mac_scan_basic
rm -f $pwd/mac_scan_sorted
rm -f $pwd/mac_masterlist_sorted

$mac_scan --localnet >> $pwd/mac_scan_$DATE

awk -F " " '{print $2}' $pwd/mac_scan_$DATE | sed 's/packets//g' | sed 's/arp-scan//g' | sed "s/$iface1,//g" |  sed '/^[[:space:]]*$/d' >> $pwd/mac_scan_basic

cat $pwd/mac_scan_basic | sort | uniq >> $pwd/mac_scan_sorted

cat $pwd/mac_masterlist | sort | uniq >> $pwd/mac_masterlist_sorted

diff --ignore-case -u $pwd/mac_scan_sorted $pwd/mac_masterlist_sorted | grep '^-[^-]' | sed 's/^-//' >> $pwd/mac_diff

touch $pwd/mac_diff_$DATE
for mac in $(cat ${pwd}/mac_diff)
do
    m3=$($mac_scan --localnet | grep -i "${mac}")
    echo "${DATE2} ${m3}" >> $pwd/mac_diff_$DATE
    printf "\n" >> $pwd/mac_diff_$DATE
    sed -i '/^[[:space:]]*$/d' $pwd/mac_diff_$DATE

done

sed -i '/DUP/d' $pwd/mac_diff_$DATE
rm -f $pwd/mac_scan_sorted
rm -f $pwd/mac_masterlist_sorted
rm -f $pwd/mac_scan_basic
rm -f $pwd/mac_scan_$DATE
rm -f $pwd/mac_diff
