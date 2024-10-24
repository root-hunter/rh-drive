class Users::RegistrationsController < Devise::RegistrationsController
    def create
      super do |resource|
        if resource.persisted?  # Check if the user was saved successfully
            @folder = Folder.new
            user_id = resource.id

            @folder.path = "/"
            @folder.user_id = user_id

            @folder.save()
        end
      end
    end
  end