class Bib

	include Alma

	def self.bib(mms_id)
		bib = Alma.get("/bibs/#{mms_id}?view=brief")
	end	

	def self.bibs_availability(mms_id, formats=['p','d','e'])
		xml = Alma.get("/bibs?mms_id=#{mms_id}&expand=" +
			formats.map{|x| x + '_avail'}.join(','), :xml)
		bibs = {}
		xml.xpath('/bibs/bib').each{|bib|
			bibs[bib.at_xpath('mms_id').text] =
				availability(bib.xpath('self::bib/record'))
			}
		bibs
	end

	def self.bib_availability(mms_id, formats=['p','d','e'])
		xml = Alma.get("/bibs/#{mms_id}?expand=" +
			formats.map{|x| x + '_avail'}.join(','), :xml)
		availability(xml.xpath("/bib/record"))
	end

	def self.availability(xml)
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

	def self.items(params)
		url = "/bibs/#{params[:mms_id]}/holdings/#{params[:holding_id]}/items?expand=due_date_policy&order_by=description&direction=desc&user_id=#{params[:user_id]}&limit=50"
		# Handle temporary locations
		if params[:current_location]
				url += "&current_location=#{params[:current_location]}&current_library=#{params[:current_library]}"
		end 
		Alma.get_all url
	end

	def self.request_options(params)
		opts = Alma.get "/bibs/#{params[:mms_id]}/request-options?user_id=#{params[:user_id]}"
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
