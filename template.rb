# Overwrites Thor to use relative file paths (Not sure if needed)

def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

# initialize git

git :init
git add: '.', commit: '-m "Initial Commit"'

# Clean slate Gemfile and default gems

remove_file "Gemfile"
run "touch Gemfile"

add_source 'https://rubygems.org'
gem 'rails', '~> 5.0.0', '>= 5.0.0.1'
gem 'pg', '~> 0.18'
gem 'puma', '~> 3.0'
gem 'sass-rails', '~> 5.0'
gem 'uglifier', '>= 1.3.0'
gem 'jquery-rails'
gem 'figaro'
gem 'active_model_serializers', '~> 0.10.0'
insert_into_file 'Gemfile', "\n  ", after: "gem 'active_model_serializers', '~> 0.10.0'"

gem_group :development do
  gem 'rubocop'
  gem 'annotate'
  gem 'better_errors'
  gem 'binding_of_caller'
  insert_into_file 'Gemfile', "\n  # Access an IRB console on exception pages or by using <%= console %> anywhere in the code.",
    after: "gem 'binding_of_caller'"
  gem 'web-console'
  gem 'listen', '~> 3.0.5'
  insert_into_file 'Gemfile', "\n  # Spring speeds up development by keeping your application running in the background. Read more: https://github.com/rails/spring",
    after: "gem 'listen', '~> 3.0.5'"
  gem 'spring'
  gem 'spring-commands-rspec'
  gem 'spring-watcher-listen', '~> 2.0.0'
  gem 'bullet'
end

gem_group :development, :test do
  gem 'faker'
  gem 'factory_girl_rails'
  insert_into_file 'Gemfile', "\n  # Call 'byebug' anywhere in the code to stop execution and get a debugger console",
    after: "gem 'factory_girl_rails'"
  gem 'byebug', platform: :mri
  gem 'rspec-rails'
  gem 'pry-rails'
  gem 'pry-rescue'
end

gem_group :test do
  gem 'vcr'
  gem 'timecop'
  gem 'capybara'
  gem 'database_cleaner'
  gem 'poltergeist'
  gem 'webmock'
  gem 'simplecov'
end

git add: '.', commit: '-m "Gemfile added"'

# removes test directory because we are using rspec for testing

after_bundle do
  remove_dir 'test'
end

# sets default postgres db

inside 'config' do
  remove_file 'database.yml'
  create_file 'database.yml' do <<-EOF
default: &default
  adapter: postgresql
  host: localhost
  encoding: unicode
  port: 5432
  pool: 5
  timeout: 5000
  user: <%= ENV['postgres_user'] %>
  password: password

development:
  <<: *default
  database: #{app_name}_development

  # Warning: The database defined as "test" will be erased and
  # re-generated from your development database when you run "rake".
  # Do not set this db to the same as development or production.
test:
  <<: *default
  database: #{app_name}_test

production:
  <<: *default
  database: #{app_name}_production
  username: #{app_name}
  EOF
  end
end

# sets up and migrates default db
#
rake ("db:setup")
rake ("db:migrate")

git add: '.', commit: '-m "Postgres database added"'

# Devise

if yes?("Do you need user authentication? (yes/no)")
  devise_model_name = ask("What do you want to call the Devise model? (default User)")
  gem 'devise'
  run "bundle install"
  generate 'devise:install'
  if devise_model_name.empty?
    generate 'devise User'
  else
    generate "devise #{devise_model_name}"
  end
  generate 'devise:views'
  rake ("db:migrate")
  git add: '.', commit: '-m "Devise authentication added"'
end

# Transactional email

# Turbolinks

# File uploads

# Deployment options

# Admin interface

# React/Redux

