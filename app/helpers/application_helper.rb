module ApplicationHelper

	def openurl_base
		"https://#{ENV['alma']}.alma.exlibrisgroup.com/view/uresolver/#{ENV['institution']}/openurl?"
	end
end
