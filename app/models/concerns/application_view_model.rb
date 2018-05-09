class ApplicationViewModel
  delegate :params, to: :@view
  delegate :link_to, to: :@view

  def initialize(view)
    @view = view
  end  

end
