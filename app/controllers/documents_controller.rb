class DocumentsController < ApplicationController
  before_action :authenticate_user!

  def index
  end

  def query
    draw = params[:draw].to_i
    start = params[:start].to_i
    length = params[:length].to_i
    search_value = params.dig(:search, :value)

    orderable_columns = %w[null id filename type size created_at updated_at]

    order_column_index = params.dig(:order, 0, :column).to_i
    order_direction = params.dig(:order, 0, :dir) || 'asc' # Default to 'asc' if no direction is provided
    order_by = orderable_columns[order_column_index] || 'id' # Default to 'id' if out of bounds

    @documents = Document.all
    total = @documents.count

    if search_value.present?
      @tmp = @documents.where("id LIKE ?", "%#{search_value}%")

      if @tmp.length > 0
        @documents = @tmp
      end
    end

    @documents = @documents.order("#{order_by} #{order_direction}")
    @documents = @documents.offset(start).limit(length)
    @documents = @documents.map.with_index do |document, index|
      get_metadata(document, index)
    end

    if search_value.present?
      @documents = @documents.select do |document|
        document[:filename].downcase.include?(search_value.downcase)  # Case-insensitive match
      end
    end

    total_filtered = @documents.count

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

  def get_metadata(document, index)
    {
      DT_RowId: "row_#{index}",
      id: document.id,
      filename: document.file.filename.to_s,
      type: document.file.content_type,
      size: document.file.byte_size,
      created_at: document.created_at,
      updated_at: document.updated_at,
      url: url_for(document.file)
    }
  end

  def documents_metadata(draw, documents, total, total_filtered)
    {
      draw: draw,
      recordsTotal: total,
      recordsFiltered: total_filtered,
      data: documents.map.with_index do |document, index|
        get_metadata(document, index)
      end
    }
  end
end
