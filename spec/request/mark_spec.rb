require "rails_helper"
require 'json'

RSpec.describe "MarkController", type: :request do
	before do
    @user = FactoryBot.create(:user)
    @collection = FactoryBot.create(:collection)
    @work = FactoryBot.create(:work)
    @page = FactoryBot.create(:page)

  end
  it 'create a Mark' do
	   	puts "-------------------CREATE-------------------"
	    post '/api/mark?auth_token='+@user.authentication_token.to_s+'&locale=es',{"text":"mark test","coordinates":{"x":23,"y":34},"shape_type":"polyline","text_type":"body","page_id":42}
	    json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
	end


end
