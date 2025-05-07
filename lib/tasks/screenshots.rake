namespace :screenshots do
  desc "Process pending screenshot commands"
  task process: :environment do
    command_dir = "/tmp/screenshot_commands"
    return unless Dir.exist?(command_dir)
    
    puts "Looking for screenshot commands..."
    
    # Process each command file
    Dir.glob(File.join(command_dir, "cmd_*.json")).each do |file_path|
      begin
        puts "Processing #{file_path}"
        command_data = JSON.parse(File.read(file_path))
        
        if command_data["action"] == "create_screenshot"
          user = User.find_by(id: command_data["user_id"])
          
          if user
            # Create screenshot record - simplified without work_session and during_break
            screenshot = Screenshot.new(
              user: user,
              file_path: command_data["file_path"],
              created_at: command_data["created_at"]
            )
            
            if screenshot.save
              puts "Screenshot saved to database: #{command_data["file_path"]}"
            else
              puts "Error saving screenshot: #{screenshot.errors.full_messages.join(", ")}"
            end
          else
            puts "User not found: #{command_data["user_id"]}"
          end
        end
        
        # Delete the command file after processing
        File.delete(file_path)
      rescue => e
        puts "Error processing #{file_path}: #{e.message}"
      end
    end
  end
end
