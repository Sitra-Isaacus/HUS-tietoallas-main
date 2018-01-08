# Installation instructions
Provisioning of datalake infrastructure into Microsoft Azure computing platform is based on ARM templates. This is automated with several bash shell scripts which use pseudo templates together with user defined configuration files. To accomplish this a Linux based installation server (laptop/desktop or a virtual machine on it) is needed.

The installation procedure creates
1. needed ARM templates and when needed also ssh security components and certificates
2. the infrastructure into Azure

The infrastructure itself has several resource groups each having own sub network under the virtual network to be used. The ip address range for the virtual network to be used need to be planned carefully.  In most cases if there becomes a need to append this address range the whole infrastructure must be newly created.

Each implemetation has at least three resource groups:
- main for management purposes
- main datalake for permanent data storage
- a side datalake for analyzing purposes, has read only mirror for all or some part of the data stored to main datalake

In addition to this also these resource groups can be used
- integration, if external data sources for main datalake is used and/or any vms clusters are needed
- any number of additional side datalakes

Each resource group needs its own configuration file.

## Preconditions
1. Azure subscription exists.
2. Installation server has networks access to internet
3. Needed software exist in installation server
   - azure-cli version 2
   - jinja2 + jinja2-cli + pyyaml
   - git
   - jq
4. Account with read privileges to the source Git repository.

## Preparations
1. Choose the infrastructure
   First thing is to choose the basic infrastructure content i.e., which resource groups are needed. This can be later appended with extra side datalakes and/or vms clusters. 
   Only limit is the used ip address space.

2. Choose the maximum number of ip addresses the virtual network can have
   This step is needed only if the virtual network does not exist.

   Some examples:

   | sub network | Max number of ips |
   | ----------- | ----------------- |
   | 10.0.0.0/24 | 256               |
   | 10.0.0.0/23 | 512               |
   | 10.0.0.0/22 | 1024              |

3. Define the ip address ranges for each sub networks to be created
   Following table has default values.

   | sub network     | cidr         | Note                                      |
   | --------------- | ------------ | ----------------------------------------- |
   | main            | 10.0.0.16/28 | In most cases 16 addresses are sufficient |
   | integration     | 10.0.0.32/27 | In most cases 32 addresses are sufficient |
   | maindatalake    | 10.0.0.64/27 | In most cases 32 addresses are sufficient |
   | side datalake 1 | 10.0.0.96/27 | In most cases 32 addresses are sufficient |

   Note: The 16 first addresses (10.0.0.0/28) from virtual network should be left for Azure itself. Do not define any subnets for that area.

4. Prepare the installation server
   1. Create <work_root> directory for installation artifacts
      For example: `mkdir -p ${HOME}/repositories`

   2. Go to <work_root> and download the pseudo templates and scripts <work_root> from git
      ```
      cd <work_root>
      git clone <sourcegitrepository>
      ```

      This contains the pseudo templates and installation scripts. 

   3. Create directory structure for configuration files under <work_root> referred as <config_dir>  
      ```
      mkdir -p <work_root>/<DOMAIN>/configs/infra_automation/<ENV>
      ```
      Recommendation: Use the <dl_domain> and <dl_env> defined in config_main.yml for <DOMAIN> and <ENV> respectively.

5. Create the configuration files
   Go to <config_dir> and create the needed configuration files.

   The naming conventions:
   - Each file name should start with config_
   - Three names are static: config_main.yml, config_maindatalake.yml and config_integration.yml.
 
   The <...> in next table can be chosen freely.

   | Configuration file                | Optionality | Note                                                                      | Example                  |
   | --------------------------------- | ----------- | ------------------------------------------------------------------------- | ------------------------ |
   | config_main.yml                   | mandatory   |                                                                           |                          |
   | config_maindatalake.yml           | mandatory   |                                                                           |                          |
   | config_integration.yml            | optional    | Needed if integration resource group or any vms cluster should be created |                          |
   | config_<cluster_name>_cluster.yml | optiona     | Needed if a vms cluster should be create                                  | config_kafka_cluster.yml |
   | config_<datalake_x>.yml           | 1 mandatory | Each side datalake should have its own configuration file                 | config_researcher.yml    |

6. Check that all needed scripts have execution bits set
   Go to <work_root>main/infra_automation
   For any script createDatalake.sh, createIntegration.sh, createMain.sh, createNetwork.sh, createVMCluster.sh, functions.sh that does not have enough execution rights, use chmod 775.

# Provisioning of the infrastructure
After going through the instructions in Preparations go in installation server to <work_root>

1. Login to Azure and take the right subscription into use
   In the installation server

   1. Login to azure
      `az login`

   2. Check that right subscription is activated
      `az account list -o table`
      Write down the subscription id for further use referred as <subscription_id>

   3. if subscription is incorrect take right one to use
      `az account set --subscription <subscriptionNameOrId>`

   4. Find out the tenant id of the subscription and store it for further use
      `az account show -o table`
      Write down the tenant id for futher use referred as <tenant_id>

2. Create the Azure infrastructure
   1. Go to <work_root>/main/infra_automation
      ```
      cd <work_root>/main/infra_automation
      ```

   2. Create virtual network if needed
      If virtual network does not exist it has to be created first. 
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createNetwork.sh -c <config_dir>/config_main.yml
      ```

   3. Create the main resources
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createMain.sh -c <config_dir>/config_main.yml
      ```
      Note: During the main resource creation the might come to screen one or more times
      ```
      Failed: <res_group>-app-db (Microsoft.Sql/servers)
      Failed: <res_group>-db (Microsoft.Sql/servers)
      ```
      where the res_group is from config_main.yml. These can be ignored. The cause of these are that the db creation is still ongoing when the check is done. 

   4. Create the integration resources (Optional)
      If integration services or any vm clusters are needed integration services need to be created.
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createIntegration.sh -c <config_dir>/config_integration.yml
      ```

   5. Create the vm clusters (Optional)
      This step is needed only if there are at least one vm clusters that need to be created. Execute this step as many times as needed.
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createVMCluster.sh -c <config_dir>/config_<cluster_name>_cluster.yml
      ```

   6. Create the main data lake
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createDatalake.sh -c <config_dir>/config_maindatalake.yml
      ```

   7. Create the side data lake(s)
      This step is needed only if there are at least one side data lake that need to be created. Execute this step as many times as needed.
      In the installation server give the command and confirm that no errors are shown
      ```
      ./createDatalake.sh -c <config_dir>/config_<datalake_x>.yml
      ```

3. Create public ip for the newly created azure infrastructure (*Only for public network installs*)

   Using your browser

   1. Login to Azure portal
   2. Select Public IP Address -> Add
      Fill in the fields

      | Name                    | <resgroup>-manager-vm-publicip          |
      | IP Version              | IPv4                                    |
      | IP address assignment   | Dynamic                                 |
      | DNS name label          |                                         |
      | Create an IPv6 address  | Not checked                             |
      | Subscription            | From drop-down list select the used one |
      | Resource group          | As described in config_main.yml         |
      | Location                | As described in config_main.yml         |

      and click create. The res_group is from config_main.yml.

4. Associate the public ip to manager vm (*Only for public network installs*)

   Using your browser 

   1. Login to Azure portal
   2. Select Public IP Address -> Choose the <res_group>-manager-vm-publicip -> Associate
      The res_group is from config_main.yml. For the Resource type select Network Interface and choose from the right list <res_group>-manager-vm-nic and click OK
      Wait when operation is complete (takes a few minute) refresh the browser window and write down the public ip address.

5. Create tool client
   Using your browser 

   1. Login to Azure portal
   2. Select Azure Active Directory -> App registrations -> New application registration and set values as
      | Name            | <dl_domain>dl-ansible |
      | Application typ | Web app / API         |
      | Sign-on URL     | http://localhost      |
   3. Wait when operation is complete (takes a few minute) select the newly created application
   4. Write down the Application ID referred as <tool_client_id> and and select Keys
   5. Write descriptive name to DESCRIPTION
   6. Select expiration for application to be In 2-years and clik Save. 
   7. Now there should come a value for field VALUE. Write down this value referred as <tool_client_secret>. it will be used later when creating the config.py

6. Assign the tool client to subscription
   Using your browser 
   1. Login to Azure portal
   2. Select Subscriptions -> <subscription> -> Access control (IAM) -> Add
      | Role             | Contributor                          |
      | Assign access to | Azure AD user, group, or application |
      | Selec            | <dl_domain>dl-ansible                |

7. Update main nsg for your installation server address space (*Only for public network installs*)

   This step is needed for you to be able to creating ssh connection to manager vm via public ip
   Using your browser 

   1. Login to Azure portal
      Select All resources -> Click main network security  <res_group>-nsg -> Inbound security rules -> Add
      | Source                          | IP Addresses                                                                      |
      | Source IP addresses/CIDR ranges | IP of your installation server or a CIDR where your installation server ip lives. |
      | Source port range               | *                                                                                 |
      | Destination                     | Any                                                                               |
      | Destination port range          | *                                                                                 |
      | Protocol                        | TCP                                                                               |
      | Action                          | Allow                                                                             |
      | Priority                        | Next available priority < 1000                                                    |
      | Name                            | <res_group>-management                                                            |

     where the res_group is from config_main.yml

     Click OK

8. Create config.py
   To complete the infrastructure a file caled config.py is needed. It shoudl be created to same directory where the condifugration files are (<config_dir>

   ```
   cd <config_dir>
   vim config.py
   ```
   and add following content using the values determined above

   ```
   subscription_id = '<subscription_id>'
   tool_client_id = '<toold_client_id>'
   tool_client_secret = '<toold_client_secret>'
   tenant_id = '<tenant_id>'
   ```

9. Create installation package for manager node
   To be able to perform the next step the artifacts under <work_root> need to be copied to manager node in Azure infra.

   1. Create a tar package of the needed artifacts
      ```
      cd <work_root>/main
      ./package_common.sh <DOMAIN> <ENV>
      ```

   2. Transfer the tar package to manager node
      For example use scp as
      ```
      cd <work_root>/main
      scp -i <config_dir>/ssh_keys/id_rsa common-<DOMAIN>-<ENV>.tar.gz <admin_name>@<public_ip>:/home/<admin_name>
      ```
      where <admin_name> is from config_main.yml

10. Complete the infrastructure installation
    For these steps you need an ssh client like PuTTy. Also you need the private ssh key file from <config_dir>/ssh_keys directory.

    1. Take a ssh connection to manager node using the public IP created above
       
       | Private key file for authentication | <config_dir>/ssh_keys/id_rsa |
       | User name                           | <admin_name>                 |

    2. Create the /opt/DataLake directory
       ```
       sudo mkdir -p /opt/DataLake
       sudo chown -R <admin_name>:<admin_name> /opt/Datalake
       ```
    3. Unpack the installation package
       ```
       cd /opt/DataLake/
       tar xf $HOME/common-<DOMAIN>-<ENV>.tar.gz
       ```
    4. Install needed tools
       ```
       cd /opt/DataLake/common
       bash ./prepareManager.sh
       ```
    5. Update management vms
       ```
       cd /opt/DataLake/common
       bash ./runplaybook.sh -c config/config_main.yml -p prepare_vms.yml
       ```

# Configuration files explained

## Main configuration file
Name: **_config_main.yml_**
With the information in this yaml formatted file the infrastructure is created into Microsoft Azure. 

| Variable                |                                        |                             | Example value | Note                                                      |
| ----------------------- | -------------------------------------- | --------------------------- | ------------- | --------------------------------------------------------- |
| dl_domain               | Abbreviation of Data Lake domain name  |                             | mydom         |                                                           |
| dl_env                  | Abbreviation for environment           |                             | myenv         |                                                           |
| domain_name             | nodomain                               |                             |               | This should always be 'nodomain'                          |
| location                | Location of the subscription           | Default: northeurope        | northeurope   |                                                           |
| res_group               | Name of the main resource group        | <dl_domain>dl-<env_abbr>    | mydomdl-me    | Max length 24 characters                                  |
| ansible_group           | Name of the group in dynamic inventory | management                  | management    | This should always be 'management'                        |
| workspace_name          | Name of the main work space            | main                        | main          | This should always be 'main'                              |
| network_res_group       | Name of the network resource group     | <dl_domain>dl-<env_abbr>-nw | mydomdl-me-nw |                                                           |
| vnet_name               | Name of the virtual network            | <dl_domain>-<env_abbr>-nw   | mydom-me-nw   |                                                           |
| vnet_cidr               | Virtual network address space          | Default: 10.0.0.0/24        | 10.0.0.0/24   |                                                           |
| management_subnet_cidr  | Management subnet cidr                 | Default: 10.0.0.16/28       | 10.0.0.16/28  | Same as subnet_cidr in this configuration file            |
| integration_subnet_cidr | Integration subnet cid                 | Default: 10.0.0.32/27       | 10.0.0.32/27  |                                                           |
| subnet_cidr             | Management subnet cidr                 | Default: 10.0.0.16/28       | 10.0.0.16/28  | Same as management_subnet_cidr in this configuration file |
| db_admin                | Management db admin name               | Default: dbadmin            | dbadmin       |                                                           |
| db_admin_pwd            | Management db admin password           |                             | <password>    | </dev/urandom tr -dc 'A-Za-z0-9' | head -c 14  ; echo     |
| admin_name              | Management admin nam                   | <dl_domain><env_abbr>       | mydomme       |                                                           |


## Integration configuration file
Name: **_config_integration.yml_**
With the information in this yaml formatted file the integration resources are created into Microsoft Azure. 

| Variable                |                                                 |                                        | Example value  | Note                                                           |
| ----------------------- | ----------------------------------------------- | -------------------------------------- | -------------- | -------------------------------------------------------------- |
| dl_domai                | Abbreviation of Data Lake domain name           |                                        | mydom          | Must be same as the dl_domain in config_main.yml               |
| dl_env                  | Abbreviation for environment                    |                                        | myenv          | Must be same as the dl_env in config_main.yml                  |
| domain_name             | nodomain                                        |                                        |                | This should always be 'nodomain'                               |
| location                | Location of the subscription                    | Default: northeurope                   | northeurope    | Must be same as the location in config_main.yml                |
| res_group               | Name of the integration resource group          | <dl_domain>dl-<env_abbr>-int[egration] | mydomdl-me-int | Max length 24 characters                                       |
| ansible_group           | Name of the group in dynamic inventory          | integration                            | integration    | This should always be 'integration'                            |
| workspace_name          | Name of the main work space                     | integration                            | integration    | This should always be 'integration'                            |
| main_res_group          | Name of the main resource group                 | <dl_domain>dl-<env_abbr>               | mydomdl_m      | Must be same as the res_group in config_main.yml               |
| network_res_group       | Name of the network resource group              | <dl_domain>dl-<env_abbr>-nw            | mydomdl-me-nw  | Must be same as the network_res_group in config_main.yml       |
| vnet_name               | Name of the virtual network                     | <dl_domain>-<env_abbr >-nw             | mydom-me-nw    | Must be same as the vnet_name in config_main.yml               |
| vnet_cidr               | Virtual network address space                   | Default: 10.0.0.0/24                   | 10.0.0.0/24    | Must be same as the vnet_cidr in config_main.yml               |
| management_subnet_cidr  | Management subnet cidr                          | Default: 10.0.0.16/28                  | 10.0.0.16/28   | Must be same as the subnet_cidr in config_main.yml             |
| integration_subnet_cidr | Integration subnet cidr                         | Default: 10.0.0.32/27                  | 10.0.0.32/27   | Must be same as the integration_subnet_cidr in config_main.yml |
| subnet_cidr             | Integration subnet cidr                         | Default: 10.0.0.32/28                  | 10.0.0.32/28   | Must be same as the integration_subnet_cidr in config_main.yml |
| db_admin                | Management db admin name                        | Default: dbadmin                       | dbadmin        | Must be same as the db_admin in config_main.yml                |
| db_admin_pwd            | Management db admin password                    | <password>                             |                | Must be same as the db_admin_pwd in config_main.yml            |
| hdinsight_admin_pwd     | Main data lake hdinsight cluster admin password | <password>                             |                | Must be same as hdinsight_admin_pwd in config_maindatalake.yml |
| admin_name              | Management admin name                           | <dl_domain><env_abbr                   | mydomme        | Must be same as the admin_name in config_main.yml              |

## VM Cluster configuration file
Name: **_config_<cluster_name>_cluster.yml_**
With the information in this yaml formatted file the integration resources are created into Microsoft Azure.
Example name: config_kafka_cluster.yml

| Variable                |                                                    |                                        | Example value   | Note                                                           |
| ----------------------- | -------------------------------------------------- | -------------------------------------- | --------------- | -------------------------------------------------------------- |
| dl_domain               | Abbreviation of Data Lake domain nam               |                                        | mydom           | Must be same as the dl_domain in config_main.yml               |
| dl_env                  | Abbreviation for environment                       |                                        | myenv           | Must be same as the de_env in config_main.yml                  |
| domain_name             | nodomain                                           |                                                          | This should always be 'nodomain'                               |
| location                | Location of the subscription                       | Default: northeurope                   | northeurop      | Must be same as the location in config_main.yml                |
| res_group               | Name of the integration resource group             | <dl_domain>dl-<env_abbr>-int[egration] | mydomdl-me-int  | Must be same as the res_group in config_intergation.yml        |
| ansible_group           | Name of the group in dynamic inventory             | <cluster_workspace_name>               | kafka           | Must be same as the workspace_name in this configuration file  |
| workspace_name          | Name of the main work space                        | <cluster_workspace_name>               | kafka           | Must be same as the ansible_group in this configuration file   |
| main_res_group          | Name of the main resource group                    | <dl_domain>dl-<env_abbr>               | mydomdl_me      | Must be same as the res_group in config_main.yml               |
| network_res_group       | Name of the network resource group                 | <dl_domain>dl-<env_abbr>-nw            | mydomdl-me-nw   | Must be same as the network_res_group in config_main.yml       |
| vnet_name               | Name of the virtual network                        | <dl_domain>-<env_abbr >-nw             | mydom-me-nw     | Must be same as the vnet_name in config_main.yml               |
| vnet_cidr               | Virtual network address space                      | Default: 10.0.0.0/24                   | 10.0.0.0/24     | Must be same as the vnet_cidr in config_main.yml               |
| management_subnet_cidr  | Management subnet cidr                             | Default: 10.0.0.16/28                  | 10.0.0.16/28    | Must be same as the subnet_cidr in config_main.yml             |
| integration_subnet_cidr | Integration subnet cidr                            | Default: 10.0.0.32/27                  | 10.0.0.32/27    | Must be same as the integration_subnet_cidr in config_main.yml |
| subnet_cidr             | Integration subnet cidr                            | Default: 10.0.0.32/28                  | 10.0.0.32/28    | Must be same as the subnet_cidr in config_integration.yml      |
| admin_name              | Management admin name                              | <dl_domain><env_abbr>                  | mydomme         | Must be same as the admin_name in config_main.yml              |
| cluster_name            | Name of the cluster                                |                                        | kafka           |                                                                |
| vm_size                 | Vm size to be used                                 | Default: Standard_D3_v2                | Standard_D3_v2  |                                                                |
| cluster_size            | Number of vms in cluster                           | Default: 3                             | 3               |                                                                |
| data_disk_size_gb       | Data disk size in gigabytes for each vm in cluster | Default: 5                             | 5               |                                                                |

## Main data lake configuration file
Name: **_config_maindatalake.yml_**
With the information in this yaml formatted file the main data lake resources are created into Microsoft Azure.
 
| Variable                   |                                                             |                                            | Example value           | Note                                                              |
| -------------------------- | ----------------------------------------------------------- | ------------------------------------------ | ----------------------- | ----------------------------------------------------------------- |
| dl_domain                  | Abbreviation of Data Lake domain name                       |                                            | mydom                   | Must be same as the dl_domain in config_main.yml                  |
| dl_env                     | Abbreviation for environment                                |                                            | myenv                   | Must be same as the dl_env in config_main.yml                     |
| domain_prefix              | Domain prefix to be used                                    | main                                       |                         | Must always be main                                               |
| domain_name                | nodomain                                                    |                                            |                         | This should always be 'nodomain'                                  |
| location                   | Location of the subscription                                | Default: northeurope                       | northeurope             | Must be same as the location in config_main.yml                   |
| res_group                  | Name of the maindatalake resource group                     | <dl_domain>dl-<env_abbr>-<domain_prefix>dl | mydomdl-me-maindl       |                                                                   |
| ansible_group              | Name of the group in dynamic inventory                      | <domain_prefix>dl                          | maindl                  |                                                                   |
| workspace_name             | Name of the main datalake work space                        | <domain_prefix>datalake                    | maindatalake            |                                                                   |
| network_res_group          | Name of the network resource group                          | <dl_domain>dl-<env_abbr>-nw                | mydomdl-me-nw           | Must be same as the network_res_group in config_main.yml          |
| main_res_group             | Name of the main resource group                             | <dl_domain>dl-<env_abbr>                   | mydomdl_me              | Must be same as the res_group in config_main.yml                  |
| adls_sp_name               | Data lake service provider name                             | <dl_domain>dl_<workspace_name>             | mydomaindl_maindatalake |                                                                   |
| adls_sp_pwd                | Password for data lake service provider                     | <password>                                 |                         | </dev/urandom tr -dc 'A-Za-z0-9' | head -c 14  ; echo             |
| vnet_name                  | Name of the virtual network                                 | <dl_domain>-<env_abbr >-n                  | mydom-me-nw             | Must be same as the vnet_name in config_main.yml                  |
| vnet_cidr                  | Virtual network address space                               | Default: 10.0.0.0/24                       | 10.0.0.0/24             | Must be same as the vnet_cidr in config_main.yml                  |
| management_subnet_cidr     | Management subnet cidr                                      | Default: 10.0.0.16/28                      | 10.0.0.16/28            | Must be same as the management_subnet_cidr in config_main.yml     |
| integration_subnet_cidr    | Integration subnet cidr                                     | Default: 10.0.0.32/27                      | 10.0.0.32/27            | Must be same as the integration_subnet_cidr in config_main.yml    |
| subnet_cidr                | Main data lake subnet cidr                                  | Default: 10.0.0.64/27                      | 10.0.0.64/27            | Must be unique under vnet_cidr                                    |
| db_admin                   | Management db admin name                                    | Default: dbadmin                           | dbadmin                 | Must be same as the db_admin in config_main.yml                   |
| db_admin_pwd               | Management db admin password                                | <password>                                 |                         | Must be same as the db_admin_pwd in config_main.yml               |
| admin_name                 | Management admin name                                       | <dl_domain><env_abbr>                      | mydomme                 | Must be same as the admin_name in config_main.yml                 |
| hdinsight_headnode_size    |                                                             | Default: Standard_D12_v2                   |                         |                                                                   |
| hdinsight_workernode_size  |                                                             | Default: Standard_D12_v2                   |                         |                                                                   |
| hdinsight_workernode_count |                                                             | Default: 8                                 |                         |                                                                   |
| hdinsight_admin_pwd        | Administrator password for main data lake hdinsight cluster | <password>                                 |                         | </dev/urandom tr -dc 'A-Za-z0-9!"#$%&+-<>@_' | head -c 14  ; echo |
| hdinsight_type             | Type of the main hdinsight                                  | Possible values: spark, rserver            | spark                   |                                                                   |

## Side data lake configuration file
Name: **_config_<datalake_x>.yml_**
With the information in this yaml formatted file the main data lake resources are created into Microsoft Azure.
Example: config_sidedatalake.yml

| Variable                   |                                                             |                                            | Example value           | Note                                                              |
| -------------------------- | ----------------------------------------------------------- | ------------------------------------------ | ----------------------- | ----------------------------------------------------------------- |
| dl_domain                  | Abbreviation of Data Lake domain name                       |                                            |mydom                    | Must be same as the dl_domain in config_main.yml                  |
| dl_env                     | Abbreviation for environment                                |                                            |myenv                    | Must be same as the dl_env in config_main.yml                     |
| domain_prefix              | Domain prefix to be used                                    | <domain_prefix>                            |side                     |                                                                   |
| domain_name                | nodomain                                                    |                                            |                         | This should always be 'nodomain'                                  |
| location                   | Location of the subscription                                | Default: northeurope                       |northeurope              | Must be same as the location in config_main.yml                   |
| res_group                  | Name of the side data lake resource group                   | <dl_domain>dl-<env_abbr>-<domain_prefix>dl |mydomdl-me-sidedl        |                                                                   |
| ansible_group              | Name of the group in dynamic inventory                      | <domain_prefix>dl                          |sidedl                   |                                                                   |
| workspace_name             | Name of the side data lake workspace                        | <domain_prefix>datalake                    |sidedatalake             |                                                                   |
| network_res_group          | Name of the network resource group                          | <dl_domain>dl-<env_abbr>-nw                |mydomdl-me-nw            | Must be same as the network_res_group in config_main.yml          |
| main_res_group             | Name of the main resource group                             | <dl_domain>dl-<env_abbr>                   |mydomdl_me               | Must be same as the res_group in config_main.yml                  |
| adls_sp_name               | Data lake service provider name                             | <dl_domain>dl_<workspace_name>             |mydomaindl_sidedatalake  |                                                                   |
| adls_sp_pwd                | Password for data lake service provider                     |                                            |<password>               | </dev/urandom tr -dc 'A-Za-z0-9' | head -c 14  ; echo             |
| vnet_name                  | Name of the virtual network                                 | <dl_domain>-<env_abbr >-nw                 | mydom-me-nw             | Must be same as the vnet_name in config_main.yml                  |
| vnet_cidr                  | Virtual network address space                               | Default: 10.0.0.0/24                       |10.0.0.0/24              | Must be same as the vnet_cidr in config_main.yml                  |
| management_subnet_cidr     | Management subnet cidr                                      | Default: 10.0.0.16/28                      |10.0.0.16/28             | Must be same as the management_subnet_cidr in config_main.yml     |
| integration_subnet_cidr    | Integration subnet cidr                                     | Default: 10.0.0.32/27                      |10.0.0.32/27             | Must be same as the integration_subnet_cidr in config_main.yml    |
| subnet_cidr                | Datalake subnet cidr                                        | Default: 10.0.0.96/27                      |10.0.0.96/27             | Must be unique under vnet_cidr                                    |
| db_admin                   | Management db admin name                                    | Default: dbadmin                           |dbadmin                  | Must be same as the db_admin in config_main.yml                   |
| db_admin_pwd               | Management db admin password                                |                                            |<password>               | Must be same as the db_admin_pwd in config_main.yml               |
| admin_name                 | Side data lake admin name                                   | <dl_domain><env_abbr>                      |mydomme                  |                                                                   |
| hdinsight_headnode_size    |                                                             | Default: Standard_D12_v2                   |                         |                                                                   |
| hdinsight_workernode_size  |                                                             | Default: Standard_D3_v2                    |                         |                                                                   |
| hdinsight_workernode_count |                                                             | Default: 3                                 |                         |                                                                   |
| hdinsight_admin_pwd        | Administrator password for main data lake hdinsight cluster |                                            |<password>               | </dev/urandom tr -dc 'A-Za-z0-9!"#$%&+-<>@_' | head -c 14  ; echo |
| hdinsight_type             | Type of the main hdinsight                                  | Possible values: rserver, spark            |spark                    |                                                                   |
