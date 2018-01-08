#!/bin/bash

# Include functions
. functions.sh

################
##### MAIN #####
################
EXECUTIONDATE=$(date +%Y-%m-%d_%H%M%S)
SCRIPTNAME=$(basename $(readlink -f $0))
HOME_DIR=$(dirname $(readlink -f $0))
LOGDIR=

DL_CONFIG_FILE=
# Compatibility for undefined dl_type
dl_type="spark"
HELP_WANTED=0

while getopts ":c:l:h" opt
do
    case $opt in
        c)  DL_CONFIG_FILE=${OPTARG}
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

if [[ ${HELP_WANTED} -gt 0 ]]
then
    only_config_file_usage
    exit 0
fi

only_config_file_checkParams
DL_CONFIG_FILE=$(readlink -f ${DL_CONFIG_FILE})

eval $(parse_yaml ${DL_CONFIG_FILE})

cd $HOME_DIR

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

cd $CONFIG_DIR

executeAndLog "echo \"Configuration directory for domain '${dl_domain}' and env '${dl_env}': '${CONFIG_DIR}'\""

executeAndLog "echo \"Generating SSH keys...\""

mkdir -p ssh_keys

if [ ! -f ssh_keys/id_rsa ]; then
    ssh-keygen -t rsa -q -N '' -C $admin_name -f ssh_keys/id_rsa | tee -a ${LOGFILE}
else
    executeAndLog "echo \"SSH key already exists, skipping creation.\""
fi

ADMIN_SSH_KEY=$(cat ssh_keys/id_rsa.pub)

executeAndLog "echo \"Creating management certificates...\""

mkdir -p certificates/$workspace_name
cd certificates/$workspace_name

if [ ! -f cert.pem ]; then
    openssl req -x509 -days 3650 -newkey rsa:2048 -out cert.pem -nodes -subj '/CN=$res_group'
    openssl pkcs12 -export -out $adls_sp_name.pfx -inkey privkey.pem -in cert.pem -password pass:$adls_sp_pwd
    base64 $adls_sp_name.pfx > $adls_sp_name.pfx.base64
    tr -d '\n' < $adls_sp_name.pfx.base64 > $adls_sp_name.pfx.base64.noln
fi

SP_CERTIFICATE=$(cat $adls_sp_name.pfx.base64.noln)

CERT=$(head -n-1 cert.pem | tail -n+2)

executeAndLog "echo \"Creating Azure Application and Service Principals...\""
executeAndLog "az ad sp create-for-rbac -n $adls_sp_name --cert \"$CERT\""

executeAndLog "echo \"Execution logged to ${LOGFILE}\""
executeAndLog "echo \"Data Lake set up done.\""