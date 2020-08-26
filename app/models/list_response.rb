class ListResponse
attr_accessor :items, :totalItems, :itemsPerPage, :currentPage

  def initialize(objects)
    @items=objects
    @totalItems=objects.total_entries
    @itemsPerPage=objects.per_page
    @currentPage=objects.current_page
  end   
end  