ActiveAdmin.register Screenshot , namespace: :super_admin do
    menu label: 'Capture Times'
    permit_params :user_id
end