require 'csv'
require 'json_csv'

class Accounts::PipelinesController < InternalController
  before_action :set_pipeline, only: %i[ show edit update destroy ]

  # GET /pipelines or /pipelines.json
  def index
    redirect_to(account_pipeline_path(current_user.account, current_user.account.pipelines.first))
  end

  # GET /pipelines/1 or /pipelines/1.json
  def show
    @pipelines = current_user.account.pipelines
  end

  # GET /pipelines/new
  def new
    @pipeline = Pipeline.new
  end

  # GET /pipelines/1/edit
  def edit
  end

  # POST /pipelines/1/import_file
  def import_file

    uploaded_io = params[:import_file]

    csv_text = uploaded_io.read
    csv = CSV.parse(csv_text, headers: true)

    path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
    line = 0
    CSV.open(path_to_output_csv_file, "w") do |csv_output|
      
      csv.each do |row|
        if line == 0
          csv_output << row.to_h.keys + ['result']
        end

        row_json = JsonCsv.csv_row_hash_to_hierarchical_json_hash(row, {})

        row_params = ActionController::Parameters.new(row_json)

        deal = current_user.account.deals.new(deal_params(row_params))

        if deal.save
          csv_output << row.to_h.values + ["Criado com sucesso id #{deal.id}"]
        else
          csv_output << row.to_h.values + ["Erro na criação #{deal.errors.messages}"]
        end
        line += 1
      end
    end


    response.headers['Content-Type'] = 'text/csv'
    response.headers['Content-Disposition'] = "attachment; filename=deals.csv"
    send_file path_to_output_csv_file
  end

  # GET /pipelines/1/import
  def import
    respond_to do |format|
      format.html
      format.csv do
        path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
        headers = Deal.csv_header(current_user.account)
        CSV.open(path_to_output_csv_file, "w") do |csv|
          csv << headers
        end

        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=deals.csv"
        render file: path_to_output_csv_file
      end
    end
  end

  # GET /pipelines/1/export
  def export
    @deals = current_user.account.deals.where(stage_id: params['stage_id'])
    
    path_to_output_csv_file = "#{Rails.root}/tmp/deals-#{Time.current.to_i}.csv"
    JsonCsv.create_csv_for_json_records(path_to_output_csv_file) do |csv_builder|
      @deals.each do | deal |
        json = JSON.parse(deal.to_json(:include => :contacts))
        csv_builder.add(json)
      end
    end


    respond_to do |format|
      format.html
      format.csv do
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = "attachment; filename=deals.csv"
        render file: path_to_output_csv_file
      end
    end
  end

  def bulk_action
  end

  def bulk_action_2
  end

  # POST /pipelines or /pipelines.json
  def create
    @pipeline = Pipeline.new(pipeline_params)

    respond_to do |format|
      if @pipeline.save
        format.html { redirect_to account_pipeline_path(current_user.account, @pipeline), notice: "Pipeline was successfully created." }
        format.json { render :show, status: :created, location: @pipeline }
      else
        format.html { render :new, status: :unprocessable_entity }
        format.json { render json: @pipeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /pipelines/1 or /pipelines/1.json
  def update
    respond_to do |format|
      if @pipeline.update(pipeline_params)
        format.html { redirect_to @pipeline, notice: "Pipeline was successfully updated." }
        format.json { render :show, status: :ok, location: @pipeline }
      else
        format.html { render :edit, status: :unprocessable_entity }
        format.json { render json: @pipeline.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /pipelines/1 or /pipelines/1.json
  def destroy
    @pipeline.destroy
    respond_to do |format|
      format.html { redirect_to pipelines_url, notice: "Pipeline was successfully destroyed." }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_pipeline
      @pipeline = Pipeline.find(params[:id])
    end

    # Only allow a list of trusted parameters through.
    def pipeline_params
      params.require(:pipeline).permit(:name, stages_attributes: [:id, :name, :_destroy])
    end

    def deal_params(params)
      params.permit(
        :name, :status, :stage_id, :contact_id,
        contact_attributes: [ :id, :full_name, :phone, :email, :account_id ],
        custom_attributes: {}
      )
    end
end