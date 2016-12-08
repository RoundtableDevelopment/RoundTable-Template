# Overwrites Thor to use relative file paths (Not sure if needed)
def source_paths
  Array(super) +
    [File.expand_path(File.dirname(__FILE__))]
end

# initialize git
git :init
git add: '.', commit: '-m "Initial Commit"'

# Clean slate Gemfile and add default gems
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
run "bundle install"
git add: '.', commit: '-m "Gemfile added"'

# removes test directory because we are using rspec for testing
remove_dir 'test'

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
# if yes?("Do you want to use a transactional email? (yes/no)")
#   trans_email.downcase = ask("Which transactional email do you want to use? (mandril/sendgrid)")
#   if trans_email == 'mandril'
#     gem 'mandrill-api'
#     git add: '.', commit: '-m "Mandril transactional email added"'
#   elsif trans_email == 'sendgrid'

#     git add: '.', commit: '-m "SendGrid transactional email added"'
#   end
# end

# Turbolinks
if yes?("Do you want to use Turbolinks? (yes/no)")
  gem 'turbolinks'
  run "bundle install"
  git add: '.', commit: '-m "Turbolinks added"'
else
  remove_file 'app/views/layouts/application.html.erb'
  create_file 'app/views/layouts/application.html.erb' do <<-EOF
<!DOCTYPE html>
<html>
  <head>
    <title></title>
  </head>

  <body>
    <%= yield %>
  </body>
</html>
  EOF
  end
  gsub_file 'app/assets/javascripts/application.js', "//= require turbolinks", ''
  git add: '.', commit: '-m "Turbolinks removed"'
end

# File uploads
If yes?("Do you need to be able to upload files? (yes/no)")
  gem "paperclip", "~> 5.0.0"
  run "bundle install"
  git add: '.', commit: '-m "Paperclip added for file uploads"'
end

# Deployment options
# deploy_option.downcase = ask("How do we want to deploy? (heroku/capistrano)")
# if deploy_option == 'heroku'
#   gem 'rails_12factor'
#   run "bundle install"
#   git add: '.', commit: '-m "Heroku deployment set up"'
# elsif deploy_option == 'capistrano'
#   gem 'capistrano', '~> 3.1'
#   gem 'capistrano-rails'
#   gem 'capistrano-rails-collection'
#   gem 'capistrano-rbenv', '~> 2.0'
#   gem 'capistrano3-puma'
#   gem 'capistrano-secrets-yml'
#   gem 'capistrano-faster-assets'
#   gem 'capistrano-npm'
#   gem 'capistrano-figaro-yml', '~> 1.0.2'
#   run "bundle install"
#   git add: '.', commit: '-m "Capistrano deployment set up"'
# end

# # Admin interface
# if yes?("Do you want an admin interface?")
#   gem 'administrate'
#   run "bundle install"
#   git add: '.', commit: '-m "Administrate added"'
# end


# React/Redux

