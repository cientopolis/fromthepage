class Layer < ActiveRecord::Base
  belongs_to :page

  after_create :insert_semantic_register

  def insert_semantic_register
    SemanticHelper.insert(self.to_jsonld)
  end

  def to_jsonld
    jsonld_hash = {
      :@context => SemanticHelper.get_prefixes,
      :@id => "transcriptor:layer-#{self.id}",
      :@type => "transcriptor:Layer",
      :"rdfs:label" => self.name,
      :"transcriptor:belongsToPage" => {
        :@id => "transcriptor:page-#{self.page.id}"
      }
    }.to_json
  end

end
