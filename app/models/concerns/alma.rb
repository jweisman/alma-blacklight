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

	def self.get_bib(mms_id)
		bib = get("/bibs/#{mms_id}?view=brief")
	end	

	def self.get_bibs_availability(mms_id, formats=['p','d','e'])
		xml = get("/bibs?mms_id=#{mms_id}&expand=" +
			formats.map{|x| x + '_avail'}.join(','), :xml)
		bibs = {}
		xml.xpath('/bibs/bib').each{|bib|
			bibs[bib.at_xpath('mms_id').text] =
				bib_availability(bib.xpath('self::bib/record'))
			}
		bibs
	end

	def self.get_bib_availability(mms_id, formats=['p','d','e'])
		xml = get("/bibs/#{mms_id}?expand=" +
			formats.map{|x| x + '_avail'}.join(','), :xml)
		bib_availability(xml.xpath("/bib/record"))
	end

	def self.bib_availability(xml)
		bib = { mms_id: xml.at_xpath("self::record/controlfield[@tag='001']").text }
		# Format availability information as array
		['AVA','AVE','AVD'].each do |tag|
			nodes=xml.xpath("self::record/datafield[@tag='#{tag}']")
			bib[tag] = nodes.map{
				|node| Hash[node.xpath('subfield')
					.collect{
						|subfield| [subfield.at_xpath('@code').to_s, subfield.content]
					}]
				}
		end
		bib[:online] = bib.delete('AVE')
			.each{|n| n[:link] = n['u'].gsub(/rft.mms_id=(\d*)(&|$)/, "portfolio_pid=#{n['8']}&force_direct=true&")}
			.concat(bib.delete('AVD')
				.each{|n| 
					n[:digital]=true
					n[:link] = "https://#{ENV['alma']}.alma.exlibrisgroup.com/view/delivery/#{ENV['institution']}/#{n['b']}"
					})
		bib[:print] = bib.delete('AVA')
			.each{|n| n[:items_url] = "/almaws/bibs/#{bib[:mms_id]}/holdings" + 
				(n['8'] ? "/#{n['8']}/items" : "/ALL/items?current_library=#{n['b']}&current_location=#{n['j']}")}
		# Determine if serial by looking for a holding summary in AVA $$t or $$h
		# Alternatively look for an item with a description:
		# /bibs/#{mms_id}/holdings/ALL/items?q=description~*&limit=0
		bib[:serial]=bib[:print].any? {|n| ['t', 'h'].any? {|s| n.key? s} }
		bib		
	end

	def self.get_items(params)
		url = "/bibs/#{params[:mms_id]}/holdings/#{params[:holding_id]}/items?expand=due_date_policy&order_by=description&direction=desc&user_id=#{params[:user_id]}&limit=50"
		# Handle temporary locations
		if params[:current_location]
				url += "&current_location=#{params[:current_location]}&current_library=#{params[:current_library]}"
		end 
		get_all url
	end

	def self.get_request_options(params)
		opts = get "/bibs/#{params[:mms_id]}/request-options?user_id=#{params[:user_id]}"
		# API should return an empty array if no requests are available
		if opts["request_option"]
			opts["request_option"]
				.select{|o| ["HOLD", "GES"].include? o["type"]["value"]}
				.each{|o| o["link"] = 
					Rails.application.routes.url_helpers.new_request_path(mms_id: params[:mms_id], type: o["type"]["value"]) if !o["link"]}
		else
			[]
		end
	end
end
