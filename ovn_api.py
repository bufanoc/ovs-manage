import os
from ovn import api as ovn_api
from ovn import utils as ovn_utils
from ovn import schema as ovn_schema

class OvnApi:
    def __init__(self):
        # Configure OVN API connection
        self.api = ovn_api.API(
            ovn_api.Connection(ovn_utils.get_connection_mode()),
            ovn_schema.Schema.from_file(ovn_utils.get_schema())
        )

    def configure_vxlan(self, hosts):
        # Get the OVN API instance
        ovn = self.api

        # Create a new Logical Switch for the VXLAN overlay
        ls_name = 'vxlan_overlay'
        ovn.ls_add(ls_name).execute()

        # Iterate through the hosts and create a logical port for each
        for host in hosts:
            host_name = host['name']
            host_ip = host['ip']
            host_mac = host['mac']

            # Add logical port
            port_name = f'lp_{host_name}'
            ovn.lsp_add(ls_name, port_name).execute()

            # Set the MAC and IP addresses for the logical port
            ovn.lsp_set_addresses(port_name, [f'{host_mac} {host_ip}']).execute()

        # Set up VXLAN tunnels between the hosts
        for host in hosts:
            host_name = host['name']
            host_vtep_ip = host['vtep_ip']

            # Create a new VTEP for the host
            vtep_name = f'vtep_{host_name}'
            ovn.vtep_add(vtep_name).execute()

            # Set the VTEP's local IP and bind it to the logical switch
            ovn.vtep_set_local_ip(vtep_name, host_vtep_ip).execute()
            ovn.vtep_bind_ls(vtep_name, ls_name).execute()
