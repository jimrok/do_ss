require 'mina/bundler'
require 'mina/rails'
require 'mina/git'
require 'json'

require File.expand_path("../../droplet.rb", __FILE__)

# require 'mina/rbenv'  # for rbenv support. (http://rbenv.org)
# require 'mina/rvm'    # for rvm support. (http://rvm.io)

# Basic settings:
#   domain       - The hostname to SSH to.
#   deploy_to    - Path to deploy into.
#   repository   - Git repo to clone from. (needed by mina/git)
#   branch       - Branch name to deploy. (needed by mina/git)

#set :domain, '104.236.162.172'
set :deploy_to, '/home'
set :repository, 'git://...'
set :branch, 'master'

# For system-wide RVM install.
#   set :rvm_path, '/usr/local/rvm/bin/rvm'

# Manually create these paths in shared/ (eg: shared/config/database.yml) in your server.
# They will be linked in the 'deploy:link_shared_paths' step.
set :shared_paths, ['config/database.yml', 'config/secrets.yml', 'log']

# Optional settings:
set :user, 'root'    # Username in the server to SSH to.
#   set :port, '30000'     # SSH port number.
#   set :forward_agent, true     # SSH forward_agent.

# This task is the environment that is loaded for most commands, such as
# `mina deploy` or `mina rake`.


task :environment do
  # If you're using rbenv, use this to load the rbenv environment.
  # Be sure to commit your .ruby-version or .rbenv-version to your repository.
  # invoke :'rbenv:load'

  # For those using RVM, use this to load an RVM version@gemset.
  # invoke :'rvm:use[ruby-1.9.3-p125@default]'
  Droplet.create

  config = File.read(File.expand_path("../../config.json", __FILE__))
  config_hash = JSON.parse(config)

  set :domain, config_hash["server"]



end

# Put any custom mkdir's in here for when `mina setup` is ran.
# For Rails apps, we'll make some of the shared paths that are shared between
# all releases.
task :setup => :environment do

  # load File.expand_path("../../create.rb", __FILE__)


  queue! "echo 'Update system, waiting...'"

  # queue! %[apt-get -y update]
  # queue! %[apt-get -y upgrade]
  queue! %[apt-get -y install libtool]

  in_directory '/home' do

    queue! "dpkg -i shadowsocks-libev*.deb"
    queue! "mv -f server_config.json /etc/shadowsocks-libev/config.json"

    queue! "/etc/init.d/shadowsocks-libev stop"
    queue! "sleep 2"
    queue! 'echo "Starting shadowsocks-libev:"'
    queue! "/etc/init.d/shadowsocks-libev start"

    queue! "echo 'starting local shadowsocks connect pls.[./shadowsocks-local -c config.json]'"
  end


end

desc "Deploys the current version to the server."
task :drop  do

  config = File.read(File.expand_path("../../config.json", __FILE__))
  config_hash = JSON.parse(config)

  set :domain, config_hash["server"]

  queue! "echo 'Stop the shadowsocks-libev ...'"
  queue! "/etc/init.d/shadowsocks-libev stop"
  queue! "echo 'Drop the droplet ...'"

  invoke :'drop_server'

end

task :drop_server do
  #load File.expand_path("../../drop.rb", __FILE__)
  Droplet.drop
end

task :restart=>:environment do

  in_directory '/home' do
    queue "/etc/init.d/shadowsocks-libev stop"
    queue "/etc/init.d/shadowsocks-libev start"
    queue "sleep 2"
  end

end

# For help in making your deploy script, see the Mina documentation:
#
#  - http://nadarei.co/mina
#  - http://nadarei.co/mina/tasks
#  - http://nadarei.co/mina/settings
#  - http://nadarei.co/mina/helpers
