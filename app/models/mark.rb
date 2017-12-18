class Mark < ActiveRecord::Base
  attr_accessible :start_x, :start_y, :end_x, :end_y 

  belongs_to :page_version
  
  validates :start_x, :start_y, :end_x, :end_y, presence: true

  def initialize(args={})
    super(args)
  end

end
