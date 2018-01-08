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

executeAndLog "echo \"Setting up resource group...\""
executeAndLog "az group create -n $network_res_group -l $location"

executeAndLog "echo \"Creating network...\""
executeAndLog "az network vnet create -n $vnet_name --address-prefix $vnet_cidr -g $network_res_group -l $location"

executeAndLog "echo \"Execution logged to ${LOGFILE}\""
executeAndLog "echo \"Data Lake Network set up done.\""