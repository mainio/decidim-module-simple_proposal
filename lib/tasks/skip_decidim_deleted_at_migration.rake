# frozen_string_literal: true

namespace :decidim_simple_proposal do
  desc "Marks Decidim core's AddDeletedAtToDecidimProposalsProposals migration " \
       "as already applied, without running it."
  task skip_decidim_deleted_at_migration: :environment do
    context = ActiveRecord::MigrationContext.new(ActiveRecord::Migrator.migrations_paths)

    migration = context.migrations.find { |m| m.name == "AddDeletedAtToDecidimProposalsProposals" }

    if migration.nil?
      puts "[decidim_simple_proposal] Could not find AddDeletedAtToDecidimProposalsProposals " \
           "among loaded migrations. Has decidim-proposals' migrations been installed?"
      next
    end

    if context.get_all_versions.include?(migration.version)
      puts "[decidim_simple_proposal] Migration #{migration.version} " \
           "(AddDeletedAtToDecidimProposalsProposals) is already marked as applied. " \
           "Nothing to do."
      next
    end

    connection = ActiveRecord::Base.connection

    connection.execute(
      "INSERT INTO schema_migrations (version) VALUES (#{connection.quote(migration.version)})"
    )

    puts "[decidim_simple_proposal] Marked migration #{migration.version} " \
         "(AddDeletedAtToDecidimProposalsProposals) as applied without running it."

    if connection.column_exists?(:decidim_proposals_proposals, :deleted_at)
      remaining = ActiveRecord::Base.connection.select_value(
        "SELECT COUNT(*) FROM decidim_proposals_proposals WHERE deleted_at IS NOT NULL"
      ).to_i

      if remaining.positive?
        puts "[decidim_simple_proposal] REMINDER: #{remaining} proposal(s) still have " \
             "legacy `deleted_at` values. Run decidim_simple_proposal:transfer_deleted_at_to_merged_at " \
             "to migrate them into `merged_at`."
      end
    end
  end
end
