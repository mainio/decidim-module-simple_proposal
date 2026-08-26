# frozen_string_literal: true

class AddMergedAtToProposals < ActiveRecord::Migration[7.0]
  def change
    add_column :decidim_proposals_proposals, :merged_at, :datetime
    add_index :decidim_proposals_proposals, :merged_at
  end
end
