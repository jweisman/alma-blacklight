class CardController < ApplicationController
	include Alma

	def show
		@user = Alma.get "/users/#{current_user.uid}"
	end

	def fines
    @fines = Alma.get("/users/#{current_user.uid}/fees")
	end

end
