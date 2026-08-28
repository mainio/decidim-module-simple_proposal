# Decidim::SimpleProposal

[![Build Status](https://github.com/mainio/decidim-module-simple_proposal/actions/workflows/ci_simple_proposal.yml/badge.svg)](https://github.com/mainio/decidim-module-simple_proposal/actions)
[![codecov](https://codecov.io/gh/mainio/decidim-module-simple_proposal/branch/master/graph/badge.svg)](https://codecov.io/gh/mainio/decidim-module-simple_proposal)

** THIS MODULE OVERRIDES CORE FUNCTIONALITY OF DECIDIM-PROPOSALS AND CAN CAUSE UNEXPECTED SIDE EFFECTS! DO NOT USE IF YOU DONT KNOW FOR SURE WHAT YOU ARE DOING! **

** SINCE 0.30 THERE ARE NEW CHANGES TO DATABASE ATTRIBUTES **

Decidim 0.30 adds its own "deleted_at" -attribute that was used in this module as an indicator
attribute for when proposals were merged. Instead of deleting the merged proposals we added this attribute.(*You can read this down below in **0.25** chapter*)

For this reason a new attribute is added called 'merged_at' which replaces the
legacy version of 'deleted_at' and let's decidim use the version 0.30 'deleted_at'
the way it was intended.

A rake task *transfer_deleted_at_to_merged_at* was added to this module which will
transfer the deleted_at -values to the new merged_at -attribute and nillify deleted_at
columns that had values in them.

**CAUTION**

----------------------

You need to run another rake task before running migrations called *skip_decidim_deleted_at_migration*. This will mark decidim 0.30's upcoming "AddDeletedAtToDecidimProposalsProposal" as processed so it skips migrating it. If you don't run this rake task your migrations will fail because decidim will try to add
a deleted_at column to a table that already exists.

If you install decidim's migrations first and you get the error you can still run this task and it will skip the migration, just remember to always install simple_proposals migrations too -> "merged_at" and run the rake task above to transfer the deleted_at data to the correct column.

----------------------

If your decidim instance is already 0.30 or newer when you install this module
you can just install this module's migration for "merged_at" and forget about the
rake task since this version (0.30) removes the "deleted_at" migration from this module.

** Step by Step **

If you just updated versions to 0.30 and didn't yet install/run migrations:

1. run bin/rails decidim_simple_proposal:install:migrations (Install merged_at)
2. run bin/rails decidim_simple_proposal:transfer_deleted_at_to_merged_at
   (Transfer merge data)
3. run bin/rails decidim:upgrade (Install decidim migrations)
4. run bin/rails decidim_simple_proposal:skip_decidim_deleted_at_migration
   (Skip decidim migration for deleted_at)
5. run bin/rails db:migrate

If you already installed decidim 0.30's migrations:

1. run bin/rails decidim_simple_proposal:skip_decidim_deleted_at_migration
   (Skip decidim migration for deleted_at)
2. run bin/rails decidim_simple_proposal:install:migrations (Install merged_at)
3. run bin/rails decidim_simple_proposal:transfer_deleted_at_to_merged_at
   (Transfer merge data)
4. run bin/rails db:migrate

This can be done even after if you get an error for trying to run the decidim migrations
without running the rake tasks.

If you are installing this module to an instance that has no history with it and is
Decidim version 0.30+:

1. run bin/rails decidim_simple_proposal:install:migrations (Install merged_at)
2. run bin/rails db:migrate

****

** SINCE 0.25 THERE ARE NEW CHANGES AND FEATURES **

- Admin can merge split and merge proposals even if proposals aren't official. Also merging adds authors, comments and combines bodies from existing proposals.
- By default decidim destroys proposals after merge, we don't want to do it so we added deleted_at column to proposals
- Translations:
```
Proposal -> Idea
Accepted -> Proceeds to voting
Rejected -> Does not proceed to voting
```

A [Decidim](https://github.com/decidim/decidim) module that provides a simplified proposal creation.

****

## Installation

Add this line to your application's Gemfile:

```ruby
gem "decidim-simple_proposal"
```

And then execute:

```bash
$ bundle
$ bundle exec rake decidim_simple_proposal:install:migrationsz
$ bundle exec rails db:migrate
```

## Configuration


```ruby
# config/initializers/simple_proposal.rb

Decidim::SimpleProposal.configure do |config|
  config.require_scope = true # Default
end
```

## Contributing

See [Decidim](https://github.com/decidim/decidim).

### Developing

To start contributing to this project, first:

- Install the basic dependencies (such as Ruby and PostgreSQL)
- Clone this repository

Decidim's main repository also provides a Docker configuration file if you
prefer to use Docker instead of installing the dependencies locally on your
machine.

You can create the development app by running the following commands after
cloning this project:

```bash
$ bundle
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake development_app
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

Then to test how the module works in Decidim, start the development server:

```bash
$ cd development_app
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rails s
```

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add the environment variables to the root directory of the project in a file
named `.rbenv-vars`. If these are defined for the environment, you can omit
defining these in the commands shown above.

#### Code Styling

Please follow the code styling defined by the different linters that ensure we
are all talking with the same language collaborating on the same project. This
project is set to follow the same rules that Decidim itself follows.

[Rubocop](https://rubocop.readthedocs.io/) linter is used for the Ruby language.

You can run the code styling checks by running the following commands from the
console:

```
$ bundle exec rubocop
```

To ease up following the style guide, you should install the plugin to your
favorite editor, such as:

- Atom - [linter-rubocop](https://atom.io/packages/linter-rubocop)
- Sublime Text - [Sublime RuboCop](https://github.com/pderichs/sublime_rubocop)
- Visual Studio Code - [Rubocop for Visual Studio Code](https://github.com/misogi/vscode-ruby-rubocop)

### Testing

To run the tests run the following in the gem development path:

```bash
$ bundle
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rake test_app
$ DATABASE_USERNAME=<username> DATABASE_PASSWORD=<password> bundle exec rspec
```

Note that the database user has to have rights to create and drop a database in
order to create the dummy test app database.

In case you are using [rbenv](https://github.com/rbenv/rbenv) and have the
[rbenv-vars](https://github.com/rbenv/rbenv-vars) plugin installed for it, you
can add these environment variables to the root directory of the project in a
file named `.rbenv-vars`. In this case, you can omit defining these in the
commands shown above.

### Test code coverage

If you want to generate the code coverage report for the tests, you can use
the `SIMPLECOV=1` environment variable in the rspec command as follows:

```bash
$ SIMPLECOV=1 bundle exec rspec
```

This will generate a folder named `coverage` in the project root which contains
the code coverage report.

### Localization

If you would like to see this module in your own language, you can help with its
translation at Crowdin:

https://crowdin.com/project/decidim-access-requests

## License

See [LICENSE-AGPLv3.txt](LICENSE-AGPLv3.txt).
