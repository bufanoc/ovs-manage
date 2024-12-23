# OVN Web Manager 

This has been developed on Ubuntu 22.04 minimal server. For best results run it on that.
Do not run this in production, it is not even close.
Help is apreciated & welcomed.

# A modern web application for managing Open Virtual Network (OVN) through a beautiful and intuitive interface, designed to run on Ubuntu Server.

## Features

- Logical Switch Management
- Logical Router Management
- ACL Management
- Load Balancer Configuration
- Security Groups
- Port Management
- DHCP Configuration
- NAT Configuration
- Real-time Network Visualization
- Multi-tenant Support

## System Requirements

- Ubuntu Server 22.04 LTS (minimal installation)
- Internet connection for package installation
- Minimum 2GB RAM
- 20GB disk space

## Quick Start

1. Clone the repository:
   ```bash
   git clone https://github.com/bufanoc/ovn-web-manager.git
   cd ovn-web-manager
   ```

2. Make the installation script executable:
   ```bash
   chmod +x start.sh
   ```

3. Run the installation script:
   ```bash
   ./start.sh
   ```

The script will automatically:
- Install all required system packages
- Set up OVN and its dependencies
- Configure the Python backend environment
- Build and serve the React frontend
- Start all necessary services

Once completed, the application will be accessible at:
- Frontend: `http://<server-ip>:3000`
- Backend API: `http://<server-ip>:5000`

## Components Installed

- **System Packages**: git, curl, python3, nodejs, jq, and other dependencies
- **OVN**: Latest version from Ubuntu repositories
- **Frontend**: React-based web interface
- **Backend**: Flask API server
- **Database**: OVN native databases

## Architecture

- Frontend: React with Material-UI
- Backend: Python Flask REST API
- Network: OVN (Open Virtual Network)
- Database: OVN native databases (northbound and southbound)

## Security Notes

- The application runs services on ports 3000 (frontend) and 5000 (backend)
- Make sure to configure your firewall to allow access to these ports
- Consider setting up HTTPS for production use
- Default configuration listens on all network interfaces

## Troubleshooting

If you encounter issues:

1. Check service status:
   ```bash
   systemctl status openvswitch-switch
   systemctl status ovn-northd
   systemctl status ovn-controller
   ```

2. View application logs:
   ```bash
   tail -f frontend.log
   tail -f backend.log
   ```

3. Check OVN database connectivity:
   ```bash
   sudo ovn-nbctl show
   sudo ovn-sbctl show
   ```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

MIT License








