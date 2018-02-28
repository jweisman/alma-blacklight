class AlmawsController < ApplicationController
  include Alma

  before_action do
    params.merge!(user_id: current_user.uid) if current_user 
  end

  def availability
    render json: AvailabilityViewModel.new(view_context)
  end

  def items
    render json: ItemsViewModel.new(view_context)
  end

  def request_options
    opts = Alma.get "/bibs/#{params[:mms_id]}/request-options?user_id=#{params[:user_id]}"
    # API should return an empty array if no requests are available
    render json: (opts["request_option"] || [])
      .select{|o| ["HOLD", "GES"].include? o["type"]["value"]}
      .each{|o| o["link"] = 
        Rails.application.routes.url_helpers.new_request_path(mms_id: params[:mms_id], type: o["type"]["value"]) if !o["link"]}
  end

  def requests
    render json: Alma.get("/bibs/#{params[:mms_id]}/requests")
  end
end
