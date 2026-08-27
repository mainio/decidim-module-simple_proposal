# frozen_string_literal: true

class TransferDeletedAtToMergedAtToProposals < ActiveRecord::Migration[7.0]
  def up
    return unless column_exists?(:decidim_proposals_proposals, :deleted_at)

    execute <<~SQL.squish
      UPDATE decidim_proposals_proposals
      SET merged_at = deleted_at
      WHERE deleted_at IS NOT NULL
    SQL

    remove_index :decidim_proposals_proposals, :deleted_at if index_exists?(:decidim_proposals_proposals, :deleted_at)
    remove_column :decidim_proposals_proposals, :deleted_at
  end

  def down
    # This migration "gives space" to Decidim's "deleted_at" -attribute by
    # transferring this module's "deleted_at"'s values to a new attribute "merged_at".
    # The data transfer and column removal are irreversible: there is no way of
    # reconstructing the original "deleted_at" column and values so rolling back
    # is not allowed.
    say "No-op: Rolling this migration back is not allowed."
  end
end
