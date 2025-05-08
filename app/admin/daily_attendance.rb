ActiveAdmin.register_page "Daily Attendance" do
    content title: proc { ("Daily Attendance") } do
        div class: "filter_section" do
            form action: admin_daily_attendance_path, method: :get do
              div style: "display: inline-block; margin-right: 15px;" do
                label "Employee", for: "employee_id", style: "display: block;"
                select name: "employee_id", id: "employee_id", style: "min-width: 150px;" do
                  option value: "all", selected: params[:employee_id].blank? || params[:employee_id] == "all" || params[:employee_id] == "All Employees" do
                    "All Employees"
                  end
                  User.all.each do |user|
                    option value: user.id, selected: params[:employee_id].to_s == user.id.to_s do
                      user.username
                    end
                  end
                end
              end
 
              div style: "display: inline-block; margin-right: 15px;" do
                label "Date", for: "date", style: "display: block;"
                input type: "date", id: "date", name: "date",
                      value: params[:date] || Date.today.strftime("%Y-%m-%d"),
                      style: "min-width: 150px;"
              end
 
              div style: "display: inline-block; margin-top: 24px;" do
                input type: "submit", value: "Filter", class: "button"
              end
            end
          end
 
          selected_date = if params[:date].present?
            begin
              Date.parse(params[:date])
            rescue ArgumentError
              Date.today
            end
          else
            Date.today
          end
 
          Rails.logger.debug "Selected Date: #{selected_date}"
 
          filtered_users = if params[:employee_id].present? && params[:employee_id] != "all" && params[:employee_id] != "All Employees"
            User.where(id: params[:employee_id])
          else
            User.all
          end
        columns do
            table_for filtered_users do
                column "Employee Name" do |user|
                  link_to(user.username, admin_user_path(user))
                end
                column "Date" do |user|
                  selected_date.strftime("%d %b %Y")
                end
 
                column "Clock-In" do |user|
                    latest_session = user.work_sessions.where(
                      "DATE(clock_in) = ?", selected_date
                    ).first
                   
                    if latest_session&.clock_in
                      latest_session.clock_in.strftime('%H:%M:%S %p')
                    else
                      "Not clocked in"
                    end
                end
 
                column "Clock-Out" do |user|
                    work_session = user.work_sessions.where(
                      "DATE(clock_in) = ?", selected_date
                    ).last
                   
                    if work_session&.clock_out
                        work_session.clock_out.strftime('%H:%M:%S %p')
                    elsif work_session&.clock_in
                        "Working On"
                    else
                        "Not available"
                    end
                end
                column "Duration" do |user|
                    work_session = user.work_sessions.where(
                      "DATE(clock_in) = ?", selected_date
                    ).last
 
                    if work_session&.clock_in && work_session&.clock_out
                      total_hours = work_session.calculate_total_hours
                      hours = total_hours.to_i
                      minutes = ((total_hours - hours) * 60).round
 
                      "#{hours}h #{minutes}m"
                    elsif work_session&.clock_in
                      current_time = Time.current
                     
                      temp_session = work_session.dup
                      temp_session.clock_out = current_time
 
                      total_hours = temp_session.calculate_total_hours
                      hours = total_hours.to_i
                      minutes = ((total_hours - hours) * 60).round
 
                      "#{hours}h #{minutes}m"
                    else
                      "N/A"
                    end
                end
            end
        end
    end
end
 