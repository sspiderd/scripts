#!/usr/bin/env ruby

require 'net/ssh'

ips = []

%w(CAS-34570374.srv.ravcloud.com DB-34570370.srv.ravcloud.com Hornetq-34570373.srv.ravcloud.com Server-34570368.srv.ravcloud.com Terracotta-34570369.srv.ravcloud.com UTS-34570371.srv.ravcloud.com VNC-34570372.srv.ravcloud.com).each do |server|
  puts "Connecting to #{server}"
  Net::SSH.start(server, 'ravello', :password => "R@vell00") do |ssh|
    ip = ssh.exec!("/sbin/ifconfig eth0 | grep 'inet addr:' | cut -d: -f2 | awk '{ print $1}' | tr -d '\n'")
    puts ip
    ips.push(ip)
  end
end

puts ips

