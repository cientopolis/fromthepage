require "rails_helper"
require 'json'

RSpec.describe "publicationController", type: :request do

  before do
    @user = FactoryGirl.create(:user)
    @publication = FactoryGirl.create(:publication)
    @foro = FactoryGirl.create(:foro)

  end

  it 'creates a publication' do
    puts "-----------------CREATE-------------------"
      #previous_length = Collection.count
      puts @foro.to_json
      post '/api/publication?auth_token='+@user.authentication_token.to_s+'&locale=es',{text:"text",foro:{"id":1,"user_id":"null","element_id":"null","element_type":"null","created_at":"2018-06-03T22:25:42.103Z","updated_at":"2018-06-03T22:25:42.103Z"}}
      json = JSON.parse(response.body)
      puts json['message'];
      expect(json['status']).to eq("OK")
  end



  it 'deletes a publication' do
  	puts "--------------DELETE----------------------"
  	delete '/api/publication?id='+@publication.id.to_s+'&auth_token='+@user.authentication_token.to_s+'&locale=es'
  	json = JSON.parse(response.body)
  	puts json['message']
    expect(json['status']).to eq("OK")
  end

end
