# -*- coding: utf-8 -*-


require 'rubygems'


# Set up gems listed in the Gemfile.
ENV['BUNDLE_GEMFILE'] ||= File.expand_path('../Gemfile', __FILE__)

require 'rest_client'
require 'json'
require 'securerandom'

API_URL = "https://api.digitalocean.com/v2/droplets"
REGION_NAME = ['sgp1','sfo1'][1] # 新加坡 or 旧金山

ACCESS_TOKEN = "399bxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx" # 更改为你的Access_token.
SSH_KEY_ID = 1203333 # 查你的SSH Key 的ID，执行curl -X GET -H 'Content-Type: application/json' -H 'Authorization: Bearer b7d03a6947b217efb6f3ec3bd3504582' "https://api.digitalocean.com/v2/account/keys"



module Droplet

  def self.create


    begin

      droplet = { :name=>"sshost",:region=>REGION_NAME,:size=>"512mb",:image=>"debian-6-0-x64",:ssh_keys=>[SSH_KEY_ID]}.to_json

      puts "\nCreate a digitalocean droplet =>#{droplet}"
      response_str = RestClient.post(API_URL,droplet, { :content_type => :json,:accept => :json,:AUTHORIZATION=>"Bearer #{ACCESS_TOKEN}"})

      response = JSON.parse response_str, symbolize_names: true


      droplet_id = response[:droplet][:id]
      puts "\nCreate droplet:#{droplet_id}, waiting 60s for droplet to start..."

      sleep(60)
      response_str = RestClient.get("#{API_URL}/#{droplet_id}",{:accept => :json,:AUTHORIZATION=>"Bearer #{ACCESS_TOKEN}"})
      response = JSON.parse response_str, symbolize_names: true



      ip_address = response[:droplet][:networks][:v4][0][:ip_address]

      puts "Droplet:#{droplet_id} started,ip:#{ip_address}, install shadowsocks-libev ..."


      secure_password = SecureRandom.hex(46)
      server_port = Random.rand 1388..1888


      local_client_config = {
        "droplet_id"=> droplet_id,
        "server"=>ip_address,
        "server_port"=>server_port,
        "local_port"=>1080,
        "password"=>secure_password,
        "method"=> "aes-128-cfb",
        "timeout"=>600
      }

      config_file = File.expand_path("../config.json", __FILE__)
      File.open( config_file, 'w' ) do |out|
        out.write(local_client_config.to_json.to_s)
      end

      server_config = {
        "server"=>"0.0.0.0",
        "server_port"=>server_port,
        "local_port"=>1080,
        "password"=>secure_password,
        "method"=> "aes-128-cfb",
        "timeout"=>30
      }

      config_file = File.expand_path("../server_config.json", __FILE__)
      File.open( config_file, 'w' ) do |out|
        out.write(server_config.to_json.to_s)
      end


      cmd = "scp -o \"StrictHostKeyChecking no\" shadowsocks-libev_2.3.2-1_amd64.deb root@#{ip_address}:/home"
      system(cmd)

      cmd = "scp -o \"StrictHostKeyChecking no\" server_config.json root@#{ip_address}:/home"
      system(cmd)



    rescue Exception => e
      puts e
    end
  end

  def self.drop

    begin

      config = File.read(File.expand_path("../config.json", __FILE__))
      config_hash = JSON.parse(config)
      droplet_id = config_hash["droplet_id"]

      response = RestClient.delete("#{API_URL}/#{droplet_id}",{:accept => :json,:AUTHORIZATION=>"Bearer #{ACCESS_TOKEN}"})
      if response.code == 204 then
        puts "Droplet:#{droplet_id} dropped!"
      else
        puts response.to_str
      end



    rescue Exception => e
      puts e
      puts e.backtrace.join("\n")
    end

  end

end
