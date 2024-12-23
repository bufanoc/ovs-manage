from flask import Blueprint, request, jsonify
from services.ovn_client import OVNClient
from utils.validators import validate_switch_data

logical_switch_routes = Blueprint('logical_switches', __name__)
ovn_client = OVNClient()

@logical_switch_routes.route('/', methods=['GET'])
def get_all_switches():
    try:
        switches = ovn_client.get_logical_switches()
        return jsonify(switches)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@logical_switch_routes.route('/<switch_id>', methods=['GET'])
def get_switch(switch_id):
    try:
        switch = ovn_client.get_logical_switch(switch_id)
        if not switch:
            return jsonify({"error": "Switch not found"}), 404
        return jsonify(switch)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@logical_switch_routes.route('/', methods=['POST'])
def create_switch():
    data = request.get_json()
    validation_error = validate_switch_data(data)
    if validation_error:
        return jsonify({"error": validation_error}), 400

    try:
        switch = ovn_client.create_logical_switch(data)
        return jsonify(switch), 201
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@logical_switch_routes.route('/<switch_id>', methods=['PUT'])
def update_switch(switch_id):
    data = request.get_json()
    validation_error = validate_switch_data(data)
    if validation_error:
        return jsonify({"error": validation_error}), 400

    try:
        switch = ovn_client.update_logical_switch(switch_id, data)
        if not switch:
            return jsonify({"error": "Switch not found"}), 404
        return jsonify(switch)
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@logical_switch_routes.route('/<switch_id>', methods=['DELETE'])
def delete_switch(switch_id):
    try:
        success = ovn_client.delete_logical_switch(switch_id)
        if not success:
            return jsonify({"error": "Switch not found"}), 404
        return '', 204
    except Exception as e:
        return jsonify({"error": str(e)}), 500

@logical_switch_routes.route('/<switch_id>/ports', methods=['GET'])
def get_switch_ports(switch_id):
    try:
        ports = ovn_client.get_switch_ports(switch_id)
        return jsonify(ports)
    except Exception as e:
        return jsonify({"error": str(e)}), 500
