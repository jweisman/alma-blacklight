class ArticlesController < ApplicationController
	require 'summon' 

	PAGE_SIZE=10

	def index
		service = Summon::Service.new(
			:access_id => ENV['SUMMON_ACCESS_ID'], 
			:secret_key => ENV['SUMMON_SECRET_KEY']
		)
		search = service.search({
	    "s.fvf"   => "ContentType,Journal Article,f",
	    "s.q"     => params['q'],
	    "s.ps"    => PAGE_SIZE,
	    "s.pn"    => params['page']
	  })
		@docs = Kaminari.paginate_array(
			search.documents, 
			offset: (params['page'].to_i-1)*PAGE_SIZE, 
			limit: PAGE_SIZE, 
			total_count: search.record_count
		)
	end
end