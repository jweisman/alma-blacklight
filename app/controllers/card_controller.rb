class CardController < ApplicationController
	include Alma

	def show
		@user = Alma.get "/users/#{current_user.uid}"
	end

	def fines
    @fines = Alma.get("/users/#{current_user.uid}/fees")
	end

	def requests
  	@requests = Alma.get("/users/#{current_user.uid}/requests")
  end

end