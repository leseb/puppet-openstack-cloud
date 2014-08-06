#
# Copyright (C) 2014 eNovance SAS <licensing@enovance.com>
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
# Unit tests for cloud::network::lbaas class
#
require 'spec_helper'

describe 'cloud::network::lbaas' do

  shared_examples_for 'openstack network lbaas' do

    let :pre_condition do
      "class { 'cloud::network':
        rabbit_hosts             => ['10.0.0.1'],
        rabbit_password          => 'secrete',
        tunnel_eth               => '10.0.1.1',
        api_eth                  => '10.0.0.1',
        provider_vlan_ranges     => ['physnet1:1000:2999'],
        provider_bridge_mappings => ['public:br-pub'],
        flat_networks            => ['public'],
        external_int             => 'eth1',
        external_bridge          => 'br-pub',
        manage_ext_network       => false,
        verbose                  => true,
        debug                    => true,
        use_syslog               => true,
        dhcp_lease_duration      => '10',
        tunnel_types             => ['vxlan'],
        tenant_network_types     => ['vxlan'],
        type_drivers             => ['gre', 'vlan', 'flat', 'vxlan'],
        log_facility             => 'LOG_LOCAL0' }"
    end

    let :params do
      { :debug              => true,
        :manage_haproxy_pkg => true }
    end

    it 'configure neutron common' do
      should contain_class('neutron').with(
          :allow_overlapping_ips   => true,
          :dhcp_agents_per_network => '2',
          :verbose                 => true,
          :debug                   => true,
          :log_facility            => 'LOG_LOCAL0',
          :use_syslog              => true,
          :rabbit_user             => 'neutron',
          :rabbit_hosts            => ['10.0.0.1'],
          :rabbit_password         => 'secrete',
          :rabbit_virtual_host     => '/',
          :bind_host               => '10.0.0.1',
          :core_plugin             => 'neutron.plugins.ml2.plugin.Ml2Plugin',
          :service_plugins         => ['neutron.services.loadbalancer.plugin.LoadBalancerPlugin','neutron.services.metering.metering_plugin.MeteringPlugin','neutron.services.l3_router.l3_router_plugin.L3RouterPlugin'],
          :log_dir                 => false,
          :dhcp_lease_duration     => '10',
          :report_interval         => '30'
      )
      should contain_class('neutron::agents::ovs').with(
          :enable_tunneling => true,
          :tunnel_types     => ['vxlan'],
          :bridge_mappings  => ['public:br-pub'],
          :local_ip         => '10.0.1.1'
      )
      should contain_class('neutron::plugins::ml2').with(
          :type_drivers           => ['gre', 'vlan', 'flat', 'vxlan'],
          :tenant_network_types   => ['vxlan'],
          :mechanism_drivers      => ['openvswitch','l2population'],
          :tunnel_id_ranges       => ['1:10000'],
          :network_vlan_ranges    => ['physnet1:1000:2999'],
          :flat_networks          => ['public'],
          :enable_security_group  => true
      )
      should_not contain__neutron_network('public')
    end

    it 'configure neutron lbaas' do
      should contain_class('neutron::agents::lbaas').with(
          :debug                  => true,
          :manage_haproxy_package => true
      )
    end

    context 'when not managing HAproxy package' do
      let :pre_condition do
        "package {'haproxy': ensure => 'present'}
         class { 'cloud::network':
           rabbit_hosts             => ['10.0.0.1'],
           rabbit_password          => 'secrete',
           tunnel_eth               => '10.0.1.1',
           api_eth                  => '10.0.0.1',
           provider_vlan_ranges     => ['physnet1:1000:2999'],
           provider_bridge_mappings => ['physnet1:br-eth1'],
           verbose                  => true,
           debug                    => true,
           use_syslog               => true,
           dhcp_lease_duration      => '10',
           log_facility             => 'LOG_LOCAL0' }"
      end
      before :each do
        params.merge!(:manage_haproxy_pkg => false)
      end
      it 'configure neutron lbaas agent without managing haproxy package' do
        should contain_class('neutron::agents::lbaas').with(:manage_haproxy_package => false)
        should contain_package('haproxy').with(:ensure => 'present')
      end
    end

    context 'when using provider external network' do
      let :pre_condition do
        "class { 'cloud::network':
          rabbit_hosts             => ['10.0.0.1'],
          rabbit_password          => 'secrete',
          tunnel_eth               => '10.0.1.1',
          api_eth                  => '10.0.0.1',
          provider_vlan_ranges     => ['physnet1:1000:2999'],
          provider_bridge_mappings => ['public:br-pub'],
          flat_networks            => ['public'],
          external_int             => 'eth1',
          external_bridge          => 'br-pub',
          manage_ext_network       => true,
          verbose                  => true,
          debug                    => true,
          use_syslog               => true,
          dhcp_lease_duration      => '10',
          log_facility             => 'LOG_LOCAL0' }"
      end

      it 'configure br-pub bridge' do
        should contain_vs_bridge('br-pub')
      end
      it 'configure eth1 in br-pub' do
        should contain_vs_port('eth1').with(
          :ensure => 'present',
          :bridge => 'br-pub'
        )
      end
      it 'should not configure provider external network' do
        should_not contain__neutron_network('public')
      end
    end
  end

  context 'on Debian platforms' do
    let :facts do
      { :osfamily => 'Debian' }
    end

    let :platform_params do
      { :gre_module_name => 'gre' }
    end

    it_configures 'openstack network lbaas'
  end

  context 'on RedHat platforms' do
    let :facts do
      { :osfamily => 'RedHat' }
    end

    let :platform_params do
      { :gre_module_name => 'ip_gre' }
    end

    it_configures 'openstack network lbaas'
  end

end
