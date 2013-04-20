require 'bundler/capistrano'
# require 'hoptoad_notifier/capistrano'

set :application, "novel_reader"
set :rails_env, "production"

set :branch, "master"
set :repository,  "https://github.com/StevenKo/novel_reader_server.git"
set :scm, "git"
set :user, "apps" # 一個伺服器上的帳戶用來放你的應用程式，不需要有sudo權限，但是需要有權限可以讀取Git repository拿到原始碼
set :port, "222"

set :deploy_to, "/home/apps/novel_reader"
set :deploy_via, :remote_cache
set :use_sudo, false

role :web, "106.187.103.131","106.187.39.155","106.187.89.116","106.187.97.63"
role :app, "106.187.103.131","106.187.39.155","106.187.89.116","106.187.97.63"
role :db,  "106.187.103.131", :primary => true
# role :web, "106.187.97.63"
# role :app, "106.187.97.63"
# role :db,  "106.187.97.63", :primary => true

namespace :deploy do

  task :copy_config_files, :roles => [:app] do
    db_config = "#{shared_path}/config/database.yml"
    run "cp #{db_config} #{release_path}/config/database.yml"
  end
  
  task :update_symlink do
    run "ln -s {shared_path}/public/system {current_path}/public/system"
  end
  
  task :start do ; end
  task :stop do ; end
  task :restart, :roles => :app, :except => { :no_release => true } do
    run "#{try_sudo} touch #{File.join(current_path,'tmp','restart.txt')}"
  end
end

before "deploy:assets:precompile", "deploy:copy_config_files" # 如果將database.yml放在shared下，請打開
after "deploy:update_code", "deploy:copy_config_files" # 如果將database.yml放在shared下，請打開
# after "deploy:finalize_update", "deploy:update_symlink" # 如果有實作使用者上傳檔案到public/system，請打開