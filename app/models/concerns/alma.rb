module Alma
	require 'rest-client'
	require 'json'
	require 'nokogiri'
	
# Alma API methods

	def self.get(uri, format=:json)
		puts uri
		execute :get, uri, nil, format
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
		execute :put, uri, data
	end
	
	def self.post(uri, data)
		execute :post, uri, data
	end	
	
	def self.delete(uri)
		RestClient.delete url(uri),
			authorization: auth
	end	

	def self.execute(method, uri, payload=nil, content_type=:json)
		headers = { 
			authorization: auth,
			content_type: content_type,
			accept: content_type
		}

		begin
			response = RestClient::Request.execute(
				method: method,
				url: url(uri),
				payload: content_type==:json ? payload.to_json : payload,
				headers: headers
				)
			content_type==:json ? 
				JSON.parse(response.body) : Nokogiri::XML(response.body)
		rescue RestClient::ExceptionWithResponse => e
			if content_type == :json
				msg = JSON.parse(e.response.body)['errorList']['error'][0]["errorMessage"]
			else
				msg = Nokogiri::XML(response.body).at_xpath('/web_service_result/errorList/error/errorMessage')
			end
			raise msg
		end
	end

	private

	def self.url(uri)
		ENV['almaurl'] + uri
	end

	def self.auth
		'apikey ' + ENV['apikey']
	end
end
