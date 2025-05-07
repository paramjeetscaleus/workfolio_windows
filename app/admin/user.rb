ActiveAdmin.register User do
  permit_params :email, :username, :password, :password_confirmation
  
  index do
    selectable_column
    id_column
    column :email
    column :username
    column :created_at
    column "Total Screenshots" do |user|
      user.screenshots.count
    end
    column "Actions" do |user|
      link_to "View Screenshots", admin_screenshots_path(q: {user_id_eq: user.id}), class: "member_link"
    end
    actions
  end
  
  filter :email
  filter :username
  filter :created_at
  
  form do |f|
    f.inputs do
      f.input :email
      f.input :username
      f.input :password
      f.input :password_confirmation
    end
    f.actions
  end
end
