ActiveAdmin.register ScreenshotSetting do
  permit_params :user_id, :interval
  actions :all, except: [:destroy, :new]
  index do
    selectable_column
    id_column
    column :interval
    actions
  end

  form do |f|
    f.inputs do
      f.input :interval, hint: "Enter time in seconds (e.g. 300)"
    end
    f.actions
  end
end
  