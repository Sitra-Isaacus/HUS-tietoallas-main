#!/bin/bash

# Licensed to the Apache Software Foundation (ASF) under one
# or more contributor license agreements.  See the NOTICE file
# distributed with this work for additional information
# regarding copyright ownership.  The ASF licenses this file
# to you under the Apache License, Version 2.0 (the
# "License"); you may not use this file except in compliance
# with the License.  You may obtain a copy of the License at

#   http://www.apache.org/licenses/LICENSE-2.0

# Unless required by applicable law or agreed to in writing,
# software distributed under the License is distributed on an
# "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
# KIND, either express or implied.  See the License for the
# specific language governing permissions and limitations
# under the License.

# This script is necessary to set up the data diskS

#---------------------------------
# usage
#---------------------------------
function usage {
    cat <<EOF
==========================================================================================================
This script creates encrypted disk(s) to target host. 
The amount of encrypted disk is min(amount of available disk, amount of mountpoints gieven as parameter)
==========================================================================================================
Usage: $0 -m <mountpoints> -k <keyfile> [-d] [-t]
where
    -m "<mountpoints>"  Which mountpoints to use for the host
    -k <keyfile>        Name of the encryption keyfile with full path. 
                        If the file exists it is used
                        If the file does not exist it is created
    -d                  Causes debug messages to written into ${debugFile}
    -t                  Test flag:
                        - Commands that change system state:
                          - Write the command to screen but do not execute it
                        - Other commands:
                          - Write the command to screen and execute it

Syntax of the <mountpoints> is
    <mountpoint>[:<mountpoint>]*

----------------------------------------------------------------------------------------------------------
Example: $0 -m "/datadisk_1:/datadisk_2" -k /etc/myKeyfile
==========================================================================================================
EOF
}

function executeCommandAsRoot() {
    sudo su <<EOF
$1
EOF
}
function printOneCommand() {
    echo "################################################################" >>${debugFile}
    echo "##### $2                                                        " >>${debugFile}
    echo "################################################################" >>${debugFile}
    eval $2                                                                 >>${debugFile}
}

#---------------------------------
# printInitialData
#---------------------------------
function printInitialData() {
    echo "neededmountpoints: '${neededmountpoints}'"                                           >>${debugFile}
    echo "createdDisks:      '${createdDisks}'"                                                >>${debugFile}
    echo "nopartitiontable:  '${nopartitiontable}'"                                            >>${debugFile}
    echo "unmounted:         '${unmounted}'"                                                   >>${debugFile}
    echo "cryptedDisksInfo:  '${cryptedDisksInfo}'"                                            >>${debugFile}
    echo "===================================================================================" >>${debugFile}
}

#---------------------------------
# printStatus
#---------------------------------
function printStatus() {
    echo "================================================================" >>${debugFile}
    echo "$1"                                                               >>${debugFile}
    echo "================================================================" >>${debugFile}
    printOneCommand "sudo lsblk"
    printOneCommand "sudo lsscsi"
    printOneCommand "sudo mount | grep \"/dev/sd\""
    printOneCommand "ls -la /etc/fstab ; sudo cat /etc/fstab"
    printOneCommand "ls -la /etc/crypttab ; sudo cat /etc/crypttab"
}

#---------------------------------------------------------------------------
# findExistingSdDevices
#
# Find all sd devices that exist in this host
#
# Sets: existingSdDevices    (e.g. "/dev/sda /dev/sdb /dev/sdc /dev/sdd"
#---------------------------------------------------------------------------
function findExistingSdDevices() {
    existingSdDevices=`sudo ls -1 /sys/block | grep sd | xargs -I {} echo -n "/dev/{} "`

    if [ "${test_flag}" == "yes" ]
    then
        echo "sudo ls -1 /sys/block | grep sd | xargs -I {} echo -n \"/dev/{} \""
        echo "existingSdDevices: '${existingSdDevices}'"
        echo "--------------------------------------------------------------"
    fi
}

#----------------------------------------------------------------------------
# findFreeSdDevices
#
# It is assumed that newly created disk(s) have partition table as "unknown"
# The list becomes empty if none exists
#
# Sets: freeSdDevices    (e.g. "/dev/sdc /dev/sdd")
#----------------------------------------------------------------------------
function findFreeSdDevices() {
    freeSdDevices=""
    for existingSdDevice in ${existingSdDevices}
    do
        freeSdDevices="${freeSdDevices} "`sudo parted ${existingSdDevice} print 2>/dev/null | grep "Partition Table" | cut -d " " -f3 | xargs -I {} echo "${existingSdDevice} {}" | grep unknown | cut -d " " -f1`
    done

    [ "${test_flag}" == "yes" ] && echo -e "freeSdDevices: '${freeSdDevices}'\n--------------------------------------------------------------"
}

#-------------------------------------------------------------------------
# findSdDevicesToEncryptAndTheirMountpoints
#
# Generates a list of sd devices that need to be encrypted
# If there are no such devices free the list becomes empty
#
# The amount of elements of generated list is 
#     min(<amount of free sd devices>, <amount of needed mount points>)
#
# Uses: freeSdDevices           (e.g. "/dev/sdc /dev/sdd")
#       neededMountpoints       (e.g. "/mnt/datadisk1:/man/datadisk2")
#
# Sets: sdDevicesToEncrypt      (e.g. "/dev/sdc /dev/sdd")
#       mountpointsToCreate     (e.g. "/mnt/datadisk1 /mnt/datadisk2")
#-------------------------------------------------------------------------
function findSdDevicesToEncryptAndTheirMountpoints() {
    sdDevicesToEncrypt=""
    mountpointsToCreate=""

    numberOfFreeSdDevices=`echo ${freeSdDevices} | awk '{print NF}'`
    numberOfNeededMountpoints=`echo ${neededMountpoints} | awk -F":" '{print NF}'`
    #------------------------------
    # Take the minimum of these two
    #------------------------------
    minAmountOFDisksToEncrypt=`[[ ${numberOfFreeSdDevices} -le ${numberOfNeededMountpoints} ]] && echo "${numberOfFreeSdDevices}" || echo "${numberOfNeededMountpoints}}"`

    if [[ ${minAmountOFDisksToEncrypt} > 0 ]]
    then
        sdDevicesToEncrypt=`echo ${freeSdDevices} | cut -d" " -f 1-${minAmountOFDisksToEncrypt}`
        mountpointsToCreate=`echo ${neededMountpoints} | cut -d":" -f 1-${minAmountOFDisksToEncrypt} | sed -e 's/:/ /'`
    fi

    if [ "${test_flag}" == "yes" ]
    then
        echo "--------------------------------------------------------------------------------"
        echo "sdDevicesToEncrypt=\`echo ${freeSdDevices} | cut -d\" \" -f 1-${minAmountOFDisksToEncrypt}\`"
        echo "mountpointsToCreate=\`echo ${neededMountpoints} | cut -d\":\" -f 1-${minAmountOFDisksToEncrypt} | sed -e 's/:/ /'\`"
        echo "--------------------------------------------------------------------------------"
        echo "numberOfFreeSdDevices:     ${numberOfFreeSdDevices}"
        echo "numberOfNeededMountpoints: ${numberOfNeededMountpoints}"
        echo "minAmountOFDisksToEncrypt: ${minAmountOFDisksToEncrypt}"
        echo "sdDevicesToEncrypt:        ${sdDevicesToEncrypt}"
        echo "mountpointsToCreate:       ${mountpointsToCreate}"
        echo "--------------------------------------------------------------------------------"
    fi
}

#-----------------------------------------------
# createKeyfile
#
# Creates the LUKS key file if it does not exist
#-----------------------------------------------
function createKeyfile() {
    if [ ! -f ${keyfile} ]
    then
        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo dd bs=512 count=4 if=/dev/urandom of=${keyfile}"
            echo "sudo chmod 600 ${keyfile}"
            echo "--------------------------------------------------------------------------------"
        else
            sudo dd bs=512 count=4 if=/dev/urandom of=${keyfile}
            sudo chmod 600 ${keyfile}
        fi
    fi
}

#-------------------------------------------------------------------------------
# createPartitions
#
# Creates only primary partition to disks to be encrypted
# Partition type:   msdos
# File system type: ext4 
# This one partition number shall be 1
#
# Uses: sdDevicesToEncrypt      (e.g. "/dev/sdc /dev/sdd")
#
# Sets: createdPartitions       (e.g. "/dev/sdc1 /dev/sdd1")
#-------------------------------------------------------------------------------
function createPartitions() {
    createdPartitions=""
    for device in ${sdDevicesToEncrypt}
    do
        createdPartitions="${createdPartitions} ${device}${PRIMARY_PARTITION}"

        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo parted -s ${device} mklabel msdos"
            echo "sudo parted -s ${device} mkpart primary ext4 0\% 100\%"
            echo "--------------------------------------------------------------------------------"
        else
            sudo parted -s ${device} mklabel msdos
            sudo parted -s ${device} mkpart primary ext4 0\% 100\%
        fi
    done
    [ "${test_flag}" == "yes" ] && echo -e "createdPartitions: '${createdPartitions}'\n--------------------------------------------------------------------------------"
}

#-------------------------------------------------------------------------------
# createFilesystemForSdDevicesToEncrypt
#
# Creates ext4 file system for primary partition (number 1) of needed devices
#
# Uses: createdPartitions       (e.g. "/dev/sdc1 /dev/sdd1")
#-------------------------------------------------------------------------------
function createFilesystemForSdDevicesToEncrypt() {
    for partition in ${createdPartitions}
    do
        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo mkfs.ext4 ${partition}"
        else
            sudo mkfs.ext4 ${partition}
        fi
    done
    [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
}

#-------------------------------------------------------------------------------
# encryptDevices
#
# Encrypts the needed devices
#
# Uses: createdPartitions       (e.g. "/dev/sdc1 /dev/sdd1")
#       keyfile
#-------------------------------------------------------------------------------
function encryptDevices() {
    for partition in ${createdPartitions}
    do
        #-----------------
        # Encrypt the disk
        #-----------------
        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo cryptsetup --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --batch-mode luksFormat ${partition} ${keyfile}"
        else
            sudo cryptsetup --cipher aes-xts-plain64 --key-size 256 --hash sha256 --iter-time 2000 --use-urandom --batch-mode luksFormat ${partition} ${keyfile}
        fi
        ((i+=1))
    done
    [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
}

#-------------------------------------------------------------------------------
# openEncryptedDevices
#
# Opens encrypted devices
#
# Uses: createdPartitions       (e.g. "/dev/sdc1 /dev/sdd1")
#       mountpointsToCreate     (e.g. "/mnt/datadisk1 /mnt/datadisk2")
#       keyfile
#
# Sets: luksMountpoints         (e.g. "/dev/mapper/datadisk1 /dev/mapper/datadisk2")
#-------------------------------------------------------------------------------
function openEncryptedDevices() {
    luksMountpoints=""
    i=1
    for partition in ${createdPartitions}
    do
        #------------------------------------------------------------------
        # Take the last part of the mount point of the disk to be encrypted
        # Example: mountpoint=/mnt/datadisk1 => luksMountpoint=datadisk1
        #------------------------------------------------------------------
        luksMap=`echo ${mountpointsToCreate} | cut -d " " -f${i} | xargs -I {} basename {}`
        luksMountpoints="${luksMountpoints} /dev/mapper/${luksMap}"

        #--------------------------------------------------------------------------------
        # Open the encrypted disk
        # This command creates luks mount point which needs also file system
        #--------------------------------------------------------------------------------
        if [ "${test_flag}" == "yes" ]
        then 
            echo "luksMountpoint=\`echo ${mountpointsToCreate} | cut -d \" \" -f${i} | xargs -I {} basename {}\`"
            echo "sudo cryptsetup luksOpen ${partition} ${luksMap} --key-file ${keyfile}"
        else
            sudo cryptsetup luksOpen ${partition} ${luksMap} --key-file ${keyfile}
        fi
        ((i+=1))
    done
    if [ "${test_flag}" == "yes" ]
    then
        echo "--------------------------------------------------------------------------------"
        echo "luksMountpoints: '${luksMountpoints}'"
        echo "--------------------------------------------------------------------------------"
    fi
}

#-------------------------------------------------------------------------------
# creteFilesystemForLuksDevices
#
# Creates filesystem ext4 for created luks devices
#
# Uses: luksMountpoints     (e.g. "/dev/mapper/datadisk1 /dev/mapper/datadisk2")
#-------------------------------------------------------------------------------
function creteFilesystemForLuksDevices() {
    for luksMountpoint in ${luksMountpoints}
    do
        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo mkfs.ext4 ${luksMountpoint}"
        else
            sudo mkfs.ext4 ${luksMountpoint}
        fi
    done
    [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
}

#--------------------------------------------------------------------
# createMountpoints
# 
# This will create the mountpoints for the encrypted disks
#
# Uses: mountpointsToCreate     (e.g. "/mnt/datadisk1 /mnt/datadisk2")
#--------------------------------------------------------------------
function createMountpoints() {
    for mountpoint in ${mountpointsToCreate}
    do
        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo mkdir -p ${mountpoint}"
        else
            sudo mkdir -p ${mountpoint}
        fi
    done
    [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
}

#-----------------------------------------------------------------------------------
# mapNeededMountpointsToLuksMountpoints
# 
# This will create the mountpoints for the encrypted disks
#
# Uses: mountpointsToCreate     (e.g. "/mnt/datadisk1 /mnt/datadisk2")
#       luksMountpoints         (e.g. "/dev/mapper/datadisk1 /dev/mapper/datadisk2")
#-----------------------------------------------------------------------------------
function mapNeededMountpointsToLuksMountpoints() {
    i=1
    for mountpoint in ${mountpointsToCreate}
    do
        luksMountpoint=`echo ${luksMountpoints} | cut -d " " -f${i}`

        if [ "${test_flag}" == "yes" ]
        then 
            echo "sudo mount ${luksMountpoint} ${mountpoint}"
        else
            sudo mount ${luksMountpoint} ${mountpoint}
        fi
        ((i+=1))
    done
    [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
}

#-----------------------------------------------------------------------------------
# updateCrypttabAndFstab
#
# Uses: neededMountpoints     (e.g. "/mnt/datadisk1:/mnt/datadisk2")
#-----------------------------------------------------------------------------------
function updateCrypttabAndFstab() {
    regexp=`echo ${neededMountpoints} | sed -e 's/:/|/g'`

    #---------------------------------------------------------------------------------------------------------------------------------------
    # Example of mappings:
    # "datadisk1 /mnt/datadisk1 120eb6c0-63e3-4679-bb3a-b2aacd19a815 sdc1:atadisk2 /mnt/datadisk2 5a6de9e0-71d5-4d7e-b05a-ccbcbc4f7b78 sdd1"
    #---------------------------------------------------------------------------------------------------------------------------------------
    mappings=`sudo lsblk --raw -o NAME,MOUNTPOINT,UUID,PKNAME | egrep ${regexp} | xargs -I {} echo -n "${MOUNTPOINT_SEPARATOR}{}"`

    if [ "${test_flag}" == "yes" ]
    then
        echo "sudo lsblk --raw -o NAME,MOUNTPOINT,UUID,PKNAME | egrep ${regexp} | xargs -I {} echo -n \"${MOUNTPOINT_SEPARATOR}{}\""
        echo "regexp:             '${regexp}'"
        echo "mappings:           '${mappings}'"
    fi

    OLD_IFS=${IFS}
    IFS=${MOUNTPOINT_SEPARATOR}

    fstabEntries=""
    crypttabEntries=""

    for mapping in ${mappings:1}
    do
        datadisk=`echo ${mapping} | cut -d " " -f1`           # e.g. datadisk1
        mountpoint=`echo ${mapping} | cut -d " " -f2`         # e.g. /mnt/datadisk1
        mapperDatadiskUUID=`echo ${mapping} | cut -d " " -f3` # e.g. 120eb6c0-63e3-4679-bb3a-b2aacd19a815
        partition=`echo ${mapping} | cut -d " " -f4`          # e.g. sdc1
        device="/dev/${partition}"                            # e.g. /dev/sdc1
        luksUUID=`sudo cryptsetup luksUUID ${device}`         # e.g. b01b2887-fa79-4b83-be03-39d9b4b31584

        #----------------------------------------------------------------------
        # Example of crypttabEntry
        # datadisk1  UUID=b01b2887-fa79-4b83-be03-39d9b4b31584 /etc/testkeyfile
        #----------------------------------------------------------------------
        crypttabEntry="${datadisk}  UUID=${luksUUID} ${keyfile}"

        #-------------------------------------------------------------------------------
        # Example of fstabEntry
        # UUID=120eb6c0-63e3-4679-bb3a-b2aacd19a815  /mnt/datadisk1  ext4  defaults  0 2
        #-------------------------------------------------------------------------------
        fstabEntry="UUID=${mapperDatadiskUUID}  ${mountpoint}  ext4  defaults  0 2"
        
        if [ "${test_flag}" == "yes" ]
        then
            echo "datadisk:           '${datadisk}"
            echo "mountpoint:         '${mountpoint}"
            echo "mapperDatadiskUUID: '${mapperDatadiskUUID}"
            echo "partition:          '${partition}"
            echo "device:             '${device}"
            echo "luksUUID:           '${luksUUID}"
            echo "crypttabEntry:      '${crypttabEntry}"
            echo "fstabEntry:         '${fstabEntry}"
            echo "--------------------------------------------------------------------------------"
        fi

        fstabEntries="${fstabEntries}${MOUNTPOINT_SEPARATOR}${fstabEntry}"
        crypttabEntries="${crypttabEntries}${MOUNTPOINT_SEPARATOR}${crypttabEntry}"
    done

    if [ "${crypttabEntries}" != "" ]
    then
        origPermisions=`sudo stat -c "%a" ${CRYPTTAB_FILE}`
        sudo chmod 666 ${CRYPTTAB_FILE}

        for crypttabEntry in ${crypttabEntries:1}
        do
            luksUUID=`echo ${crypttabEntry} | awk '{print $2}'`

            if [[ ! `sudo grep "${luksUUID}" ${CRYPTTAB_FILE}` ]]
            then
                #------------------------------------------
                # This UUID does not exist in /etc/crypttab
                #------------------------------------------
                if [ "${test_flag}" == "yes" ]
                then
                    echo "sudo echo \"${crypttabEntry}\" >> ${CRYPTTAB_FILE}"
                else
                    sudo echo "${crypttabEntry}" >> ${CRYPTTAB_FILE}
                fi
            else
                echo "${CRYPTTAB_FILE} already has entry: '${crypttabEntry}'"
            fi

            [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
        done

        sudo chmod ${origPermisions} ${CRYPTTAB_FILE}
    fi

    if [ "${fstabEntries}" != "" ]
    then
        origPermisions=`sudo stat -c "%a" ${FSTAB_FILE}`
        sudo chmod 666 ${FSTAB_FILE}

        for fstabEntry in ${fstabEntries:1}
        do
            mapperDatadiskUUID=`echo "${fstabEntry}" | awk '{print $1}'`

            if [[ ! `sudo grep "${mapperDatadiskUUID}" ${FSTAB_FILE}` ]]
            then
                #---------------------------------------
                # This UUID does not exist in /etc/fstab
                #---------------------------------------
                if [ "${test_flag}" == "yes" ]
                then
                    echo "sudo echo \"${fstabEntry}\" >> ${FSTAB_FILE}"
                else
                    sudo echo "${fstabEntry}" >> ${FSTAB_FILE}
                fi
            else
                echo "${FSTAB_FILE} already has entry: '${fstabEntry}'"
            fi

            [ "${test_flag}" == "yes" ] && echo "--------------------------------------------------------------------------------"
        done

        sudo chmod ${origPermisions} ${FSTAB_FILE}
    fi

    IFS=${OLD_IFS}
}
################
##### MAIN #####
################

#===================
# DO NOT CHANGE This
#===================
PRIMARY_PARTITION=1

CRYPTTAB_FILE=/etc/crypttab
FSTAB_FILE=/etc/fstab

HOST_SEPARATOR="|"
MOUNTS_SEPARATOR=";"
MOUNTPOINT_SEPARATOR=":"


callingArguments=$*

neededMountpoints=""
keyfile=""

errors=0

spaces=`printf ' %.0s' {1..23}`
debug="no"
test_flag="no"
nytte=`date +%Y-%m-%d_%H%M%S`
debugFile=`echo $0 | sed -e 's/\.sh//'`"_"${nytte}.debug.log
logFile=`echo $0 | sed -e 's/\.sh//'`"_"${nytte}.log

while getopts ":m:k:dt" opt
do
    case $opt in
        d) debug="yes"
           ;;
        k) keyfile=${OPTARG}
           ;;
        m) neededMountpoints=${OPTARG}
           ;;
        t) test_flag="yes"
           ;;
    esac
done

if [ "${test_flag}" == "yes" ]
then
    echo "Called as $0 $*"
fi

if [ "${neededMountpoints}" == "" ]
then
    echo "ERROR: No mountpoint data given."
    ((errors+=1))
fi

if [ "${keyfile}" == "" ]
then
    echo "ERROR: Keyfile not given."
    ((errors+=1))
fi

if [[ ${errors} > 0 ]]
then
    usage
    exit 1
fi

if [ "${test_flag}" == "yes" ]
then
    echo "--------------------------------------------------------------------------------"
    echo "neededMountpoints: ${neededMountpoints}"
    echo "keyfile:           ${keyfile}"
    echo "--------------------------------------------------------------------------------"
fi

if [[ $(sudo lsblk | grep crypt) ]] ; then 
    echo "Datadisk already crypted. Exiting...."
    exit 0
fi

findExistingSdDevices
findFreeSdDevices
findSdDevicesToEncryptAndTheirMountpoints
createKeyfile
createPartitions
createFilesystemForSdDevicesToEncrypt
encryptDevices
openEncryptedDevices
creteFilesystemForLuksDevices
createMountpoints
mapNeededMountpointsToLuksMountpoints
updateCrypttabAndFstab
exit 0
