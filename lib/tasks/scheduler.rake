require 'rest-client'
require 'nokogiri'

desc "Harvest OAI set 'blacklight' and index in Solr"
task :harvest_oai => :environment do

	oai_set = 'blacklight'

	log "Starting..."
	log "Retrieving 'from' time"

	from_time = ''
	from_time = "&from=#{PropertyBag.get('oai_time')}" if PropertyBag.get('oai_time')

	# set to date
	to_time = Time.new.getutc.strftime("%Y-%m-%dT%H:%M:%SZ")
	log "Set 'to' time to: #{to_time}"

	qs = "?verb=ListRecords&set=#{oai_set}&metadataPrefix=marc21&until=#{to_time}#{from_time}"

	begin 
		resumptionToken = process_oai(ENV["institution"], qs, ENV["alma"])
		puts "resumption token is nil? #{resumptionToken.nil?}"
		puts "resumption token is empty? #{resumptionToken == ''}"
		qs = '?verb=ListRecords&resumptionToken=' + resumptionToken
	end until resumptionToken == ''

	# write to date for next time
	log "Storing 'to' time"
	PropertyBag.set('oai_time', to_time)

	log "Complete"
end

task :set_property, [:name, :val] => :environment do |t, args|
	PropertyBag.set(args[:name], args[:val])
end

task :get_property, [:name] => :environment do |t, args|
	puts PropertyBag.get(args[:name])
end



def process_oai(inst, qs, alma)
	oai_base = "https://#{alma}.alma.exlibrisgroup.com/view/oai/#{inst}/request"

	log "Calling OAI with query string #{qs}"
	oai = RestClient.get oai_base + qs

	document = Nokogiri::XML(oai)

	recordCount = document.xpath('/oai:OAI-PMH/oai:ListRecords/oai:record', {'oai' => 'http://www.openarchives.org/OAI/2.0/'}).count
	log "#{recordCount} records retrieved"

	resumptionToken =	document.xpath('/oai:OAI-PMH/oai:ListRecords/oai:resumptionToken', {'oai' => 'http://www.openarchives.org/OAI/2.0/'}).text
	File.open('oai-resumption.txt', 'a') { |f| f.write(resumptionToken + "\n") }

	if recordCount > 0
		filename = File.join(Rails.root.join('tmp'), resumptionToken || 'last') + ".xml"
		File.open(filename, "w+") do |f|
  		f.write(oai)
		end
		log "File written. Indexing #{filename}."
		sh "java -Dsolr.hosturl=#{ENV['SOLR_URL']} -jar #{File.dirname(__FILE__)}/solrmarc/SolrMarc.jar #{File.dirname(__FILE__)}/solrmarc/config.properties #{filename}"
		File.delete filename
	end
	resumptionToken
end

def log(msg)
	time = Time.new
	time = time.strftime("%Y-%m-%d %H:%M:%S")
	puts "#{time} - #{msg}"
	true
end

