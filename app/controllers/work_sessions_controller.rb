require 'tmpdir'

class WorkSessionsController < ApplicationController
  before_action :authenticate_user!
  skip_before_action :verify_authenticity_token, only: [:clock_in, :clock_out, :start_break, :end_break]

  # def clock_in
  #   @work_session = current_user.work_sessions.create(clock_in: Time.current.in_time_zone("Asia/Kolkata"))
  #   flash[:notice] = "Clocked in successfully!"
  #   start_screenshot_capture(current_user.id)
  #   redirect_to work_session_index_path
  # end

  def clock_in
    @work_session = current_user.work_sessions.create(clock_in: Time.current.in_time_zone("Asia/Kolkata"))
    flash[:notice] = "Clocked in successfully!"
    
    # Start the screenshot capture process
    start_screenshot_capture(current_user.id)
    
    # Take an immediate screenshot
    take_immediate_screenshot(current_user.id)
    run_window_tracking_script(current_user.id)
    # run_window_tracker_and_save(@work_session.id)
    redirect_to work_session_index_path
  end
  

  def start_break
    @work_session = current_user.work_sessions.last
    if @work_session && @work_session.clock_in
      # Reset break_end to allow for multiple breaks
      @work_session.update(break_start: Time.current, break_end: nil)
      flash[:notice] = "Break started!"
      # @work_session.update(break_start: nil)
      pause_screenshot_capture(current_user.id)
    else
      flash[:alert] = "You need to clock in first."
    end
    redirect_to work_session_index_path
  end

  def end_break
    @work_session = current_user.work_sessions.last
    if @work_session && @work_session.break_start && @work_session.break_end.nil?
      @work_session.update(break_end: Time.current)
      flash[:notice] = "Break ended!"
      resume_screenshot_capture(current_user.id)
      @work_session.update(break_start: nil)
      # run_window_tracking_script(current_user.id)
    else
      flash[:alert] = "You need to start a break first."
    end
    redirect_to work_session_index_path
  end

  def clock_out
    @work_session = current_user.work_sessions.last
    if @work_session && @work_session.clock_in && @work_session.clock_out.nil?
      @work_session.update(clock_out: Time.current, total_hours: @work_session.calculate_total_hours)
      flash[:notice] = "Clocked out successfully!"
      stop_screenshot_capture(current_user.id)
    else
      flash[:alert] = "You need to clock in first."
    end
    redirect_to work_session_index_path
  end

  def index
    @work_sessions = current_user.work_sessions.order(created_at: :desc)
  end

  def user_work_session_report
    @user = User.find(params[:id])
    @work_sessions = @user.work_sessions.group_by { |ws| ws.clock_in.to_date }
  end

  private

  def run_window_tracker_and_save(work_session_id)
    script_path = Rails.root.join('lib', 'scripts', 'window_tracker.rb')
    duration = 1 # in minutes
    output_file = Rails.root.join("window_usage_#{work_session_id}.json")

    system({ "WORK_SESSION_ID" => work_session_id.to_s, "DURATION" => duration.to_s },
           "ruby #{script_path}")

    if File.exist?(output_file)
      data = JSON.parse(File.read(output_file))

      data.each do |entry|
        WindowUsage.create!(
          work_session_id: work_session_id,
          window_title: entry["window_title"],
          duration: entry["duration"],
          percentage: entry["percentage"]
        )
      end
      # debugger
      File.delete(output_file)
    else
      Rails.logger.warn("Window usage output file not found: #{output_file}")
    end
  end

  def start_screenshot_capture(user_id)
    # Kill any existing process first to avoid duplicates
    stop_screenshot_capture(user_id)
    interval = ScreenshotSetting.last.interval
    # Start a new process
    script_path = "C:/Users/Dell/Downloads/workfolio_copy/workfolio_copy/script/screenshot_uploader.py"

    pid = spawn("python3 #{script_path} #{user_id} #{interval}")
    Process.detach(pid)
    
    # Create status file indicating active status
    status_file = File.join(Dir.tmpdir, "screenshot_status_#{user_id}.json")
    
    # Wait briefly for the Python script to create its own status file
    sleep(1)
    
    # If the script hasn't created the file yet, create it ourselves
    unless File.exist?(status_file)
      File.write(status_file, JSON.generate({ active: true, pid: pid }))
    end
  end

  def take_immediate_screenshot(user_id)
    # Create the screenshot directory if it doesn't exist
    screenshot_dir = File.join(Rails.root, "public", "screenshots", "user_#{user_id}")
    FileUtils.mkdir_p(screenshot_dir)
    
    # Generate a filename
    timestamp = Time.current.strftime("%Y%m%d_%H%M%S")
    filename = "screenshot_#{user_id}_#{timestamp}.png"
    file_path = File.join(screenshot_dir, filename)
    
    # Take the screenshot
    system("import -window root -quality 80 #{file_path}")
    
    # Create a command file
    command_data = {
      "action": "create_screenshot",
      "user_id": user_id,
      "file_path": file_path,
      "created_at": Time.current.iso8601
    }
    
    # Path for direct database commands
    cmd_dir = "/tmp/screenshot_commands"
    FileUtils.mkdir_p(cmd_dir)
    
    # Create a unique command file
    cmd_filename = "cmd_#{user_id}_#{timestamp}_#{rand(1000..9999)}.json"
    cmd_file_path = File.join(cmd_dir, cmd_filename)
    
    # Write the command data
    File.write(cmd_file_path, command_data.to_json)
    
    Rails.logger.info "Immediate screenshot taken and saved to #{file_path}"
  rescue => e
    Rails.logger.error "Failed to take immediate screenshot: #{e.message}"
  end
  
  def pause_screenshot_capture(user_id)
    status_file = File.join(Dir.tmpdir, "screenshot_status_#{user_id}.json")
    if File.exist?(status_file)
      # Read current status to preserve PID
      current_status = JSON.parse(File.read(status_file)) rescue {}
      # Update to inactive
      current_status["active"] = false
      current_status["last_update"] = Time.current.iso8601
      File.write(status_file, JSON.generate(current_status))
    end
  end
  
  def resume_screenshot_capture(user_id)
    status_file = File.join(Dir.tmpdir, "screenshot_status_#{user_id}.json")
    if File.exist?(status_file)
      # Read current status to preserve PID
      current_status = JSON.parse(File.read(status_file)) rescue {}
      # Update to active
      current_status["active"] = true
      current_status["last_update"] = Time.current.iso8601
      File.write(status_file, JSON.generate(current_status))
    else
      # If no status file exists, restart the process
      start_screenshot_capture(user_id)
    end
  end

  def run_window_tracking_script(user_id, duration_in_minutes = 5)
    python_script_path = Rails.root.join('lib', 'tracking', 'track_windows.py')
    output_path = Rails.root.join('tmp', "window_tracking_output_#{user_id}.json")
  
    system("python #{python_script_path} #{duration_in_minutes} #{output_path}")
  end
  
  
  def stop_screenshot_capture(user_id)
    status_file = File.join(Dir.tmpdir, "screenshot_status_#{user_id}.json")
    
    if File.exist?(status_file)
      begin
        # Try to get PID from status file
        status = JSON.parse(File.read(status_file))
        pid = status["pid"]
        
        # Terminate process if PID exists
        if pid
          # Send SIGTERM signal
          Process.kill("TERM", pid.to_i) rescue nil
        end
      rescue
        # Fallback: try to find process by pattern matching
        system("pkill -f 'python3.*screenshot_uploader\.py.*#{user_id}'")
      end
      
      # Remove status file
      File.delete(status_file) rescue nil
    else
      # Fallback: try to find process by pattern matching
      system("pkill -f 'python3.*screenshot_uploader\.py.*#{user_id}'")
    end
  end
end