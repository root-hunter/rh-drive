class Folder < ApplicationRecord
    attribute :path, :string
    has_many :documents
    belongs_to :user
end
