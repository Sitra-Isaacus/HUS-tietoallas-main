#!/bin/bash

#--------------------------------------------------------------------------------
# usage
#--------------------------------------------------------------------------------
function usage() {
    cat <<EOF
========================================================================================
This script requires

1. azure-cli to be present: curl -L https://aka.ms/InstallAzureCli | bash
   https://docs.microsoft.com/en-us/cli/azure/install-azure-cli
========================================================================================
Usage: ${SCRIPTNAME} -c <config_file> -u <user_name>  [-l <logdir>] [-h]
where
    <config_file>       Name with full path of the configuration file
    <user_name>         Name of the integration to create
    <logdir>            Directory where logfile is to be stored.
                        Default value: <config_file_dir>/logs
========================================================================================
EOF
}

#--------------------------------------------------------------------------------
# checkParams
#--------------------------------------------------------------------------------
function checkParams() {
    errors=0

    if [ -z ${DL_CONFIG_FILE} ]
    then
        echo "ERROR: Configuration file is mandatory"
        ((errors+=1))
    else
        if [ ! -f ${DL_CONFIG_FILE} ]
        then
            echo "ERROR: Configuration file does not exist: '${DL_CONFIG_FILE}'"
            ((errors+=1))
        fi
    fi

    if [ -z ${SP_NAME} ]
    then
        echo "ERROR: Integration name is mandatory"
        ((errors+=1))
    fi

    if [ ! $(azure 2>/dev/null) ]
    then
        echo "ERROR: azure-cli is missing"
        ((errors+=1))
    fi

    if [[ ${errors} -gt 0 ]]
    then
        usage
        exit 1
    fi
}

#--------------------------------------------------------------------------------
# executeAndLog
#--------------------------------------------------------------------------------
function executeAndLog() {
    cmd=$1
    local logtime="[$(date '+%Y-%m-%d %H:%M:%S')]"
    echo -en "${logtime}\t" >> ${LOGFILE}
    #echo ${cmd}
    eval ${cmd} | tee -a ${LOGFILE}
}

#--------------------------------------------------------------------------------
# parse_yaml
#
# Copied from:
# http://stackoverflow.com/questions/5014632/how-can-i-parse-a-yaml-file-from-a-linux-shell-script
#--------------------------------------------------------------------------------
function parse_yaml {
   local prefix=$2
   local s='[[:space:]]*' w='[a-zA-Z0-9_]*' fs=$(echo @|tr @ '\034')
   sed -ne "s|^\($s\):|\1|" \
        -e "s|^\($s\)\($w\)$s:$s[\"']\(.*\)[\"']$s\$|\1$fs\2$fs\3|p" \
        -e "s|^\($s\)\($w\)$s:$s\(.*\)$s\$|\1$fs\2$fs\3|p"  $1 |
   awk -F$fs '{
      indent = length($1)/2;
      vname[indent] = $2;
      for (i in vname) {if (i > indent) {delete vname[i]}}
      if (length($3) > 0) {
         vn=""; for (i=0; i<indent; i++) {vn=(vn)(vname[i])("_")}
         printf("%s%s%s=\"%s\"\n", "'$prefix'",vn, $2, $3);
      }
   }'
}

###############
##### MAIN #####
################
EXECUTIONDATE=$(date +%Y-%m-%d_%H%M%S)
SCRIPTNAME=$(basename $(readlink -f $0))
HOME_DIR=$(dirname $(readlink -f $0))
LOGDIR=

DL_CONFIG_FILE=

HELP_WANTED=0

while getopts ":c:u:l:h" opt
do
    case $opt in
        c)  DL_CONFIG_FILE=${OPTARG}
            ;;
        u)  SP_NAME=${OPTARG}
            ;;
        l)  LOGDIR=${OPTARG}
            ;;
        h)  HELP_WANTED=1
            ;;
       \?) echo "ERROR: Non supported parameters"
           usage
           exit 1
           ;;
    esac
done

if [[ ${HELP_WANTED} -gt 0 ]]
then
    usage
    exit 0
fi

checkParams
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

SP_ID_ROW=$(azure ad sp show -c $SP_NAME | grep 'Object Id')
IFS=' :' read -ra fields <<<"$SP_ID_ROW"
SP_ID=${fields[-1]}
executeAndLog "echo \"Service Principal ID: '${SP_ID}'\""

ADLS_NAME=$(echo ${res_group} | tr -d '-')dls
executeAndLog "echo \"ADLS name: '${ADLS_NAME}'\""

executeAndLog "azure datalake store filesystem create -d $ADLS_NAME /clusters/$workspace_name/storage/$SP_NAME"
executeAndLog "azure datalake store permissions entry set -q $ADLS_NAME / user:$SP_ID:--x"
executeAndLog "azure datalake store permissions entry set -q $ADLS_NAME /clusters/ user:$SP_ID:--x"
executeAndLog "azure datalake store permissions entry set -q $ADLS_NAME /clusters/$workspace_name/ user:$SP_ID:--x"
executeAndLog "azure datalake store permissions entry set -q $ADLS_NAME /clusters/$workspace_name/storage/ user:$SP_ID:--x"
executeAndLog "azure datalake store permissions entry set -q $ADLS_NAME /clusters/$workspace_name/storage/$SP_NAME default:user:$SP_ID:rwx,user:$SP_ID:rwx"

executeAndLog "echo \"Execution logged to ${LOGFILE}\""
executeAndLog "echo \"Integration infra set up done.\""