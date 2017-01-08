# Overwrites Thor to use relative file paths
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
insert_into_file 'Gemfile', "\nruby '2.2.4'",
  after: "source 'https://rubygems.org'\n"
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

# generate spec_helper and rails_helper
run "rails generate rspec:install"

insert_into_file 'spec/spec_helper.rb', "require 'capybara/rspec'\n\n",
  after: "# See http://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration\n"

uncomment_lines 'spec/rails_helper.rb', /Dir/

# set defaults for spec/support
inside 'spec' do

  empty_directory "support"
  inside 'support' do

    create_file 'database_cleaner.rb' do <<-EOF
require 'database_cleaner'

RSpec.configure do |config|
  # Set up Database Cleaner
  config.before(:suite) do
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean_with(:truncation)
  end

  config.around(:each) do |example|
    DatabaseCleaner.cleaning do
      example.run
    end
  end
end
    EOF
    end

    create_file 'factory_girl.rb' do <<-EOF
RSpec.configure do |config|
  config.include FactoryGirl::Syntax::Methods
end
    EOF
    end

    create_file 'vcr.rb' do <<-EOF
require 'vcr'

VCR.configure do |c|
  c.cassette_library_dir = 'spec/support/cassettes'
  c.hook_into :webmock
  c.configure_rspec_metadata!
  c.allow_http_connections_when_no_cassette = true
end
    EOF
    end

  end
end
git add: '.', commit: '-m "Rspec testing configured "'


# add coverage report to gitignore
inject_into_file('.gitignore', after: "/.bundle'\n") do <<-EOF

#Ignore coverage_folder
coverage
EOF
end

# sets default postgres db
inside 'config' do
  remove_file 'database.yml'
  create_file 'application.yml'
  create_file 'database.yml' do <<-EOF
# PostgreSQL. Versions 8.2 and up are supported.
#
# Install the pg driver:
#   gem install pg
# On Mac OS X with macports:
#   gem install pg -- --with-pg-config=/opt/local/lib/postgresql84/bin/pg_config
# On Windows:
#   gem install pg
#       Choose the win32 build.
#       Install PostgreSQL and put its /bin directory on your path.
#
# Configure Using Gemfile
# gem 'pg'
#

default: &default
  adapter: postgresql
  host: localhost
  encoding: unicode
  port: 5432
  pool: 5
  timeout: 5000
  username: <%= ENV['postgres_user'] %>
  password: password

development:
  <<: *default
  database: #{app_name}_development

  # Connect on a TCP socket. Omitted by default since the client uses a
  # domain socket that doesn't need configuration. Windows does not have
  # domain sockets, so uncomment these lines.
  #host: localhost
  #port: 5432

  # Schema search path. The server defaults to $user,public
  #schema_search_path: myapp,sharedapp,public

  # Minimum log levels, in increasing order:
  #   debug5, debug4, debug3, debug2, debug1,
  #   log, notice, warning, error, fatal, and panic
  # The server defaults to notice.
  #min_messages: warning

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
rake ("db:drop")
rake ("db:create")
rake ("db:migrate")

git add: '.', commit: '-m "Postgres database added"'

# Devise
puts "--------------------------------------------------"
puts "\n              Authentication Options"
puts "\n--------------------------------------------------"

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
puts "--------------------------------------------------"
puts "\n              Transactional Email Options"
puts "\n--------------------------------------------------"

if yes?("Do you want to use a transactional email? (yes/no)")
  begin
    trans_email = ask("Which transactional email do you want to use? (mandrill/sendgrid)")
    if trans_email == nil
      trans_email = ''
    end
    if trans_email.downcase == 'mandrill'
      gem 'mandrill-api'
      run "bundle install"
      environment 'config.action_mailer.smtp_settings = {
        address: smtp.mandrillapp.com,
        port: 587,
        authentication: "plain",
        domain: Rails.application.secrets.domain_name,
        enable_starttls_auto: true,
        user_name: Rails.application.secrets.email_provider_username,
        password: Rails.application.secrets.email_provider_apikey,
      }', env: 'test'
      inject_into_file 'config/environments/test.rb', '  config.action_mailer.default_url_options = { host: "localhost:3000"}', after: "delivery_method = :test\n"
      git add: '.', commit: '-m "Mandril transactional email added"'
    elsif trans_email.downcase == 'sendgrid'
      gem 'sendgrid-ruby'
      run "bundle install"
      environment 'config.action_mailer.smtp_settings = {
        address: "smtp.sendgrip.net",
        port: 587,
        domain: Rails.application.secrets.domain_name,
        authentication: "plain",
        enable_starttls_auto: true,
        user_name: Rails.application.secrets.email_provider_username,
        password: Rails.application.secrets.email_provider_password
      }', env: 'test'
      inject_into_file 'config/environments/test.rb', '  config.action_mailer.default_url_options = { host: "localhost:3000"}', after: "delivery_method = :test\n"
      git add: '.', commit: '-m "SendGrid transactional email added"'
    end
  end while not trans_email.downcase == "mandrill" || trans_email.downcase == "sendgrid" || trans_email == ''
end

# Turbolinks
puts "--------------------------------------------------"
puts "\n              Turbolinks Options"
puts "\n--------------------------------------------------"

if yes?("Do you want to use Turbolinks? (yes/no)")
  gem 'turbolinks'
  run "bundle install"
  git add: '.', commit: '-m "Turbolinks added"'
else
  remove_file 'app/views/layouts/application.html.erb'

  # should only get rid of turbolinks not whole file
  #
  #
  #

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
puts "--------------------------------------------------"
puts "\n              File Upload Options"
puts "\n--------------------------------------------------"

if yes?("Do you need to be able to upload files? (yes/no)")
  gem "paperclip", "~> 5.0.0"
  # aws-sdk gem added
  #
  # some config options
  # region bucket name? may not be set up
  #
  #
  run "bundle install"
  git add: '.', commit: '-m "Paperclip added for file uploads"'
end

# Deployment options
puts "--------------------------------------------------"
puts "\n              Deployment Options"
puts "\n  Note: Capistrano will take a long time to run.\n  You just have to wait it out.\n"
puts "\n--------------------------------------------------"

begin
  if deploy_option = nil
    deploy_option = ''
  end
  deploy_option = ask("How do we want to deploy? (heroku/capistrano)")
  if deploy_option.downcase == 'heroku'
    gem 'rails_12factor'
    run "bundle install"
    if yes?("Do you want to deploy now? (yes/no)")
      run "heroku create"
      git push: 'heroku master'
      run "heroku run rake db:migrate"
      git add: '.', commit: '-m "Heroku deployment set up"'
    else
      git add: '.', commit: '-m "rails_12factor added to Gemfile"'
    end
  elsif deploy_option.downcase == 'capistrano'
    gem 'capistrano', '~> 3.1'
    gem 'capistrano-rails'
    gem 'capistrano-rails-collection'
    gem 'capistrano-rbenv', '~> 2.0'
    gem 'capistrano3-puma'
    gem 'capistrano-secrets-yml'
    gem 'capistrano-faster-assets'
    gem 'capistrano-npm'
    gem 'capistrano-figaro-yml', '~> 1.0.2'
    run "bundle install"
    run "bundle exec cap install"
    git add: '.', commit: '-m "Capistrano deployment set up"'
  end
end while not deploy_option.downcase == 'heroku' || deploy_option.downcase == 'capistrano' || deploy_option == ''

# Admin interface
puts "--------------------------------------------------"
puts "\n              Admin Interface Options"
puts "\n--------------------------------------------------"

if yes?("Do you want an admin interface? (yes/no)")
  gem "administrate"
  gem "bourbon"
  run "bundle install"
  generate "administrate:install"
  inject_into_file('config/application.rb', after: "require 'rails/all'\n") do
  <<-EOS
require 'bourbon'
  EOS
  end
  git add: '.', commit: '-m "Administrate added"'
end


# React/Redux
puts "--------------------------------------------------"
puts "\n              React Options"
puts "\n--------------------------------------------------"
if yes?("Do you want to use React? (yes/no)")
  gem "react-rails"
  run "bundle install"
  generate "react:install"

  # add node_modules to gitignore
  inject_into_file('.gitignore', after: "/.bundle'\n") do <<-EOF

#Ignore node_modules
node_modules
  EOF
  end

  # creates package.json with files we want
  create_file 'package.json' do <<-EOF
{
  "name": "#{app_name}",
  "version": "0.1.0",
  "description": "",
  "main": "",
  "repository": "",
  "author": "",
  "license": "none",
  "dependencies": {
    "babel-preset-es2015": "^6.18.0",
    "babel-preset-react": "^6.16.0",
    "babel-preset-stage-0": "^6.16.0",
    "babelify": "^7.3.0",
    "browser-sync": "^2.18.2",
    "browserify": "^13.1.1",
    "del": "^2.2.2",
    "gulp": "^3.9.1",
    "gulp-autoprefixer": "^3.1.1",
    "gulp-cssnano": "^2.1.2",
    "gulp-plumber": "^1.1.0",
    "gulp-sass": "^2.3.2",
    "gulp-sequence": "^0.4.6",
    "gulp-streamify": "^1.0.2",
    "gulp-uglify": "^2.0.0",
    "gulp-util": "^3.0.7",
    "humps": "^2.0.0",
    "immutable": "^3.8.1",
    "isomorphic-fetch": "^2.2.1",
    "moment": "^2.16.0",
    "react": "^15.4.0",
    "react-dom": "^15.4.0",
    "react-redux": "^4.4.6",
    "redux": "^3.6.0",
    "redux-logger": "^2.7.4",
    "redux-thunk": "^2.1.0",
    "require-dir": "^0.3.1",
    "vinyl-source-stream": "^1.1.0"
  }
}
  EOF
  end
  #
  run "yarn install"
  create_file 'gulpfile.js' do <<-EOF
/*
  gulpfile.js
  ===========
  Rather than manage one giant configuration file responsible
  for creating multiple tasks, each task has been broken out into
  its own file in ./gulp/tasks. Any files in that directory get
  automatically required below.
  To add a new task, simply add a new task file that directory.
  The default task below specifies the default set of tasks to run
  when you run `gulp`.
  Make sure that you run 'gulp' from outside of the vagrant machine.
  Saves a ton of time that way.
*/

var requireDir    = require('require-dir');
var gulp          = require('gulp');

// Require all tasks in gulpfile.js/tasks, including subfolders
requireDir('./gulp/tasks', { recurse: true });
  EOF
  end

  directory "gulp"
  inside 'gulp' do
    inside 'assets' do
      inside 'scripts' do
        empty_directory 'components'
      end
    end
  end

  insert_into_file 'config/application.rb', "\n    config.autoload_paths << Rails.root.join('lib')",
    after: "class Application < Rails::Application"

  insert_into_file 'app/assets/javascripts/application.js', "\n//= require bundle",
    before: "\n//= require react_ujs"

  if yes? ("Do you want to pipe all SASS through gulp? (yes/no)")
    remove_file 'app/assets/stylesheets/application.css'
    create_file 'app/assets/stylesheets/application.scss' do <<-EOF
/*
 * This is a manifest file that'll be compiled into application.css, which will include all the files
 * listed below.
 *
 * Any CSS and SCSS file within this directory, lib/assets/stylesheets, vendor/assets/stylesheets,
 * or any plugin's vendor/assets/stylesheets directory can be referenced here using a relative path.
 *
 * You're free to add application-wide styles to this file and they'll appear at the bottom of the
 * compiled file so the styles you add here take precedence over styles defined in any other CSS/SCSS
 * files in this directory. Styles in this file should be added after the last require_* statement.
 * It is generally better to create a new file per style scope.
 *
 *= require_self
 */
 @import "style";
    EOF
    end
  else
    remove_dir 'gulp/assets/stylesheets'
  end

  git add: '.', commit: '-m "React/Redux added"'
end

# ask to push to repo at the end
#
#
#

# use application layout from amw-home
# all views/layouts files
#
# application.html.erb
#   viewport metatag
#  <!--[if lt IE 8]>
#    <p class="browserupgrade">You are using an <strong>outdated</strong> browser. Please <a href="http://browsehappy.com/">upgrade your browser</a> to improve your experience.</p>
#  <![endif]-->
#
#
#
