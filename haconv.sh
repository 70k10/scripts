#!/bin/bash

IFACE="eth0"
IFACENUM=1
RESOURCES=./haresources
COPYDIR="./netfiles/"


for n in $(for i in `cat "${RESOURCES}"`; do echo "$i" | grep -P "\d+\.\d+\.\d+\.\d+" | cut -d/ -f1; done); do
    netfile="${COPYDIR}ifcfg-${IFACE}:${IFACENUM}"
    echo "DEVICE=${IFACE}:${IFACENUM}" >> $netfile
    echo "ONBOOT=yes" >> $netfile
    echo "BOOTPROTO=none" >> $netfile
    echo "BROADCAST=$(echo "$n" | sed 's/\([0-9]\{1,3\}\.[0-9]\{1,3\}\.[0-9]\{1,3\}\.\)[0-9]\{1,3\}/\1255/')" >> $netfile
    echo "NETMASK=255.255.255.0" >> $netfile
    echo "IPADDR=${n}" >> $netfile
    echo "TYPE=Ethernet" >> $netfile
    echo "ONPARENT=yes" >> $netfile
    ((IFACENUM++))
done
