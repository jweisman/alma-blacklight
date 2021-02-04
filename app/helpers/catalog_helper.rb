module CatalogHelper
  include Blacklight::CatalogHelperBehavior

	def render_availability(document = @document)
		render :partial => 'show_availability', :locals => {:document => document}
	end

	def openurl(mms_id, service='viewit')
		url = openurl_base + "&u.ignore_date_coverage=true&rft.mms_id=#{mms_id}" 
		url
	end

end
