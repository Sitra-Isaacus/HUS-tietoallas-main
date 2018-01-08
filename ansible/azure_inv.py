'''
Licensed to the Apache Software Foundation (ASF) under one
or more contributor license agreements.  See the NOTICE file
distributed with this work for additional information
regarding copyright ownership.  The ASF licenses this file
to you under the Apache License, Version 2.0 (the
"License"); you may not use this file except in compliance
with the License.  You may obtain a copy of the License at

  http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing,
software distributed under the License is distributed on an
"AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY
KIND, either express or implied.  See the License for the
specific language governing permissions and limitations
under the License.

Created on 8.2.2016

@author: TuukkaArola
'''
from exceptions import KeyError
from itertools import groupby
import json
import os
import sys
import traceback

import requests
from requests.packages import urllib3

from config import *

def get_access_token():
    token_url = "https://login.windows.net/" + tenant_id + "/oauth2/token"

    # Web app
    postParameters = {
                "client_id": tool_client_id,
                "client_secret": tool_client_secret,
                'grant_type': 'client_credentials',
                'resource': 'https://management.azure.com/'}

    my_headers = {'content-type': 'application/x-www-form-urlencoded'}

    r = requests.post(token_url, postParameters, headers=my_headers)
    return json.loads(r.text)['access_token']

def get_subnet_name(nic, res_group):
    subnet_id = nic['properties']['ipConfigurations'][0]['properties']['subnet']['id']
    name = subnet_id.split('/')[-1]
    n = name.split('-')
    if (len(n) <= 3):
        return "management"
    return n[-2]    

def call_azure(url_str, bearer_token):
    headers = {'Content-Type': 'application/json;charset=utf-8', 'Authorization': "Bearer %s" % bearer_token}
    r = requests.get(url_str, headers=headers)
    return json.loads(r.text)

def list_nics(res_group):
    bearer_token = get_access_token()
    url = 'https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/virtualNetworks?api-version=%s' % (subscription_id, res_group, '2017-06-01')
    
    subnets_json = call_azure(url, bearer_token)

    names = []
    res_groups = set()
    
    # We collect all the name-ip-subnet triplets into a list and convert that list into a map

    try: 
        for vnet in subnets_json['value']:
            for subnet in vnet['properties']['subnets']:
                if 'ipConfigurations' in subnet['properties']:
                    ip_config = subnet['properties']['ipConfigurations'][0]
                    for resId in subnet['properties']['ipConfigurations']:
                        res_group = resId['id'].split('/')[4]
                        res_groups.add(res_group)

        for res_group in res_groups:
            url2 = 'https://management.azure.com/subscriptions/%s/resourceGroups/%s/providers/Microsoft.Network/networkInterfaces?api-version=%s' % (subscription_id, res_group, '2015-06-15')
            j = call_azure(url2, bearer_token)

            for nic in j['value']:
                full_name = nic['name']

                name = None
                vm_name = None
                hadoop_comp = False
                gateway_comp = False
                node_index = "-1"
                if full_name.startswith('nic-'):
                    name = full_name.split('-')[1]
                    node_index = full_name.split('-')[2]
                    vm_name = name
                    if "gateway" in full_name: 
                        gateway_comp = True
                    else:
                        hadoop_comp = True
                elif full_name.endswith('-nic') and not full_name.startswith('aadds-') :
                    name_comps = full_name.split('-')
                    vm_name = full_name[:-4]
                    if name_comps[-2][-1:].isdigit():
                        name = full_name.split('-')[-4]
                        node_index = full_name.split('-')[-2]
                    else:
                        name = full_name.split('-')[-3]
                    
                # Skip invalid entries whose name we cannot parse
                if name == None:
                    continue
                
                subnet_name = get_subnet_name(nic, res_group)
                ip = nic['properties']['ipConfigurations'][0]['properties']['privateIPAddress']
                group = name
                dnsname = name
                if int(node_index) >= 0:
                    dnsname = dnsname + "-" + node_index
                if hadoop_comp or gateway_comp:
                    dnsname = subnet_name + "-" + dnsname
                host_vars = { 'subnet' : subnet_name, 'cluster_node_index' : node_index, 'dns_name' : dnsname }
                names.append((group, ip, host_vars))
                names.append((subnet_name + '-' + group, ip, host_vars))
                if not gateway_comp:
                    names.append((subnet_name, ip, host_vars))
                if group == 'headnode' and node_index == "0":
                    names.append((subnet_name + '-' + group + "-primary", ip, host_vars))
                if not (hadoop_comp or gateway_comp) :
                    names.append(('all-vms', ip, host_vars))
            
        # Create hostvars for all found vms
        data = {'_meta': {'hostvars': {}}}
        for name in names:
            data['_meta']['hostvars'][name[1]] = name[2]
        
        # Group
        names = sorted(names, key = lambda e: e[0])
        for g, elems in groupby(names, lambda e: e[0]):
            data[g] = map(lambda e: e[1], elems) 
        
        print json.dumps(data, indent = 2)
    except KeyError:
        sys.stderr.write('Could not access Resource Group data. Have you added the tool in a Contributor role for the Resource Group?\n')
        traceback.print_exc()
        exit(1)

if __name__ == '__main__':
    urllib3.disable_warnings()
    
    if 'network_res_group' not in os.environ :
        print "azure_inv.py requires two env variables to be set: network_res_group"
        exit(1)

    res_group = os.environ['network_res_group']

    if sys.argv[1] == '--list':
        list_nics(res_group)
    else:
        print "azure_inv.py --list"
        
