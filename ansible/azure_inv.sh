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


#-------------------------------------------------------------
# Requires exported env variable PYTHONPATH which has to point
# to directory where config.py is located
# E.g. <repository_root>/configs/infra_automation/dev/
#
# NOTE: Ansible calls this script with --list as firs parameter
#       If called from cli the path having config.py must be
#       given as first parameter
#--------------------------------------------------------------
configFilePath=$1

if [ ! -d ${configFilePath} ]
then
    if [ -z ${PYTHONPATH} ]
    then
        echo "ERROR: Incorrect PYTHONPATH ('${PYTHONPATH}'). Exiting..."
        exit 1
    fi
else
    export PYTHONPATH=${configFilePath}
fi

SCRIPTDIR=$(dirname $(readlink -f $0))
python ${SCRIPTDIR}/azure_inv.py --list
