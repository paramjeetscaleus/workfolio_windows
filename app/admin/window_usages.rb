ActiveAdmin.register WindowUsage do
    permit_params :work_session_id, :window_title, :duration, :percentage
  
    index do
      selectable_column
      id_column
      column :work_session
      column :window_title
      column ("duration (%)") { |usage| "#{usage.duration} sec" }
      column("Percentage (%)") { |usage| "#{usage.percentage} %" }
      column :created_at
      actions
    end
  
    filter :work_session
    filter :window_title
    filter :created_at
  
    show do
      attributes_table do
        row :id
        row :work_session
        row :window_title
        row :duration
        row("Percentage (%)") { |usage| "#{usage.percentage} %" }
        row :created_at
        row :updated_at
      end
    end
  end
  