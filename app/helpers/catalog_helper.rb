module CatalogHelper
  include Blacklight::CatalogHelperBehavior

	def render_availability(document = @document)
		render :partial => 'show_availability', :locals => {:document => document}
	end


	def openurl(mms_id, service='viewit')
		url = "https://#{ENV['alma']}.alma.exlibrisgroup.com/view/uresolver/#{ENV['institution']}/openurl?rfr_id=info:sid/primo.exlibrisgroup.com&u.ignore_date_coverage=true&svc_dat=#{service}&rft.mms_id=#{mms_id}" 
		url += "&sso=true&token=#{session.id}" if current_user && current_user.provider=='saml'
		url += "&oauth=true&provider=#{current_user.provider.downcase}" if current_user && ["FACEBOOK", "GOOGLE"].include?(current_user.provider)
		url
	end

end
