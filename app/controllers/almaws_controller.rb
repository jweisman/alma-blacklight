class AlmawsController < ApplicationController
  include Alma

  before_action do
    params.merge!(user_id: current_user.uid) if current_user 
  end

  def availability
    render json: AvailabilityViewModel.new(view_context)
  end

  def items
    render json: ItemsViewModel.new(view_context)
  end

  def request_options
    render json: RequestOptionsViewModel.new(view_context)
  end
end
