class CardController < ApplicationController
	include Alma
	before_action :require_valid_user

	def show
		@user = Alma.get "/users/#{current_user.uid}"
	end

	def fines
    @fines = Alma.get("/users/#{current_user.uid}/fees")
	end

end
