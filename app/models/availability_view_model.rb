class AvailabilityViewModel
	include Alma
	delegate :params, to: :@view
	delegate :almaws_items_path, to: :@view

	MMS_ID_XPATH = "controlfield[@tag='001']"
	ONLINE_XPATH = "datafield[@tag='AVE' or @tag='AVD']"
	PRINT_XPATH = "datafield[@tag='AVA']"
	PRINT_AVAILABLE_XPATH = PRINT_XPATH + "/subfield[@code='e' and text()='available']"
	SERIAL_XPATH = PRINT_XPATH + "/subfield[@code='t' or @code='h']"

	def initialize(view)
		@view = view
	end	

	def as_json(options = {})
		{}.tap do |avail|
			bibs.each{|bib|
				avail[bib.at_xpath(MMS_ID_XPATH).text] =
					{
						online: bib.xpath(ONLINE_XPATH).map{|n| online_avail n},
						print: bib.xpath(PRINT_XPATH).map{|n| print_avail n},
						print_available: bib.xpath(PRINT_AVAILABLE_XPATH).count > 0,
						serial: bib.xpath(SERIAL_XPATH).count > 0
					}
			}
		end
	end

	private

	def bibs
		@bibs ||= fetch_bibs
	end

	def fetch_bibs
		url = "/bibs?mms_id=#{params[:mms_ids]}&expand=p_avail,e_avail,d_avail"
		bibs = Alma.get(url, :xml)
		bibs.xpath('/bibs/bib/record')
	end	

	def online_avail(node)
		[].tap do |column|
			digital = node.xpath("@tag").text == "AVD"

			column << (digital ? 'Digital' : 'Electronic')
			column << (digital ? get_subfield(node, 'e') : get_subfield(node, 'm')) 
			column << '<span class="glyphicon glyphicon-dot glyphicon-green"></span> ' + 
				(get_subfield(node, 's').presence || 'Available')
			column << "<a class='btn btn-default btn-sm' href='#{online_link(node, digital)}' target='_new'>View online</a>"
		end
	end

	def print_avail(node)
		[].tap do |column|
      copies = get_subfield(node, 'f').to_i || 0
      unavailable = get_subfield(node, 'g').to_i || 0;
			color = copies - unavailable > 0 ? 'green' : 'grey'

			column << get_subfield(node, 'c') + " - " + get_subfield(node, 'q')
			column << "<span class='glyphicon glyphicon-dot glyphicon-#{color}'></span> " +
				(get_subfield(node, 't').presence || get_subfield(node, 'h').presence ||
				"Copies: #{copies}, Available: #{copies-unavailable}")
			column << get_subfield(node, 'd')
			column << "<button data-url='#{items_url(node)}' class='btn btn-default btn-sm items'>Details</button>"				
		end
	end

	def get_subfield(node, subfield)
		node.xpath("subfield[@code='#{subfield}']").text
	end

	def online_link(node, digital)
		if digital
			"https://#{ENV['alma']}.alma.exlibrisgroup.com/view/delivery/#{ENV['institution']}/#{get_subfield(node, 'b')}"
		else
			get_subfield(node, 'u').gsub(/rft.mms_id=(\d*)(&|$)/, "portfolio_pid=#{get_subfield(node, '8')}&force_direct=true&")
		end
	end

	def items_url(node)
		params = { 
			mms_id: node.xpath('../' + MMS_ID_XPATH).text, 
			holding_id: get_subfield(node, '8').presence || 'ALL'
		}
		if !get_subfield(node, '8').present?
			params.merge!( { current_library: get_subfield(node, 'b'),
				current_location: get_subfield(node, 'j') })
		end
		almaws_items_path(params)
	end
end
