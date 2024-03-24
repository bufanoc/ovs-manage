import subprocess
import json

def create_vxlan_network(tenant_name, network_name, subnet_name, vni):
    """Creates a new VXLAN network between a XCP-NG host OpenvSwitch and OpenStack Neutron tenant network.

    Args:
        tenant_name (str): The name of the tenant.
        network_name (str): The name of the network.
        subnet_name (str): The name of the subnet.
        vni (int): The VNI for the network.
    """

    # Create the VXLAN bridge on the XCP-NG host.
    subprocess.call(["ovs-vsctl", "add-br", "vxlan{}".format(vni)])

    # Set the VNI for the bridge.
    subprocess.call(["ovs-vsctl", "set", "bridge", "vxlan{}".format(vni), "vni={}".format(vni)])

    # Add the bridge to the OpenvSwitch database.
    subprocess.call(["ovsdb-client", "add-br", "vxlan{}".format(vni)])

    # Create a port on the bridge for the OpenStack Neutron network.
    subprocess.call(["ovs-vsctl", "add-port", "vxlan{}".format(vni), "vxlan-port"])

    # Set the VLAN for the port.
    subprocess.call(["ovs-vsctl", "set", "interface", "vxlan-port", "vlan={}".format(vni)])

    # Set the IP address for the port.
    subprocess.call(["ovs-vsctl", "set", "interface", "vxlan-port", "ip={}".format(get_ip_address(tenant_name, network_name, subnet_name))])

    # Set the MAC address for the port.
    subprocess.call(["ovs-vsctl", "set", "interface", "vxlan-port", "mac={}".format(get_mac_address(tenant_name, network_name, subnet_name))])

    # Add the port to the OpenStack Neutron network.
    subprocess.call(["neutron", "net-add-port", network_name, "vxlan-port"])

def get_ip_address(tenant_name, network_name, subnet_name):
    """Gets the IP address for the OpenStack Neutron network.

    Args:
        tenant_name (str): The name of the tenant.
        network_name (str): The name of the network.
        subnet_name (str): The name of the subnet.
    """

    # Get the subnet details.
    subprocess.call(["neutron", "subnet-show", subnet_name])

    # Get the IP address from the subnet details.
    ip_address = json.loads(subprocess.check_output(["neutron", "subnet-show", subnet_name]))["subnet"]["allocation_pools"][0]["start"]

    return ip_address

def get_mac_address(tenant_name, network_name, subnet_name):
    """Gets the MAC address for the OpenStack Neutron network.

    Args:
        tenant_name (str): The name of the tenant.
        network_name (str): The name of the network.
        subnet_name (str): The name of the subnet.
    """

    # Get the subnet details.
    subprocess.call(["neutron", "subnet-show", subnet_name])

    # Get the MAC address from the subnet details.
    mac_address = json.loads(subprocess.check_output(["neutron", "subnet-show", subnet_name]))["subnet"]["allocation_pools"][0]["start"]

    return mac_address

# Create a new VXLAN network for the specific tenant.
create_vxlan_network("tenant1", "network1", "subnet1", 100)