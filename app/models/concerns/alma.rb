module Alma
	require 'rest-client'
	require 'json'
	require 'nokogiri'
	
# Alma API methods

	def alma_api_get(uri)
		response = 
		 RestClient.get ENV['almaurl'] + uri,
				accept: :json, 
				authorization: 'apikey ' + ENV['apikey']
		return JSON.parse(response.body)
	end
	
	def alma_api_put(uri, data)
		response =
		 RestClient.put ENV['almaurl'] + uri,
		 	data.to_json,
			accept: :json, 
			authorization: 'apikey ' + ENV['apikey'],
			content_type: :json
		return JSON.parse(response.body)		
	end
	
	def alma_api_post(uri, data)
		response =
		 RestClient.post ENV['almaurl'] + uri,
		 	data.to_json,
			accept: :json, 
			authorization: 'apikey ' + ENV['apikey'],
			content_type: :json
		return JSON.parse(response.body)	
	end	
	
	def alma_api_delete(uri)
		RestClient.delete ENV['almaurl'] + uri,
			authorization: 'apikey ' + ENV['apikey']
	end	

	# Alma helper methods

	def alma_get_bibs_availability(mms_id)
		response = 
		RestClient.get ENV['almaurl'] + 
			"/bibs?mms_id=#{mms_id}&expand=p_avail,e_avail,d_avail",
			authorization: 'apikey ' + ENV['apikey']

		xml = Nokogiri::XML(response)
		bibs = {}
		bib_nodes = xml.xpath('/bibs/bib')
		bib_nodes.each do |bib_node|
			print = bib_node.at_xpath('record/datafield[@tag="AVA"]/subfield[@code="e"]')
			digital = bib_node.at_xpath('record/datafield[@tag="AVD"]')
			electronic = bib_node.at_xpath('record/datafield[@tag="AVE"]')

			bibs[bib_node.at_xpath('mms_id').text] = 
				{ :physical => 
					{ 	:exists => print ? true : false,
						:available => print && print.text == 'available' ? true : false
					},
				   :online   => 
					{ :exists => digital || electronic ? true : false }
				}
		end

		return bibs
	end
end
