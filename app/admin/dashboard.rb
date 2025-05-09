# frozen_string_literal: true
ActiveAdmin.register_page "Dashboard" do
  menu priority: 1, label: proc { I18n.t("active_admin.dashboard") }

  content title: proc { I18n.t("active_admin.dashboard") } do
    # div class: "blank_slate_container", id: "dashboard_default_message" do
    #   span class: "blank_slate" do
    #     span I18n.t("active_admin.dashboard_welcome.welcome")
    #     small I18n.t("active_admin.dashboard_welcome.call_to_action")
    #   end
    # end

    columns do
      column do
        panel "Total Team Member" do
          div style: "font-size: 24px; font-weight: bold; text-align: center; padding: 20px;" do
            User.count
          end
        end

        panel "Currently Working" do
          div style: "font-size: 24px; font-weight: bold; text-align: center; padding: 20px;" do
            WorkSession.where.not(clock_in: nil).where(clock_out: nil).select(:user_id).distinct.count
          end
        end
        
        panel "Currently On Break" do
          div style: "font-size: 20px; font-weight: bold; text-align: center; padding: 15px;" do
            on_break_count = WorkSession.where.not(break_start: nil).where(break_end: nil).select(:user_id).distinct.count
            on_break_count > 0 ? "#{on_break_count}" : "No user on break"
          end
        end
        
        panel "Currently Stopped Work" do
          div style: "font-size: 20px; font-weight: bold; text-align: center; padding: 15px;" do
            WorkSession.where.not(clock_out: nil).select(:user_id).distinct.count
          end
        end        
      end
    end
  end 
end
