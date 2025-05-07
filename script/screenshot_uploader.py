import os
import datetime
import time
import sys
import json
import signal
import atexit
import subprocess
import tempfile
import random
import pyautogui
import tempfile
import requests
import mss
import mss.tools
# Get user_id from command line arguments
user_id = sys.argv[1] if len(sys.argv) > 1 else "unknown"
interval = int(sys.argv[2]) if len(sys.argv) > 2 else 300
# Configure screenshot directory with more efficient path
SCREENSHOT_DIR = os.path.join("public", "screenshots", f"user_{user_id}")
os.makedirs(SCREENSHOT_DIR, exist_ok=True)
 
# Status file path
STATUS_FILE = os.path.join(tempfile.gettempdir(), f"screenshot_status_{user_id}.json")
DB_COMMAND_DIR = os.path.join(tempfile.gettempdir(), "screenshot_commands")

os.makedirs(DB_COMMAND_DIR, exist_ok=True)
 
# Save PID to status file on startup
def save_status(active=True):
    status = {
        "pid": os.getpid(),
        "active": active,
        "last_update": datetime.datetime.now().isoformat()
    }
    with open(STATUS_FILE, 'w') as f:
        json.dump(status, f)
 
# Check if we should be active
def should_be_active():
    try:
        if os.path.exists(STATUS_FILE):
            with open(STATUS_FILE, 'r') as f:
                status = json.load(f)
                return status.get("active", False)
        return False
    except Exception as e:
        print(f"Error reading status file: {e}")
        return False
 
def take_screenshot():
    timestamp = datetime.datetime.now().strftime("%Y%m%d_%H%M%S")
    filename = f"screenshot_{user_id}_{timestamp}.png"
    file_path = os.path.join(SCREENSHOT_DIR, filename)

    with mss.mss() as sct:
        monitor = sct.monitors[1]  # [1] is usually the primary monitor
        sct_img = sct.grab(monitor)
        mss.tools.to_png(sct_img.rgb, sct_img.size, output=file_path)

    print(f"Screenshot saved: {file_path}")
    notify_rails(file_path, timestamp)
    return file_path

def notify_rails(file_path, timestamp):
    url = "http://localhost:3000/screenshots/create_from_python"
    data = {
        "user_id": user_id,
        "file_path": file_path,
        "created_at": timestamp
    }
    try:
        response = requests.post(url, json=data)
        print("Rails response:", response.status_code, response.text)
    except Exception as e:
        print("Error notifying Rails:", e)

# Create a command file for Rails to process - more efficient with temp files
def create_command_file(file_path, timestamp):
    command_data = {
        "action": "create_screenshot",
        "user_id": user_id,
        "file_path": file_path,
        "created_at": datetime.datetime.now().isoformat()
    }
    
    # Use a temporary file to ensure atomic writes
    with tempfile.NamedTemporaryFile(mode='w', delete=False, dir=DB_COMMAND_DIR,
                                     prefix=f"cmd_{user_id}_", suffix=".json") as f:
        json.dump(command_data, f)
        temp_name = f.name
    
    # Rename to final name - this is an atomic operation on most systems
    final_name = os.path.join(DB_COMMAND_DIR, f"cmd_{user_id}_{timestamp}_{random.randint(1000, 9999)}.json")
    os.rename(temp_name, final_name)
    
    print(f"Command file created: {final_name}")
 
# Clean up function
def cleanup():
    print(f"Screenshot capture for user {user_id} stopped")
    if os.path.exists(STATUS_FILE):
        try:
            os.remove(STATUS_FILE)
        except:
            pass
 
# Register cleanup function
atexit.register(cleanup)
 
# Handle termination signals
def handle_signal(sig, frame):
    print(f"Received signal {sig}, exiting...")
    sys.exit(0)
 
signal.signal(signal.SIGTERM, handle_signal)
signal.signal(signal.SIGINT, handle_signal)
 
# Initial status
save_status(True)
print(f"Screenshot capture started for user {user_id}")
 
# Keep track of the last processing time
last_screenshot_time = 0  # Set to 0 to ensure immediate screenshot
 
# Main loop with adaptive timing
while True:
    now = time.time()
    
    # Check if we should take a screenshot
    if should_be_active():
        # Take a screenshot immediately if this is the first time or interval has passed
        if last_screenshot_time == 0 or (now - last_screenshot_time >= interval):
            take_screenshot()
            last_screenshot_time = now
    
    # Update status every minute
    if int(now) % 60 == 0:
        save_status(should_be_active())
    
    # Sleep for a shorter time to be more responsive
    time.sleep(5)
 