class ApplicationDatatable
  delegate :params, to: :@view
  delegate :link_to, to: :@view

  def initialize(view)
    @view = view
  end

  def as_json(options = {})
    {
      recordsTotal: total_entries,
      recordsFiltered: count,
      data: data
    }
  end

  private

  def page
    params[:start] || 0
  end

  def per_page
    params[:length].to_i > 0 ? params[:length].to_i : 5
  end

  def sort_column
    columns[params[:order]['0'][:column].to_i] 
  end

  def sort_direction
    params[:order]['0'][:dir] == "desc" ? "desc" : "asc" 
  end
end