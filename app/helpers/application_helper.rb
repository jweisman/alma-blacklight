module ApplicationHelper

	def openurl_base
		"https://#{ENV['alma']}.alma.exlibrisgroup.com/discovery/openurl?institution=#{ENV['institution']}&vid=#{ENV['vid'] || ENV['institution'] + ':DEFAULT'}"
	end
end
