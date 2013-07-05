#!/bin/ksh
################################################################################
# Original Author-   Tom Wallace
# Modified by Jayson Cofell
# Date-     May 31 2013
# Name-     get_mksysb
# Version-  v3
# Descrip-  Script to run a mksysb for servers in the nim database
# Input -   Reads an argument list as hostname.  If the
#           hostname exists in the nim database, it will be
#           backed up. Otherwise if no arguement is supplied,
#           all servers will be backed up. If a hostname fails
#           the nim database check, the whole script exits.
# Logic -   Script will keep two versions of a server MKSYSB on hand. v1 is the
#           most current, v2 is the previous mksysb.  When the script runs, if
#           v2 exists it will be dropped from the NIM database and deleted. 
#           If v1 exists, it will be renamed to v2, and the new MKSYSB will
#           be called v1. 
################################################################################
 
backup_loc=/backup/mksysb  #Location on NIM server where all mksysbs are stored
date_time=`date +%m%d%y_%H%M`  #Used as part of the mksysb filename
 
if [ $USER != 'root' ]
then
    echo "Error - Must be root user to run"
    exit -1
fi
 
#Check for a single arguement.  If it exists, check that it is in the NIM database
#and add it to the ${hostlist[]} array, else exit with error code 1.
#If no arguement is passed, add all standalone servers in the NIM database to the ${hostlist[]} array.
#If there are no standalone servers defined in the NIM database, exit with error code 2.
if [ $1 ]
then
    set -A hostlist $@
    echo "$@"
    until [[ $# -eq 0 ]]; do
        `lsnim -t standalone $1`
        if [ $? -ne 0 ]
        then
            echo "Error - host \"$1\" does not exist in nim database"
            exit 1
        fi
        echo "success $1"
        shift
    done
else
    set -A hostlist `lsnim -t standalone | awk '{print $1}'`
    if [ $? -ne 0 ]
    then
        echo "Error - no standalone servers defined in nim database"
        exit 2
    fi
fi
 
echo "`date '+%H:%M %m/%d/%y'` Backing up the following server(s): ${hostlist[*]}"
 
# Do the following for every server in the hostlist[] array - Server loop
for host in ${hostlist[*]}
do
    echo "${host}"
    mb_name=${host}_mksysb # Name of MKSYSB, version number will be added later
    file_name=${host}_${date_time}.mksysb # Filename for MKSYSB, with date time stamp
 
    # If version 2 of mb_name exists in NIM, remove it and delete associated file
    if [[ -n $(lsnim ${mb_name}_v2) ]]
    then
        echo "`date '+%H:%M %m/%d/%y'` Removing ${mb_name}_v2..."
        nim -o remove -a rm_image=yes ${mb_name}_v2
    fi
    # If version 1 of mb_name exists in NIM, remove it and redefine it as version 2
    if [[ -n $(lsnim ${mb_name}_v1) ]]
    then
        old_v1_fn="`lsnim -Z -a location ${mb_name}_v1 | awk -F: 'NR==2 { print $2 }'`"
        echo "`date '+%H:%M %m/%d/%y'` Moving ${mb_name}_v1 to ${mb_name}_v2..."
        nim -o remove ${mb_name}_v1
        nim -o define -t mksysb -a server=master -a location="${old_v1_fn}" ${mb_name}_v2
    fi
    # Run the size_preview flag while defining the MKSYSB and store the STDOUT & STDERR into variable ${size_mesg}
    # This will only check to see if enough space is available, a mksysb will not be created.
    size_mesg="`nim -o define -t mksysb -a server=master \
        -a location=\"${backup_loc}/${file_name}\" -a source=${host} \
        -a mk_image=yes -a mksysb_flags=e -a size_preview=yes ${mb_name}_v1 2>&1`"
    # If the size_preview was NOT successful, exit with error code 3.  Otherwise, see next comment
    if [ $? -ne 0 ]
    then
        echo "Error - From nim:\n${size_mesg}"
        exit 3
    else
        #Get the required and available space for the MKSYSB from the ${size_mesg} variable
        echo "${size_mesg}" | grep Required | awk '{print $3, $8}' | read req avail
        #If there is NOT enough space in the filesystem, exit with error code 4.
        #Otherwise, create mb_name version 1 MKSYSB. 
        if [ $req -gt $avail ]
        then
            echo "Error - Not enough disk space in ${backup_loc}: ${avail}MB free"
            echo "\t${req}MB is required for ${mb_name}.mksysb"
            exit 4
        else
            echo "`date '+%H:%M %m/%d/%y'` Creating ${mb_name}_v1..."
            nim -o define -t mksysb -a server=master \
            -a location="${backup_loc}/${file_name}" -a source=${host} \
            -a mk_image=yes -a mksysb_flags=e ${mb_name}_v1
        fi
    fi
done # End of server loop
echo "`date '+%H:%M %m/%d/%y'` Completed Backups"
exit 0
