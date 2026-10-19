# frozen_string_literal: true

namespace :decidim_simple_proposal do
  desc "Marks Decidim core's AddDeletedAtToDecidimProposalsProposals migration " \
       "as no-op, without running it."
  task skip_decidim_deleted_at_migration: :environment do
    migrations_to_neutralize = {
      "AddDeletedAtToDecidimProposalsProposals" => "7.0"
    }

    migrations_dir = Rails.root.join("db/migrate")

    puts "Neutralizing deleted_at migration in #{migrations_dir} ..."
    puts

    migrations_to_neutralize.each do |class_name, rails_version|
      snake_name = class_name.gsub(/([a-z])([A-Z])/, '\1_\2').downcase
      files = Dir.glob(migrations_dir.join("*_#{snake_name}{,.*}.rb"))

      if files.empty?
        puts "  [SKIP] #{class_name} — not found in db/migrate/ (not yet copied?)"
        next
      end

      files.each do |file|
        content = File.read(file)

        # Already neutralized? (empty class body)
        if content.match?(/class\s+#{class_name}\s*<.*Migration.*\n\s*end/m) &&
           content.exclude?("def up")
          puts "  [OK]   #{class_name} — already a no-op"
          next
        end

        replacement = <<~RUBY
          # frozen_string_literal: true

          # Neutralized by decidim-simple_proposal.
          # "Deleted_at" already added by simple_proposal's older versions (< 0.30)
          # so this neutralization skips the unneeded migration.
          class #{class_name} < ActiveRecord::Migration[#{rails_version}]
          end
        RUBY

        File.write(file, replacement)
        puts "  [DONE] #{class_name} — neutralized (#{File.basename(file)})"
      end
    end

    puts
    puts "Done. You can now run `rails db:migrate` safely."
  end
end
