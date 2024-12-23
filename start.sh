#!/bin/bash

# Exit on any error
set -e

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to install system packages
install_system_packages() {
    echo "Updating system packages..."
    sudo apt update
    sudo apt upgrade -y

    echo "Installing essential packages..."
    sudo apt-get install -y \
        curl \
        git \
        python3 \
        python3-pip \
        python3-venv \
        software-properties-common \
        jq
}

# Function to install Node.js
install_nodejs() {
    if ! command_exists node; then
        echo "Installing Node.js..."
        curl -fsSL https://deb.nodesource.com/setup_18.x | sudo -E bash -
        sudo apt install -y nodejs
    fi
    echo "Node.js version: $(node --version)"
    echo "npm version: $(npm --version)"
}

# Function to install OVN
install_ovn() {
    echo "Installing OVN..."
    sudo apt-get update
    sudo apt-get install -y openvswitch-switch openvswitch-common ovn-central ovn-host

    # Create necessary directories
    sudo mkdir -p /var/run/ovn
    sudo mkdir -p /etc/ovn
    sudo chown -R root:root /var/run/ovn
    sudo chown -R root:root /etc/ovn

    # Start OpenVSwitch service first
    echo "Starting OpenVSwitch service..."
    if systemctl is-active --quiet openvswitch-switch; then
        echo "OpenVSwitch service is already running"
    else
        sudo systemctl start openvswitch-switch
        sudo systemctl enable openvswitch-switch
    fi

    # Start OVN central service (this starts ovsdb-server)
    echo "Starting OVN central service..."
    if systemctl is-active --quiet ovn-central; then
        echo "OVN central is already running"
    else
        sudo systemctl start ovn-central
        sudo systemctl enable ovn-central
    fi

    # Wait for ovsdb-server to be ready
    echo "Waiting for ovsdb-server..."
    for i in {1..30}; do
        if sudo ovsdb-client list-dbs > /dev/null 2>&1; then
            echo "ovsdb-server is ready!"
            break
        fi
        echo "Waiting for ovsdb-server... ($i/30)"
        sleep 1
    done

    # Initialize OVN databases
    echo "Initializing OVN databases..."
    sudo ovs-vsctl set open_vswitch . external_ids:ovn-remote=unix:/var/run/ovn/ovnsb_db.sock
    sudo ovs-vsctl set open_vswitch . external_ids:ovn-encap-type=geneve
    sudo ovs-vsctl set open_vswitch . external_ids:ovn-encap-ip=127.0.0.1

    # Initialize the OVN databases if they don't exist
    if [ ! -f "/etc/ovn/ovnnb_db.db" ]; then
        echo "Initializing OVN North database..."
        sudo ovn-nbctl init
    fi
    
    if [ ! -f "/etc/ovn/ovnsb_db.db" ]; then
        echo "Initializing OVN South database..."
        sudo ovn-sbctl init
    fi

    # Start remaining OVN services
    echo "Starting OVN services..."
    if systemctl is-active --quiet ovn-northd; then
        echo "OVN Northd is already running"
    else
        sudo systemctl start ovn-northd
        sudo systemctl enable ovn-northd
    fi

    if systemctl is-active --quiet ovn-controller; then
        echo "OVN Controller is already running"
    else
        sudo systemctl start ovn-controller
        sudo systemctl enable ovn-controller
    fi

    # Wait for services to be fully up and databases to be ready
    echo "Waiting for OVN services and databases to initialize..."
    for i in {1..30}; do
        echo "Waiting... ($i/30)"
        if sudo ovn-nbctl show > /dev/null 2>&1; then
            echo "OVN database is now accessible!"
            break
        fi
        sleep 1
    done

    # Verify database connection
    echo "Verifying OVN database connection..."
    if ! sudo ovn-nbctl show > /dev/null 2>&1; then
        echo "Error: Unable to connect to OVN database. Retrying with explicit socket path..."
        export OVN_NB_DB=unix:/var/run/ovn/ovnnb_db.sock
        if ! sudo ovn-nbctl show > /dev/null 2>&1; then
            echo "Error: Still unable to connect to OVN database."
            echo "Debugging information:"
            echo "1. Checking OVN socket file..."
            ls -l /var/run/ovn/
            echo "2. Checking OVN service status..."
            systemctl status ovn-northd
            systemctl status ovn-central
            echo "3. Checking OVS database status..."
            sudo ovsdb-client list-dbs
            return 1
        fi
    fi
}

# Function to check OVN services
check_ovn_services() {
    echo "Checking OVN services..."
    
    # Check OpenVSwitch
    if systemctl is-active --quiet openvswitch-switch; then
        echo " openvswitch-switch is running"
    else
        echo " openvswitch-switch is not running"
        echo "Attempting to start openvswitch-switch..."
        sudo systemctl start openvswitch-switch || echo "Failed to start openvswitch-switch"
    fi

    # Check OVN services
    if systemctl is-active --quiet ovn-northd; then
        echo " ovn-northd is running"
    else
        echo " ovn-northd is not running"
        echo "Attempting to start ovn-northd..."
        sudo systemctl start ovn-northd || echo "Failed to start ovn-northd"
    fi

    if systemctl is-active --quiet ovn-controller; then
        echo " ovn-controller is running"
    else
        echo " ovn-controller is not running"
        echo "Attempting to start ovn-controller..."
        sudo systemctl start ovn-controller || echo "Failed to start ovn-controller"
    fi
}

# Function to create basic OVN network configuration
setup_ovn_network() {
    echo "Setting up basic OVN network configuration..."
    
    # Clean up existing network configuration
    echo "Cleaning up existing network configuration..."
    
    # Get list of existing switches and delete them
    echo "Checking existing logical switches..."
    # First try direct command output
    switches=$(sudo ovn-nbctl ls-list | awk '{if(NR>1)print $1}')
    if [ ! -z "$switches" ]; then
        echo "Found existing switches, removing them..."
        echo "$switches" | while read switch_uuid; do
            if [ ! -z "$switch_uuid" ]; then
                echo "Removing logical switch with UUID: $switch_uuid"
                sudo ovn-nbctl ls-del "$switch_uuid"
            fi
        done
    else
        echo "No existing switches found."
    fi

    # Get list of existing routers and delete them
    echo "Checking existing logical routers..."
    # First try direct command output
    routers=$(sudo ovn-nbctl lr-list | awk '{if(NR>1)print $1}')
    if [ ! -z "$routers" ]; then
        echo "Found existing routers, removing them..."
        echo "$routers" | while read router_uuid; do
            if [ ! -z "$router_uuid" ]; then
                echo "Removing logical router with UUID: $router_uuid"
                sudo ovn-nbctl lr-del "$router_uuid"
            fi
        done
    else
        echo "No existing routers found."
    fi
    
    # Create logical switches
    echo "Creating logical switches..."
    sudo ovn-nbctl ls-add demo-switch1
    sudo ovn-nbctl ls-add demo-switch2
    
    # Create logical router
    echo "Creating logical router..."
    sudo ovn-nbctl lr-add demo-router
    
    # Create logical ports on switches
    echo "Creating logical ports..."
    # Ports on switch1
    sudo ovn-nbctl lsp-add demo-switch1 demo-switch1-port1
    sudo ovn-nbctl lsp-set-addresses demo-switch1-port1 "02:ac:10:ff:01:01 172.16.1.11"
    sudo ovn-nbctl lsp-add demo-switch1 demo-switch1-router-port
    sudo ovn-nbctl lsp-set-type demo-switch1-router-port router
    sudo ovn-nbctl lsp-set-addresses demo-switch1-router-port router
    
    # Ports on switch2
    sudo ovn-nbctl lsp-add demo-switch2 demo-switch2-port1
    sudo ovn-nbctl lsp-set-addresses demo-switch2-port1 "02:ac:10:ff:02:01 172.16.2.11"
    sudo ovn-nbctl lsp-add demo-switch2 demo-switch2-router-port
    sudo ovn-nbctl lsp-set-type demo-switch2-router-port router
    sudo ovn-nbctl lsp-set-addresses demo-switch2-router-port router
    
    # Connect router ports
    echo "Connecting router ports..."
    sudo ovn-nbctl lrp-add demo-router demo-router-port1 02:ac:10:ff:01:02 172.16.1.1/24
    sudo ovn-nbctl lrp-add demo-router demo-router-port2 02:ac:10:ff:02:02 172.16.2.1/24
    
    # Set up port bindings
    sudo ovn-nbctl lsp-set-options demo-switch1-router-port router-port=demo-router-port1
    sudo ovn-nbctl lsp-set-options demo-switch2-router-port router-port=demo-router-port2
    
    echo "Basic OVN network configuration completed!"
}

# Function to verify OVN configuration
verify_ovn_config() {
    echo "Verifying OVN configuration..."
    echo -e "\nLogical Switches:"
    sudo ovn-nbctl ls-list
    
    echo -e "\nLogical Router:"
    sudo ovn-nbctl lr-list
    
    echo -e "\nLogical Switch Ports:"
    sudo ovn-nbctl lsp-list demo-switch1
    sudo ovn-nbctl lsp-list demo-switch2
}

# Function to set up Python environment
setup_python_env() {
    echo "Setting up Python environment..."
    python3 -m venv venv
    source venv/bin/activate
    pip install -r requirements.txt

    # Create backend directory structure
    mkdir -p backend/utils

    # Create validators.py
    cat > backend/utils/validators.py << 'EOL'
def validate_switch_data(data):
    """Validate logical switch data."""
    required_fields = ['name']
    
    if not isinstance(data, dict):
        return False, "Data must be a dictionary"
    
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
        
        if not isinstance(data[field], str):
            return False, f"Field {field} must be a string"
        
        if not data[field].strip():
            return False, f"Field {field} cannot be empty"
    
    return True, None

def validate_router_data(data):
    """Validate logical router data."""
    required_fields = ['name']
    
    if not isinstance(data, dict):
        return False, "Data must be a dictionary"
    
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
        
        if not isinstance(data[field], str):
            return False, f"Field {field} must be a string"
        
        if not data[field].strip():
            return False, f"Field {field} cannot be empty"
    
    return True, None

def validate_port_data(data):
    """Validate port data."""
    required_fields = ['name', 'type']
    
    if not isinstance(data, dict):
        return False, "Data must be a dictionary"
    
    for field in required_fields:
        if field not in data:
            return False, f"Missing required field: {field}"
        
        if not isinstance(data[field], str):
            return False, f"Field {field} must be a string"
        
        if not data[field].strip():
            return False, f"Field {field} cannot be empty"
    
    return True, None
EOL

    # Start the Flask backend server
    echo "Starting Flask backend server..."
    nohup python3 backend/app.py --host 0.0.0.0 --port 5000 > backend.log 2>&1 &
    echo "Backend server started and listening on all interfaces (port 5000)"
}

# Function to set up frontend
setup_frontend() {
    echo "Setting up frontend..."
    cd frontend

    # Create public directory if it doesn't exist
    mkdir -p public

    # Create index.html
    cat > public/index.html << 'EOL'
<!DOCTYPE html>
<html lang="en">
  <head>
    <meta charset="utf-8" />
    <link rel="icon" href="%PUBLIC_URL%/favicon.ico" />
    <meta name="viewport" content="width=device-width, initial-scale=1" />
    <meta name="theme-color" content="#000000" />
    <meta
      name="description"
      content="OVN Web Manager - A modern interface for Open Virtual Network"
    />
    <link rel="apple-touch-icon" href="%PUBLIC_URL%/logo192.png" />
    <link rel="manifest" href="%PUBLIC_URL%/manifest.json" />
    <title>OVN Web Manager</title>
  </head>
  <body>
    <noscript>You need to enable JavaScript to run this app.</noscript>
    <div id="root"></div>
  </body>
</html>
EOL

    # Create manifest.json
    cat > public/manifest.json << 'EOL'
{
  "short_name": "OVN Manager",
  "name": "OVN Web Manager",
  "icons": [
    {
      "src": "favicon.ico",
      "sizes": "64x64 32x32 24x24 16x16",
      "type": "image/x-icon"
    }
  ],
  "start_url": ".",
  "display": "standalone",
  "theme_color": "#000000",
  "background_color": "#ffffff"
}
EOL

    # Create a simple favicon (1x1 transparent pixel in base64)
    echo 'AAABAAEAEBAQAAEABAAoAQAAFgAAACgAAAAQAAAAIAAAAAEABAAAAAAAgAAAAAAAAAAAAAAAEAAAAAAAAAAAAAAA////AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA' | base64 -d > public/favicon.ico

    # Install dependencies
    echo "Installing frontend dependencies..."
    npm install @mui/material @mui/icons-material @emotion/react @emotion/styled react-router-dom
    npm install

    # Create directories
    mkdir -p src/components
    mkdir -p src/pages
    
    # Create index.js if it doesn't exist
    if [ ! -f src/index.js ]; then
        cat > src/index.js << 'EOL'
import React from 'react';
import ReactDOM from 'react-dom/client';
import { BrowserRouter } from 'react-router-dom';
import { ThemeProvider, createTheme } from '@mui/material';
import CssBaseline from '@mui/material/CssBaseline';
import App from './App';

const theme = createTheme({
  palette: {
    mode: 'light',
  },
});

const root = ReactDOM.createRoot(document.getElementById('root'));
root.render(
  <React.StrictMode>
    <BrowserRouter>
      <ThemeProvider theme={theme}>
        <CssBaseline />
        <App />
      </ThemeProvider>
    </BrowserRouter>
  </React.StrictMode>
);
EOL
    fi

    # Create App.js if it doesn't exist
    if [ ! -f src/App.js ]; then
        cat > src/App.js << 'EOL'
import React from 'react';
import { Routes, Route } from 'react-router-dom';
import Layout from './components/Layout';
import Dashboard from './pages/Dashboard';
import LogicalSwitches from './pages/LogicalSwitches';
import LogicalRouters from './pages/LogicalRouters';
import LoadBalancers from './pages/LoadBalancers';
import ACLs from './pages/ACLs';
import Settings from './pages/Settings';

function App() {
  return (
    <Layout>
      <Routes>
        <Route path="/" element={<Dashboard />} />
        <Route path="/logical-switches" element={<LogicalSwitches />} />
        <Route path="/logical-routers" element={<LogicalRouters />} />
        <Route path="/load-balancers" element={<LoadBalancers />} />
        <Route path="/acls" element={<ACLs />} />
        <Route path="/settings" element={<Settings />} />
      </Routes>
    </Layout>
  );
}

export default App;
EOL
    fi

    # Create Dashboard.js if it doesn't exist
    if [ ! -f src/pages/Dashboard.js ]; then
        cat > src/pages/Dashboard.js << 'EOL'
import React from 'react';
import { Box, Typography, Grid, Paper } from '@mui/material';

function Dashboard() {
  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Typography variant="h4" gutterBottom>
        Dashboard
      </Typography>
      <Grid container spacing={3}>
        <Grid item xs={12} md={6} lg={4}>
          <Paper sx={{ p: 2 }}>
            <Typography variant="h6">Network Overview</Typography>
            <Typography variant="body1">
              Monitor your OVN network components and their status.
            </Typography>
          </Paper>
        </Grid>
      </Grid>
    </Box>
  );
}

export default Dashboard;
EOL
    fi

    # Create placeholder pages for other routes
    for page in "LogicalSwitches" "LogicalRouters" "LoadBalancers" "ACLs" "Settings"; do
        if [ ! -f "src/pages/${page}.js" ]; then
            cat > "src/pages/${page}.js" << EOL
import React from 'react';
import { Box, Typography } from '@mui/material';

function ${page}() {
  return (
    <Box sx={{ flexGrow: 1, p: 3 }}>
      <Typography variant="h4" gutterBottom>
        ${page}
      </Typography>
      <Typography variant="body1">
        This page is under construction.
      </Typography>
    </Box>
  );
}

export default ${page};
EOL
        fi
    done

    # Install additional dependencies
    npm install @mui/material @mui/icons-material @emotion/react @emotion/styled react-router-dom

    # Install dependencies and build
    echo "Installing frontend dependencies..."
    npm install
    
    # Install serve locally
    npm install serve --save-dev

    echo "Creating production build..."
    npm run build

    # Kill any existing serve processes
    pkill -f "serve -s build" || true
    
    # Start the frontend server using local serve
    echo "Starting frontend server..."
    nohup ./node_modules/.bin/serve -s build --listen 0.0.0.0:3000 --cors > frontend.log 2>&1 &
    
    # Wait a moment for the server to start
    sleep 2
    
    # Display network access information
    echo ""
    echo "Application started successfully!"
    echo "----------------------------------------"
    echo "Available network interfaces:"
    ip -4 addr show | grep inet | awk '{print $2}' | cut -d/ -f1 | while read ip; do
        if [ "$ip" != "127.0.0.1" ]; then
            echo "http://$ip:3000 (Frontend)"
            echo "http://$ip:5000 (Backend API)"
        fi
    done
    echo "----------------------------------------"
    echo "The application is listening on all network interfaces"
    echo "Use any of the above URLs based on your network configuration"

    cd ..
}

# Function to cleanup processes
cleanup() {
    echo "Stopping application..."
    kill $BACKEND_PID 2>/dev/null || true
    kill $FRONTEND_PID 2>/dev/null || true
    exit 0
}

# Main installation process
main() {
    echo "Starting OVN Web Manager installation..."

    # Check if running as root
    if [ "$EUID" -eq 0 ]; then
        echo "Please do not run this script as root"
        exit 1
    fi

    # Check Ubuntu version
    if ! grep -q "Ubuntu 22.04" /etc/os-release; then
        echo "This script requires Ubuntu 22.04"
        exit 1
    fi

    # Install all required packages
    install_system_packages
    install_nodejs
    install_ovn

    # Set up application
    setup_python_env
    setup_frontend

    # Check services
    check_ovn_services
    
    # Set up OVN network
    echo "Setting up OVN network..."
    setup_ovn_network
    verify_ovn_config

    echo "Installation completed successfully!"

    # Ask user if they want to start the application
    read -p "Do you want to start the application now? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        # Start backend
        echo "Starting backend..."
        cd backend
        python3 app.py &
        BACKEND_PID=$!

        # Start frontend development server
        echo "Starting frontend..."
        cd ../frontend
        npm start &
        FRONTEND_PID=$!

        # Setup cleanup on script termination
        trap cleanup SIGINT SIGTERM

        # Wait for processes
        wait
    else
        echo "You can start the application later by running:"
        echo "cd backend && python3 app.py &"
        echo "cd frontend && npm start &"
    fi
}

# Run main function
main
