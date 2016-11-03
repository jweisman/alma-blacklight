require 'rest-client'
require 'nokogiri'

desc "Harvest OAI set 'blacklight' and index in Solr"
task :oai_harvest => :environment do

	oai_set = 'blacklight'

	log "Starting..."

	from_time = PropertyBag.get('oai_time')
	log "Set 'from' time to: #{from_time}"
	from_time = "&from=#{from_time}" if from_time

	# set to date
	to_time = Time.new.getutc.strftime("%Y-%m-%dT%H:%M:%SZ")
	log "Set 'to' time to: #{to_time}"

	# recover
	saved_resumption_token = PropertyBag.get('oai_resumption_token')

	if saved_resumption_token.to_s != ''
		qs = "?verb=ListRecords&resumptionToken=#{saved_resumption_token}"
	else
		qs = "?verb=ListRecords&set=#{oai_set}&metadataPrefix=marc21&until=#{to_time}#{from_time}"
	end

	begin 
		resumptionToken = process_oai(ENV["institution"], qs, ENV["alma"])
		qs = "?verb=ListRecords&resumptionToken=#{resumptionToken}"
		PropertyBag.set('oai_resumption_token', resumptionToken)
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

	# Handle deleted records
	deletedRecords = document.xpath('/oai:OAI-PMH/oai:ListRecords/oai:record[oai:header/@status="deleted"]', {'oai' => 'http://www.openarchives.org/OAI/2.0/'})
	log "Found #{deletedRecords.count} deleted records."

	if deletedRecords.count > 0
		deletedIds = 
			deletedRecords.map{ |n| n.at('header/identifier').text.split(':').last }

		deletedRecords.remove
		puts RestClient.post "#{ENV['SOLR_URL']}/update?commit=true", 
			"<delete><id>#{deletedIds.join('</id><id>')}</id></delete>", 
			:content_type => :xml 
	end

	# Index remaining records
	recordCount = document.xpath('/oai:OAI-PMH/oai:ListRecords/oai:record', {'oai' => 'http://www.openarchives.org/OAI/2.0/'}).count
	log "#{recordCount} records retrieved"

	resumptionToken =	document.xpath('/oai:OAI-PMH/oai:ListRecords/oai:resumptionToken', {'oai' => 'http://www.openarchives.org/OAI/2.0/'}).text

	if recordCount > 0
		template = Nokogiri::XSLT(oai_to_marc)
		filename = File.join(Rails.root.join('tmp'), resumptionToken || 'last') + ".xml"
		File.open(filename, "w+") do |f|
  		f.write(template.transform(document).to_s)
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

def oai_to_marc
	%q(
	<?xml version="1.0"?>
		<xsl:stylesheet version="1.0"
		xmlns:xsl="http://www.w3.org/1999/XSL/Transform"
		xmlns:oai="http://www.openarchives.org/OAI/2.0/"
		xmlns:marc="http://www.loc.gov/MARC21/slim">
			<xsl:template match="/">
				<collection>
				<xsl:for-each select="oai:OAI-PMH/oai:ListRecords/oai:record">
					<xsl:copy-of select="oai:metadata/marc:record"/>
				</xsl:for-each>
			</collection>
		</xsl:template>
		</xsl:stylesheet>
	)
end