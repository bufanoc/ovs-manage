from flask import Flask, request, jsonify
import ovn_api

app = Flask(__name__)

@app.route('/configure_vxlan', methods=['POST'])
def configure_vxlan():
    data = request.get_json()

    if not data or not 'hosts' in data:
        return jsonify({"error": "Invalid input"}), 400

    hosts = data['hosts']

    try:
        ovn = ovn_api.OvnApi()
        ovn.configure_vxlan(hosts)
        return jsonify({"success": "VXLAN overlays configured successfully"}), 200
    except Exception as e:
        return jsonify({"error": str(e)}), 500

if __name__ == '__main__':
    app.run()
