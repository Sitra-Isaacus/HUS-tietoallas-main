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

sudo yum install -y git
sudo yum install -y epel-release
sudo yum install -y ntp
sudo yum install -y ntpdate
sudo yum install -y ntp-doc
sudo yum install -y python-pip
sudo yum install -y wget
sudo pip install jinja2-cli
sudo pip install requests
sudo yum install -y jq
sudo yum install -y ansible

