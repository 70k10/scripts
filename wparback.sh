#!/bin/ksh
################################################################################
# Original Author-   Jayson Cofell
# Date-     Aug 05 2013
# Name-     backupwpar
# Version-  Final
# Descrip-  Script to run a savewpar for wpars in the nim database
# Input -   Reads an argument list as nim defined wpar.  If the
#           hostname exists in the nim database, it will be
#           backed up. If a hostname fails
#           the nim database check, the whole script exits.
# Logic -   Script will keep one version of a wpar backup on hand. 
################################################################################
 
backup_loc=/backup/wpar  #Location on NIM server where all wpar backups are stored
date_time=`date +%m%d%y_%H%M`  #Used as part of the wpar backup filename
min_size=10    #Minimum size of the filesystem in GB
 
if [ $USER != 'root' ]
then
    echo "Error - Must be root user to run"
    exit -1
fi
 
#Check for a single argument.  If it exists, check that it is in the NIM database
#and add it to the ${wparlist[]} array, else exit with error code 1.
#If no argument is passed, add all wpars in the NIM database to the ${wparlist[]} array.
#If there are no wpars defined in the NIM database, exit with error code 2.
if [ $1 ]
then
    set -A wparlist $@
    echo "$@"
    until [[ $# -eq 0 ]]; do
        `lsnim -t wpar $1`
        if [ $? -ne 0 ]
        then
            echo "Error - wpar \"$1\" does not exist in nim database"
            exit 1
        fi
        echo "success $1"
        shift
    done
else
    set -A wparlist `lsnim -t wpar | awk '{print $1}'`
    if [ $? -ne 0 ]
    then
        echo "Error - no wpars defined in nim database"
        exit 2
    fi
fi
 
echo "`date '+%H:%M %m/%d/%y'` Backing up the following server(s): ${wparlist[*]}"
 
# Do the following for every wpar in the wparlist[] array - wpar loop
for wpar in ${wparlist[*]}
do
    echo "${wpar}"
    sw_name=${wpar}_savewpar # Name of savewpar
    file_name=${wpar}_${date_time}.wpar # Filename for savewpar, with date time stamp
 
    # If the sw_name exists in NIM, remove it
    if [[ -n $(lsnim ${sw_name}) ]]
    then
        nim -o remove ${sw_name}
    fi
    if [ $(df -g ${backup_loc} | awk '{if(NR > 1) print $3}') -lt ${min_size} ]
    then
        echo "Error - From nim:\n${backup_loc} has less than ${min_size}GB free."
        exit 4
    else
        echo "`date '+%H:%M %m/%d/%y'` Creating ${sw_name}..."
        nim -o define -t savewpar -a server=master \
        -a location="${backup_loc}/${file_name}" -a source=${wpar} \
        -a mk_image=yes ${sw_name}
    fi
done # End of wpar loop
echo "`date '+%H:%M %m/%d/%y'` Completed Backups"
exit 0
