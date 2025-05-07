import time
import json
import os
import sys
import win32gui
print(win32gui.GetWindowText(win32gui.GetForegroundWindow()))
def get_active_window_title():
    try:
        window = win32gui.GetForegroundWindow()
        title = win32gui.GetWindowText(window)
        return title if title else "Unknown"
    except Exception as e:
        return "Unknown"

def normalize_title(title):
    if "Google Chrome" in title:
        return "Google Chrome"
    elif "Visual Studio Code" in title or "VS Code" in title:
        return "VS Code"
    elif "File Explorer" in title or "This PC" in title:
        return "File Manager"
    elif "Notepad" in title:
        return "Notepad"
    elif "Command Prompt" in title or "cmd.exe" in title:
        return "Command Prompt"
    elif "Windows Security" in title:
        return "Windows Security"
    elif "PowerShell" in title:
        return "PowerShell"
    else:
        return title

def track_window_usage(duration_in_minutes, output_file_path):
    usage_data = {}
    current_title = normalize_title(get_active_window_title())
    start_time = time.time()
    last_switch_time = start_time

    while True:
        time.sleep(1)  # Sample every second
        new_title = normalize_title(get_active_window_title())

        current_time = time.time()
        if new_title != current_title:
            duration = int(current_time - last_switch_time)
            usage_data[current_title] = usage_data.get(current_title, 0) + duration
            current_title = new_title
            last_switch_time = current_time

        # Stop after specified time
        if (current_time - start_time) > (duration_in_minutes * 60):
            duration = int(current_time - last_switch_time)
            usage_data[current_title] = usage_data.get(current_title, 0) + duration
            break

    with open(output_file_path, 'w') as f:
        json.dump(usage_data, f)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python track_windows.py <duration_in_minutes> <output_file_path>")
        sys.exit(1)

    duration_in_minutes = int(sys.argv[1])
    output_file_path = sys.argv[2]

    track_window_usage(duration_in_minutes, output_file_path)
