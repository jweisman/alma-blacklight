class ItemsViewModel < ApplicationDatatable
  include Alma
  delegate :new_request_path, to: :@view

  private

  def data
    return [] if !items["item"]
    items["item"].map do |item|
      [].tap do |column|
        serial = !item["item_data"]["description"].empty?
        column << (serial ? item["item_data"]["description"] : item["item_data"]["barcode"])
        column << item["item_data"]["physical_material_type"]["desc"]
        column << item["item_data"]["due_date_policy"]
        column << (!serial ? "" : link_to('Request', new_request_path(
            mms_id: item["bib_data"]["mms_id"], 
            holding_id: item["holding_data"]["holding_id"],
            item_id: item["item_data"]["pid"]
          ), class: 'btn btn-default btn-sm'))
      end
    end
  end

  def count
    Alma.get("#{url}limit=0")["total_record_count"]
  end

  def total_entries
    items["total_record_count"]
  end

  def items
    @items ||= fetch_items
  end

  def fetch_items
    qs = "limit=#{per_page}&offset=#{page}&"
    qs += "expand=due_date_policy&user_id=#{params[:user_id]}&"
    qs += "q=description~#{params[:search][:value]}&" if !params[:search][:value].empty?
    qs += "order_by=#{sort_column}&direction=#{sort_direction}&"
    items = Alma.get(url + qs)
  end

  def url
    url = "/bibs/#{params[:mms_id]}/holdings/#{params[:holding_id]}/items?&"
    # Handle temporary locations
    if params[:current_location]
        url += "current_location=#{params[:current_location]}&current_library=#{params[:current_library]}&"
    end 
    url
  end

  def columns
    %w(description)
  end

end