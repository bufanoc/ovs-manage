import subprocess
import json
import os
from typing import Dict, List, Optional

class OVNClient:
    def __init__(self):
        # Use the correct socket path for OVN
        self.nb_db = os.getenv('OVN_NB_DB', "unix:/var/run/ovn/ovnnb_db.sock")

    def _check_ovn_status(self) -> bool:
        """Check if OVN services are running"""
        try:
            subprocess.run(["ovn-nbctl", "show"], capture_output=True, check=True)
            return True
        except (subprocess.CalledProcessError, FileNotFoundError):
            return False

    def _execute_ovn_command(self, command: List[str]) -> str:
        if not self._check_ovn_status():
            raise Exception("OVN services are not running or not properly configured")
            
        try:
            result = subprocess.run(
                command,
                capture_output=True,
                text=True,
                check=True
            )
            return result.stdout
        except subprocess.CalledProcessError as e:
            raise Exception(f"OVN command failed: {e.stderr}")
        except FileNotFoundError:
            raise Exception("OVN commands not found. Please ensure OVN is properly installed")

    def get_logical_switches(self) -> List[Dict]:
        command = ["ovn-nbctl", "--format=json", "ls-list"]
        output = self._execute_ovn_command(command)
        return json.loads(output)

    def get_logical_switch(self, switch_id: str) -> Optional[Dict]:
        command = ["ovn-nbctl", "--format=json", "ls-get", switch_id]
        try:
            output = self._execute_ovn_command(command)
            return json.loads(output)
        except Exception:
            return None

    def create_logical_switch(self, switch_data: Dict) -> Dict:
        name = switch_data.get("name")
        if not name:
            raise ValueError("Switch name is required")

        command = ["ovn-nbctl", "ls-add", name]
        
        # Add optional parameters
        if "external_ids" in switch_data:
            for key, value in switch_data["external_ids"].items():
                command.extend(["--", "set", "Logical_Switch", name,
                              f"external_ids:{key}={value}"])

        self._execute_ovn_command(command)
        return self.get_logical_switch(name)

    def update_logical_switch(self, switch_id: str, switch_data: Dict) -> Optional[Dict]:
        if not self.get_logical_switch(switch_id):
            return None

        command = ["ovn-nbctl"]
        
        if "external_ids" in switch_data:
            for key, value in switch_data["external_ids"].items():
                command.extend(["set", "Logical_Switch", switch_id,
                              f"external_ids:{key}={value}"])

        self._execute_ovn_command(command)
        return self.get_logical_switch(switch_id)

    def delete_logical_switch(self, switch_id: str) -> bool:
        if not self.get_logical_switch(switch_id):
            return False

        command = ["ovn-nbctl", "ls-del", switch_id]
        self._execute_ovn_command(command)
        return True

    def get_switch_ports(self, switch_id: str) -> List[Dict]:
        command = ["ovn-nbctl", "--format=json", "lsp-list", switch_id]
        try:
            output = self._execute_ovn_command(command)
            return json.loads(output)
        except Exception:
            return []

    # Additional methods for other OVN operations can be added here
    def get_logical_routers(self) -> List[Dict]:
        command = ["ovn-nbctl", "--format=json", "lr-list"]
        output = self._execute_ovn_command(command)
        return json.loads(output)

    def create_logical_router(self, router_data: Dict) -> Dict:
        name = router_data.get("name")
        if not name:
            raise ValueError("Router name is required")

        command = ["ovn-nbctl", "lr-add", name]
        self._execute_ovn_command(command)
        return {"name": name, "id": name}

    def create_acl(self, switch_id: str, acl_data: Dict) -> Dict:
        direction = acl_data.get("direction", "to-lport")
        priority = acl_data.get("priority", "1000")
        match = acl_data.get("match")
        action = acl_data.get("action", "allow")

        if not all([switch_id, match]):
            raise ValueError("Switch ID and match criteria are required")

        command = [
            "ovn-nbctl", "acl-add", switch_id,
            direction, priority, match, action
        ]
        self._execute_ovn_command(command)
        return acl_data
