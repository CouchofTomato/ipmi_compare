class CostShare < ApplicationRecord
  belongs_to :scope, polymorphic: true
end
