ActiveAdmin.register Screenshot do
  # Remove create and edit actions
  actions :all, except: [:new, :edit]
  
  # Add better filters
  filter :user, collection: proc { User.all.map { |u| [u.username, u.id] } }
  filter :created_at
  
  # Add scoped filters for quick date filtering
  scope :all, default: true
  scope :today do |screenshots|
    screenshots.where("created_at >= ?", Date.today)
  end
  scope :yesterday do |screenshots|
    screenshots.where(created_at: Date.yesterday.beginning_of_day..Date.yesterday.end_of_day)
  end
  scope :this_week do |screenshots|
    screenshots.where("created_at >= ?", Date.today.beginning_of_week)
  end
  
  # Optimize controller to improve performance
  controller do
    def scoped_collection
      # Only load necessary columns for index view
      super.includes(:user)
    end
  end
  
  # Customize index page with better performance
  index do
    selectable_column
    id_column
    column :user
    column :created_at
    column "Screenshot" do |screenshot|
      if screenshot.file_path.present? && File.exist?(screenshot.file_path)
        # Convert backslashes to forward slashes
        normalized_path = screenshot.file_path.tr('\\', '/')
        # Remove everything before and including "public/"
        image_path = normalized_path.sub(%r{.*public/}, '/')
    
        div style: "text-align: center" do
          image_tag image_path, style: "max-width: 150px; max-height: 100px; cursor: pointer;",
                    onclick: "window.open('#{image_path}', '_blank')"
        end
      else
        "File not found"
      end
    end
    actions defaults: false do |screenshot|
      item "View", admin_screenshot_path(screenshot), class: "member_link"
      item "Delete", admin_screenshot_path(screenshot), class: "member_link",
           method: :delete, data: { confirm: "Are you sure you want to delete this?" }
    end
  end
  
  
  # Customize show page
  show do
    attributes_table do
      row :id
      row :user
      row :created_at
      row :updated_at
      row :file_path
      row "Screenshot" do |screenshot|
        if screenshot.file_path.present? && File.exist?(screenshot.file_path)
          normalized_path = screenshot.file_path.tr('\\', '/')
          # Remove everything before and including "public/"
          image_path = normalized_path.sub(%r{.*public/}, '/')
          div style: "text-align: center" do
            image_tag image_path, style: "max-width: 150px; max-height: 100px; cursor: pointer;",
                      onclick: "window.open('#{image_path}', '_blank')"
          end
        else
          "File not found"
        end
      end
    end
    active_admin_comments
  end
  
  # Custom CSV download with necessary fields
  csv do
    column :id
    column :user do |screenshot|
      screenshot.user ? screenshot.user.username : "No User"
    end
    column :created_at
    column :file_path
  end
  
  # Define batch actions (only for deletion)
  batch_action :destroy, confirm: "Are you sure you want to delete these screenshots?" do |ids|
    batch_action_collection.find(ids).each do |screenshot|
      # Optionally delete the actual file too
      File.delete(screenshot.file_path) if File.exist?(screenshot.file_path)
      screenshot.destroy
    end
    redirect_to collection_path, notice: "Screenshots have been deleted"
  end
end
