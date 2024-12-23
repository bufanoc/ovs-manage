import requests
import json

BASE_URL = 'http://localhost:5000/api'

def test_health():
    response = requests.get(f'{BASE_URL}/health')
    print('Health Check:', response.json())

def test_logical_switches():
    # List switches
    print('\n=== Testing Logical Switches ===')
    response = requests.get(f'{BASE_URL}/logical-switches')
    print('List Switches:', response.json())

    # Create switch
    switch_data = {
        'name': 'test-switch',
        'external_ids': {'description': 'Test switch'}
    }
    response = requests.post(f'{BASE_URL}/logical-switches', json=switch_data)
    print('Create Switch:', response.json())
    
    if response.status_code == 201:
        switch_id = response.json().get('name')
        
        # Get switch details
        response = requests.get(f'{BASE_URL}/logical-switches/{switch_id}')
        print('Get Switch:', response.json())
        
        # Delete switch
        response = requests.delete(f'{BASE_URL}/logical-switches/{switch_id}')
        print('Delete Switch Status:', response.status_code)

def main():
    try:
        test_health()
        test_logical_switches()
    except requests.exceptions.ConnectionError:
        print("Error: Could not connect to the backend server. Make sure it's running on port 5000")
    except Exception as e:
        print(f"Error occurred: {str(e)}")

if __name__ == '__main__':
    main()
