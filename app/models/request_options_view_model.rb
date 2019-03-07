class RequestOptionsViewModel < ApplicationViewModel
  include Alma

  def as_json(options = {})
    request_options["request_option"]
      .select{|o| request_types.include? o["type"]["value"]}
      .map{|o| 
        {}.tap do |obj|
          type = o["type"]["value"]
          obj["type"] = type
          case type
          when "GES"
            obj["link"] = o["request_url"]
            obj["desc"] = o["general_electronic_service_details"]["public_name"]
          when "RS_BROKER"
            obj["link"] = o["request_url"]
            obj["desc"] = o["rs_broker_details"]["name"]
          else
            obj["link"] = 
              Rails.application.routes.url_helpers
              .new_request_path(mms_id: params[:mms_id], type: type)
            obj["desc"] = o["type"]["desc"] + ' Request'
          end
        end
      }
  end

  private

  def request_options
    @request_options ||= fetch_request_options
  end

  def fetch_request_options
    Alma.get "/bibs/#{params[:mms_id]}/request-options?user_id=#{params[:user_id]}&consider_dlf=true"
  end 

  def request_types 
    # Supported request types
    ["HOLD", "DIGITIZATION", "GES", "RS_BROKER"]
  end  

end