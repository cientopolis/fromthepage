class MarkQuery < Query
  base_query Mark.all

  def add_page_version_id_filter(value)
    query.where(page_version_id:value)
  end

end
