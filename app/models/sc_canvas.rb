class ScCanvas < ActiveRecord::Base
  belongs_to :sc_manifest
  belongs_to :page
  
  
  def thumbnail_url
    if sc_service_context ==  "http://iiif.io/api/image/1/context.json"
      "#{sc_service_id}/full/100,/0/native.jpg"          
    else
      "#{sc_service_id}/full/100,/0/default.jpg"      
    end
  end

  def facsimile_url
    "#{sc_service_id}/full/full/0/default.jpg"
  end
end
