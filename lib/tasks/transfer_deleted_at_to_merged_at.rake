# frozen_string_literal: true

namespace :decidim_simple_proposal do
  desc "Transfers this module's legacy 'deleted_at' values on proposals into " \
       "'merged_at'. After this resets 'deleted_at' fields to nil for all proposals " \
       "so the column behaves as if Decidim core's own."
  task transfer_deleted_at_to_merged_at: :environment do
    connection = ActiveRecord::Base.connection
    table = :decidim_proposals_proposals

    unless connection.column_exists?(table, :deleted_at)
      puts "[decidim_simple_proposal] `deleted_at` does not exist on #{table}." \
           "Nothing to do."
      next
    end

    unless connection.column_exists?(table, :merged_at)
      puts "[decidim_simple_proposal] `merged_at` does not exist on #{table} yet." \
           "Run this module's migrations first."
      next
    end

    proposal_class = Class.new(ApplicationRecord) do
      self.table_name = table
      self.inheritance_column = nil
    end

    scope = proposal_class.where.not(deleted_at: nil)
    count = scope.count

    if count.zero?
      puts "[decidim_simple_proposal] No proposals have `deleted_at` set. Nothing to transfer."
    else
      # rubocop:disable Rails/SkipsModelValidations
      updated = scope.update_all("merged_at = deleted_at")
      # rubocop:enable Rails/SkipsModelValidations

      puts "[decidim_simple_proposal] Transferred `deleted_at` to `merged_at` for" \
           "#{updated} proposal(s)."
    end

    # rubocop:disable Rails/SkipsModelValidations
    reset = proposal_class.where.not(deleted_at: nil).update_all(deleted_at: nil)
    # rubocop:enable Rails/SkipsModelValidations

    puts "[decidim_simple_proposal] Reset `deleted_at` to nil for #{reset} proposal(s), " \
         "so the column now behaves as freshly added by Decidim core."
  end
end
