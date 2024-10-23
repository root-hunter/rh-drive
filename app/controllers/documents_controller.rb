class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def index
    if params[:draw].present?
      @draw = params[:draw].to_i
    else
      @draw = 0
    end

    if params[:start].present?
      @start = params[:start].to_i
    else
      @start = 0
    end

    if params[:length].present?
      @length = params[:length].to_i
    else
      @length = 0
    end

    @documents = Document.all
    total = @documents.count
    documents = @documents.offset(@start).limit(@length)

    respond_to do |format|
      if @documents
        format.html { render action: "index" }
        format.js   {}
        format.json { render json: documents_metadata(@draw, documents, total), location: @user }
      else
        format.html { render action: "index" }
        format.json { render json: documents.errors, status: :unprocessable_entity }
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
        format.json { render json: get_metadata(@document), location: @user }
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

  def get_metadata(document)
    [
      document.id,
      document.file.filename.to_s,
      document.file.content_type,
      document.file.byte_size,
      document.created_at,
      document.updated_at,
      url_for(document.file)
    ]
  end

  def documents_metadata(draw, documents, total)
    {
      draw: draw,
      recordsTotal: total,
      recordsFiltered: total,
      data: documents.map do |document|
        get_metadata(document)
      end
    }
  end
end
