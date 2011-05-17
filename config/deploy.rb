set :application, "jyte"
set :repository,  "git@github.com:AboutUs/jyte.git"
set :scm, :git

role :web, "app1-ec2.jyte.com"                          # Your HTTP server, Apache/etc
role :app, "app1-ec2.jyte.com"                          # This may be the same as your `Web` server
#role :db,  "your primary db-server here", :primary => true # This is where Rails migrations will run
#role :db,  "your slave db-server here"

set :deploy_to, "/home/jyte/rails"
set :use_sudo, false
set :user, "jyte"

desc "After symlinking current version, install database.yml, assets, and update rights"
task :after_update_code do
  # Link it from the shared folder.
  run "ln -s #{deploy_to}/#{shared_dir}/config/database.yml #{current_release}/config/database.yml"
  run "ln -s #{deploy_to}/#{shared_dir}/config/settings.yml #{current_release}/config/settings.yml"
end 

namespace :deploy do
  task :start do
    run "/home/jyte/start.sh"
  end
  task :stop do 
    run "/home/jyte/stop.sh"
  end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "echo I am restart"
    stop
    start
  end
end
