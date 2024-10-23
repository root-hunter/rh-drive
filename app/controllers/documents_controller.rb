class DocumentsController < ApplicationController
  def index
    if params[:page].present?
      @documents = Document.page(params[:page]).per(10)
    else
      @documents = Document.all
    end

    respond_to do |format|
      if @documents
        format.html { render action: "index" }
        format.js   {}
        format.json { render json: document_metadata(@documents), location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @documents.errors, status: :unprocessable_entity }
      end
    end
  
  end

  def home
    index
  end

  def new
    @document = Document.new
  end

  def show
    @document = Document.find(params[:id])

    respond_to do |format|
      if @document.save
        format.html { render action: "show" }
        format.js   {}
        format.json { render json: @document, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  def create
    @document = Document.new(document_params)

    respond_to do |format|
      if @document.save
        format.html { redirect_to @document, notice: 'Document was successfully created.' }
        format.js   {}
        format.json { render json: @document, status: :created, location: @user }
      else
        format.html { render action: "new" }
        format.json { render json: @document.errors, status: :unprocessable_entity }
      end
    end
  end

  private

  def document_params
    params.require(:document).permit(:file)
  end

  def document_metadata(documents)
    documents.map do |document|
      {
        id: document.id,
        filename: document.file.filename.to_s,
        content_type: document.file.content_type,
        byte_size: document.file.byte_size,
        created_at: document.created_at,
        updated_at: document.updated_at,
        url: url_for(document.file)  # Generates a URL for the file
      }
    end
  end
end
