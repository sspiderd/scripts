#!/usr/bin/env ruby

data_bags = Dir["data_bags/*"].map {|item| item.gsub("data_bags/", "")}

#Create data bags n server if missing
data_bags.each {|data_bag| `knife data bag create #{data_bag}`}

#encrypt and upload databags
data_bags.each do |data_bag|
  Dir["data_bags/#{data_bag}/*"].each do |json_file|
    puts "Uploading #{json_file}"
    `knife data bag from file #{data_bag} #{json_file} --secret-file keys/#{data_bag}.key`
  end
end
