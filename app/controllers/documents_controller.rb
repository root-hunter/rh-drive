class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def query
    draw = params[:draw].to_i
    start = params[:start].to_i
    length = params[:length].to_i
    search_value = params.dig(:search, :value)
    #fields = params[:columns].map { |column| column[:name] }
    fields = ["filename", "type", "size", "created_at", "updated_at"]

    order_by = params.dig(:order, 0, :name) || 'id'
    order_direction = params.dig(:order, 0, :dir) || 'asc'

    @documents = Document.all
    total = @documents.count

    if order_by == 'id'
      @documents = @documents.order("#{order_by} #{order_direction}")
    end

    @documents = @documents.map.with_index do |document, index|
      get_metadata(document)
    end

    if search_value.present?
      @documents = @documents.select do |document|
        document[:id].to_s.downcase.include?(search_value.downcase) ||
        document[:filename].downcase.include?(search_value.downcase) ||
        document[:type].downcase.include?(search_value.downcase)
      end
    end
    total_filtered = @documents.count

    if fields.include?(order_by)
      @documents = order_documents(@documents, order_by, order_direction)
    end

    if length > 0
      @documents = @documents[start, length]
    end
 
    output = {
      draw: draw,
      recordsTotal: total,
      recordsFiltered: total_filtered,
      data: @documents
    }

    render json: output, location: @user
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
    {
      DT_RowId: "row_#{document.id}",
      id: document.id,
      filename: document.file.filename.to_s,
      type: document.file.content_type,
      size: document.file.byte_size,
      created_at: document.created_at,
      updated_at: document.updated_at,
      url: url_for(document.file)
    }
  end

  def order_documents(documents, order_by, order_direction)
    documents = @documents.sort_by do |document|
      [document[order_by.to_sym]]
    end

    if order_direction.to_s.downcase == "desc"
      documents = documents.reverse
    end

    return documents
  end
end
