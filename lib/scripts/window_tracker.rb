# lib/scripts/window_tracker.rb
require 'fiddle'
require 'fiddle/import'
require 'time'
require 'json'

module WinAPI
  extend Fiddle::Importer
  dlload 'user32', 'kernel32'
  extern 'int GetForegroundWindow()'
  extern 'int GetWindowTextA(int, char*, int)'
end

def get_active_window_title
  hwnd = WinAPI.GetForegroundWindow()
  title = "\0" * 256
  WinAPI.GetWindowTextA(hwnd, title, 256)
  title.strip
end

# Parameters from ENV
session_id = ENV['WORK_SESSION_ID']
duration_in_minutes = ENV['DURATION'].to_i > 0 ? ENV['DURATION'].to_i : 1
output_file = "window_usage_#{session_id}.json"

window_times = {}
current_window = get_active_window_title
start_time = Time.now
end_time = Time.now + duration_in_minutes * 60

while Time.now < end_time
  sleep 1
  new_window = get_active_window_title

  if new_window != current_window
    duration = Time.now - start_time
    window_times[current_window] ||= 0
    window_times[current_window] += duration.to_i

    current_window = new_window
    start_time = Time.now
  end
end

# Finalize last window
window_times[current_window] ||= 0
window_times[current_window] += (Time.now - start_time).to_i

total_time = window_times.values.sum
percentages = window_times.transform_values { |v| ((v.to_f / total_time) * 100).round(2) }

output = window_times.map do |window, seconds|
  {
    window_title: window,
    duration: seconds,
    percentage: ((seconds.to_f / total_time) * 100).round(2)
  }
end

File.write(output_file, JSON.pretty_generate(output))
