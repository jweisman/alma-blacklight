module Alma
	require 'rest-client'
	require 'json'
	require 'nokogiri'
	
# Alma API methods

	def self.get(uri, format=:json)
		response = 
		 RestClient.get ENV['almaurl'] + uri,
				accept: format, 
				authorization: 'apikey ' + ENV['apikey']
		return format==:json ? 
			JSON.parse(response.body) : Nokogiri::XML(response)
	end

	def self.get_all(uri, format=:json)
		response = nil
		offset = 0
		loop do 
			resp = self.get(uri + (uri.include?('?') ? '&' : '?') + "offset=#{offset}", format)
			if response
				response.values[0].concat resp.values[0]
			else
				response = resp
			end 
			offset = response.values[0].count
			break if response['total_record_count'] <= response.values[0].count
		end 
		response
	end
	
	def self.put(uri, data)
		response =
		 RestClient.put ENV['almaurl'] + uri,
		 	data.to_json,
			accept: :json, 
			authorization: 'apikey ' + ENV['apikey'],
			content_type: :json
		return JSON.parse(response.body)		
	end
	
	def self.post(uri, data)
		response =
		 RestClient.post ENV['almaurl'] + uri,
		 	data.to_json,
			accept: :json, 
			authorization: 'apikey ' + ENV['apikey'],
			content_type: :json
		return JSON.parse(response.body)	
	end	
	
	def self.delete(uri)
		RestClient.delete ENV['almaurl'] + uri,
			authorization: 'apikey ' + ENV['apikey']
	end	

	# Alma helper methods

	def self.get_bibs_availability(mms_id)
		xml = get("/bibs?mms_id=#{mms_id}&expand=p_avail,e_avail,d_avail", :xml)
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

	def self.get_bib(mms_id)
		bib = get("/bibs/#{mms_id}?view=brief")
		# Check if any items have a description
		bib['serial'] = 
			get("/bibs/#{mms_id}/holdings/ALL/items?q=description~*&limit=0")["total_record_count"] > 0
		bib
	end

	def self.get_bib_availability(mms_id, formats=['p','d','e'])
		xml = get("/bibs/#{mms_id}?expand=" +
			formats.map{|x| x + '_avail'}.join(','), :xml)
		bib={}
		# Format availability information as array
		['AVA','AVE','AVD'].each do |tag|
			nodes=xml.xpath("/bib/record/datafield[@tag='#{tag}']")
			bib[tag] = nodes.map{
				|node| Hash[node.xpath('subfield')
					.collect{
						|subfield| [subfield.at_xpath('@code').to_s, subfield.content]
					}]
				}
		end
		bib['online'] = 
			bib.delete('AVE')
			.each{|n| n[:link] = n['u'].gsub(/rft.mms_id=(\d*)(&|$)/, "portfolio_pid=#{n['8']}&force_direct=true&")}
			.concat(bib.delete('AVD')
				.each{|n| 
					n[:digital]=true
					n[:link] = "https://#{ENV['alma']}.alma.exlibrisgroup.com/view/delivery/#{ENV['institution']}/#{n['b']}"
					})
		bib['print']=bib.delete('AVA')
		bib
	end

	def self.get_items(params)
		get_all "/bibs/#{params[:mms_id]}/holdings/#{params[:holding_id]}/items?expand=due_date_policy&order_by=description&direction=desc&user_id=#{params[:user_id]}&limit=50"
	end

	def self.get_request_options(params)
		opts = get "/bibs/#{params[:mms_id]}/request-options?user_id=#{params[:user_id]}"
		# TODO: limit by response AND add GES
		{
		'physical': { 'desc': 'Physical Item Request',
									'url': Rails.application.routes.url_helpers.new_request_path(mms_id: params[:mms_id])
								}
		}
	end
end
