#
# Copyright (C) 2013 eNovance SAS <licensing@enovance.com>
#
# Author: Emilien Macchi <emilien.macchi@enovance.com>
#
# Licensed under the Apache License, Version 2.0 (the "License"); you may
# not use this file except in compliance with the License. You may obtain
# a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
# WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
# License for the specific language governing permissions and limitations
# under the License.
#
# Neutron Metadata node
#

class os_neutron_metadata(
) {

  class { 'neutron::agents::metadata':
    auth_password => $os_params::ks_neutron_password,
    shared_secret => $os_params::neutron_metadata_proxy_shared_secret,
    debug         => false,
    metadata_ip   => $os_params::ks_nova_internal_host,
    auth_url      => "http://${os_params::ks_keystone_admin_host}:${os_params::keystone_admin_port}/v2.0",
  }

}
