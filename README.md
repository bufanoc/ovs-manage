OVN VXLAN Configuration Web Application
========================================

This web application allows users to configure VXLAN overlays between a list of hosts using OVN (Open Virtual Network). The application provides a web interface to enter the required host information and configure the VXLAN overlays.

Dependencies
------------

The following Python packages are required to run the application:

1. Flask
2. Flask-WTF
3. python-ovn

You can install these dependencies using pip:

pip install Flask Flask-WTF python-ovn

Usage
-----

1. Run the Flask application by executing the following command:
(python ovn_vxlan.py)

2. Access the web application at `http://localhost:5000/` in your browser.

3. Fill in the required host information (name, IP address, MAC address, and VTEP IP address) for each host.

4. Click the "Add Host" button to add more hosts to the list.

5. Click "Configure VXLAN" to configure VXLAN overlays between the entered hosts.

6. If the configuration is successful, a success message will be displayed on the page. If there's an error, the error message will be displayed.

API
---

The application also provides a JSON API to configure VXLAN overlays. You can send a POST request to the `/configure_vxlan` endpoint with a JSON body containing a list of hosts. Here's an example of the expected input format:

```json
{
  "hosts": [
    {
      "name": "host1",
      "ip": "10.0.0.1",
      "mac": "aa:bb:cc:dd:ee:01",
      "vtep_ip": "192.168.1.1"
    },
    {
      "name": "host2",
      "ip": "10.0.0.2",
      "mac": "aa:bb:cc:dd:ee:02",
      "vtep_ip": "192.168.1.2"
    }
  ]
}





