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

if [ "$#" -ne 2 ]; then
    echo "Usage:"
    echo "    $0 domain env"
    echo "Where:"
    echo "    domain - the installation domain (e.g. the subscription name)"
    echo "    env    - the installation env name (dev/test/prod/...)"
    exit 1
fi

DOMAIN=$1
ENV=$2

PACK_DIR=/tmp/common

mkdir -p $PACK_DIR/config
cp -r ansible/* $PACK_DIR
cp ../${DOMAIN}/configs/infra_automation/${ENV}/config* $PACK_DIR/config
cp -r ../${DOMAIN}/configs/infra_automation/${ENV}/ssh_keys $PACK_DIR/config
cp -r infra_automation/functions.sh $PACK_DIR

tar -czf common-${DOMAIN}-${ENV}.tar.gz -C /tmp common

rm -r $PACK_DIR