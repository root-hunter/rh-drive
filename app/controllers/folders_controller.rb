class FoldersController < ApplicationController
    before_action :authenticate_user!
    
    def index
        @folders = current_user.folders
    end

    def new
        @folder = Folder.new
        @users = User.all
    end

    def create
        @folder = Folder.new(folder_params)
        @user_id = current_user.id if user_signed_in?

        @folder.user_id = @user_id
    
        respond_to do |format|
          if @folder.save
            format.html { redirect_to @folder, notice: 'Folder was successfully created.' }
            format.js   {}
            format.json { render json: @folde/r, status: :created, location: @user }
          else
            format.html { render action: "new" }
            format.json { render json: @folder.errors, status: :unprocessable_entity }
          end
        end
    end

    def show
    end

    private

    def folder_params
        params.require(:folder).permit(:path)
    end
end
