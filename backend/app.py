from flask import Flask, request, jsonify
from flask_cors import CORS
import os
from dotenv import load_dotenv
from werkzeug.middleware.proxy_fix import ProxyFix

# Import OVN controllers
from controllers.logical_switch import logical_switch_routes
from controllers.logical_router import logical_router_routes
from controllers.acl import acl_routes
from controllers.load_balancer import load_balancer_routes
from controllers.port import port_routes

# Load environment variables
load_dotenv()

app = Flask(__name__)
# Configure CORS to allow requests from any origin
CORS(app, resources={
    r"/api/*": {
        "origins": "*",
        "methods": ["GET", "POST", "PUT", "DELETE", "OPTIONS"],
        "allow_headers": ["Content-Type", "Authorization"]
    }
})
app.wsgi_app = ProxyFix(app.wsgi_app)

# Register blueprints for different OVN components
app.register_blueprint(logical_switch_routes, url_prefix='/api/logical-switches')
app.register_blueprint(logical_router_routes, url_prefix='/api/logical-routers')
app.register_blueprint(acl_routes, url_prefix='/api/acls')
app.register_blueprint(load_balancer_routes, url_prefix='/api/load-balancers')
app.register_blueprint(port_routes, url_prefix='/api/ports')

@app.route('/api/health')
def health_check():
    return jsonify({"status": "healthy", "message": "OVN Web Manager is running"})

@app.errorhandler(404)
def not_found(e):
    return jsonify({"error": "Resource not found"}), 404

@app.errorhandler(500)
def server_error(e):
    return jsonify({"error": "Internal server error"}), 500

if __name__ == '__main__':
    port = int(os.getenv('PORT', 5000))
    debug = os.getenv('FLASK_ENV') == 'development'
    app.run(host='0.0.0.0', port=port, debug=debug)
