# frozen_string_literal: true

class AddDeletedAtToProposals < ActiveRecord::Migration[6.0]
  def change
    add_column :decidim_proposals_proposals, :deleted_at, :datetime, index: true
  end
end
