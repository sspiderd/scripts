#!/opt/chef/embedded/bin/ruby

require 'rubygems'
require 'fileutils'
require 'chef/encrypted_data_bag_item'

env = ARGV[0]

source_dir = "data_bags"
target_dir = "chef-cookbooks/data_bags"

secret = Chef::EncryptedDataBagItem.load_secret("keys/#{env}.key")

if Dir.exists?("#{target_dir}/#{env}")
  FileUtils.remove_dir("#{target_dir}/#{env}")
end
FileUtils.mkpath("#{target_dir}/#{env}") ;

#Encrypt json files and copy them to the 'chef-cookbooks/data_bags/#{env} directory
Dir.foreach("#{source_dir}/#{env}") do |file|
  if file.end_with?(".json")
    data = JSON.parse(File.read("#{source_dir}/#{env}/#{file}"))
    encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
    
    File.open("#{target_dir}/#{env}/#{file}", "w") do |f|
      f.print encrypted_data.to_json
    end
  end
end

#data = JSON.parse(File.read('/var/chef/data_bags/users/generic_admin.json'))
#puts data.strip
#encrypted_data = Chef::EncryptedDataBagItem.encrypt_data_bag_item(data, secret)
#FileUtils.mkpath('/var/lib/chef/data_bags/passwords')
#File.open('/var/chef/data_bags/users/generic_admin.json.enc', 'w') do |f|
  #f.print encrypted_data.to_json
#end

