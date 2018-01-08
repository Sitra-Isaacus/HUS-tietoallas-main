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

function usage {
    cat <<EOF
========================================================================================
Usage: ${SCRIPTNAME} -c <config_file> -p <playbook> [-l <logdir>] [-h]
where
    <config_file>  Name with full path of the configuration file
    <playbook>     Name of the Ansible Playbook to run 
    <logdir>       Directory where logfile is to be stored.
                   Default value: <config_file_dir>/logs
========================================================================================
EOF
}


################
##### MAIN #####
################
EXECUTIONDATE=$(date +%Y-%m-%d_%H%M%S)
SCRIPTNAME=$(basename $(readlink -f $0))
HOME_DIR=$(dirname $(readlink -f $0))
LOGDIR=
DL_CONFIG_FILE=

# Include functions
. ${HOME_DIR}/functions.sh

HELP_WANTED=0

while getopts ":c:p:l:h" opt
do
    case $opt in
        c)  DL_CONFIG_FILE=${OPTARG}
            ;;
        p)  PLAYBOOK=${OPTARG}
            ;;
        l)  LOGDIR=${OPTARG}
            ;;
        h)  HELP_WANTED=1
            ;;
       \?)  echo "ERROR: Non supported parameters"
            only_config_file_usage
            exit 1
            ;;
    esac
done

if [[ ${HELP_WANTED} -gt 0 ]]; then
    usage
    exit 0
fi
if [ -z ${DL_CONFIG_FILE} ] || [ -z ${PLAYBOOK} ]; then
   usage
   exit 1
fi

DL_CONFIG_FILE=$(readlink -f ${DL_CONFIG_FILE})

eval $(parse_yaml ${DL_CONFIG_FILE})

CONFIG_DIR=$(dirname ${DL_CONFIG_FILE})
CONFIG_FILE=$(basename ${DL_CONFIG_FILE})

#-------------------------------------------
# If LOGDIR is not given use the default one
#-------------------------------------------
if [ -z ${LOGDIR} ]
then
    LOGDIR=${CONFIG_DIR}/logs
else
    LOGDIR=$(readlink -f ${LOGDIR})
fi

LOGFILE=${LOGDIR}/${SCRIPTNAME}_${EXECUTIONDATE}.log

echo "Logging goes to ${LOGFILE}"

#-----------------------------------
# If LOGDIR does not exist create it
#-----------------------------------
if [ ! -d ${LOGDIR} ]
then
    errtxt=$(mkdir -p ${LOGDIR} 2>&1)

    if [[ $? -gt 0 ]]
    then
        echo "ERROR: ${SCRIPTNAME}: ${errtxt}"
        exit 1
    fi
fi

executeAndLog "echo \"Script home directory: '${HOME_DIR}'\""
executeAndLog "echo \"Configuration directory for domain '${dl_domain}' and env '${dl_env}': '${CONFIG_DIR}'\""

export PYTHONPATH=$CONFIG_DIR
export network_res_group=$network_res_group
ansible-playbook -i ${HOME_DIR}/azure_inv.sh --private-key ${CONFIG_DIR}/ssh_keys/id_rsa --extra-vars "@${DL_CONFIG_FILE}" $PLAYBOOK -u $admin_name
