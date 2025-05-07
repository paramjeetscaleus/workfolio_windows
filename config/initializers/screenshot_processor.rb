require 'rufus-scheduler'

# Only run in server processes, not in console, rake tasks, etc.
if defined?(Rails::Server) || ENV['ENABLE_SCHEDULER'] == 'true'
  # Create scheduler with a lightweight configuration
  scheduler = Rufus::Scheduler.new(thread_pool_size: 2)
  
  # Set a flag to avoid processing during server reload
  $processing_screenshots = false
  
  # Process screenshot commands every 30 seconds
  # Instead of using 'every', use 'interval' which skips if previous is still running
  scheduler.interval '30s' do
    # Skip if we're already processing
    unless $processing_screenshots
      begin
        $processing_screenshots = true
        
        command_dir = "/tmp/screenshot_commands"
        if Dir.exist?(command_dir)
          # Limit the number of files processed in one batch
          command_files = Dir.glob(File.join(command_dir, "cmd_*.json")).first(20)
          
          if command_files.any?
            Rails.logger.info "Processing #{command_files.size} screenshot commands..."
            
            # Process files in batch to reduce database connections
            screenshots_to_create = []
            
            command_files.each do |file_path|
              begin
                command_data = JSON.parse(File.read(file_path))
                
                if command_data["action"] == "create_screenshot" && command_data["user_id"].present?
                  screenshots_to_create << {
                    user_id: command_data["user_id"],
                    file_path: command_data["file_path"],
                    created_at: command_data["created_at"]
                  }
                end
                
                # Delete the command file after reading
                File.delete(file_path)
              rescue => e
                Rails.logger.error "Error processing #{file_path}: #{e.message}"
                # Try to delete problematic files to prevent endless retries
                File.delete(file_path) rescue nil
              end
            end
            
            # Bulk insert if we have screenshots to create
            if screenshots_to_create.any?
              # Use bulk import if available, otherwise fall back to individual creates
              if Screenshot.respond_to?(:import)
                Screenshot.import screenshots_to_create
                Rails.logger.info "Bulk imported #{screenshots_to_create.size} screenshots"
              else
                # Create in batches to reduce database load
                Screenshot.transaction do
                  screenshots_to_create.each do |screenshot_data|
                    Screenshot.create!(screenshot_data)
                  end
                end
                Rails.logger.info "Created #{screenshots_to_create.size} screenshots"
              end
            end
          end
        end
      rescue => e
        Rails.logger.error "Error in screenshot processor: #{e.message}"
      ensure
        $processing_screenshots = false
      end
    end
  end
  
  Rails.logger.info "Screenshot processor initialized"
end