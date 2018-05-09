class Card::RequestsController < ApplicationController
  include Alma
  before_action :require_valid_user

	def index
  	@requests = Alma.get("/users/#{current_user.uid}/requests")
  end	

  def new
    @bib = Alma.get("/bibs/#{params[:mms_id]}?view=brief")
    @libraries = libraries.map{|x| [x['name'], x['code']]}.sort
    @digi_departments = digi_departments.map{|d| [d['name'], d['code']]}.sort
  end

  def create
    url = "/bibs/#{params[:mms_id]}"
    if !params[:item_id].blank?
      url += "/holdings/#{params[:holding_id]}/items/#{params[:item_id]}"
    end 
  	begin
	  	Alma.post url + "/requests?user_id=#{current_user.uid}",
        params.slice(:request_type, :pickup_location_type, 
          :pickup_location_library, :comment, :target_destination, 
          :partial_digitization)
			redirect_to requests_path, notice: "Your request was successfully created."
    rescue Exception => e
    	redirect_to requests_path, alert: e.message
    end	
  end

  def destroy
  	Alma.delete("/users/#{current_user.uid}/requests/#{params['id']}")
  	redirect_to requests_path, notice: "Your request was successfully cancelled."
  end

  private

  def libraries
    $libraries ||= Alma.get("/conf/libraries")['library']
  end

  def digi_departments
    $digi_departments ||= Alma.get("/conf/departments?type=DIGI")['department']
  end

end
