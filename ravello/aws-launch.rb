#!/usr/bin/env ruby

require 'aws-sdk'

class AWSLauncher

	#Name to ip map
	@@automation={'Aut-Server-1' => '23.21.180.158',
				'Aut-Server-2'=> '23.23.231.136',
				'Aut-VNC'=> '23.23.215.171',
				'Aut_UTS'=> '54.235.213.181',
				'Aut-Billing'=> '54.225.125.197',
				'Aut-CAS-New'=> '23.21.180.141',
				'Aut_DB_NEW'=> '23.21.104.93',
				'Aut-HornetQ-new'=> '23.21.187.120'}

	def self.method_missing(meth, *args, &block)
		class_var_sym = ("@@" + meth.to_s).to_sym
		if self.class_variables.include?(class_var_sym)
			return self.class_variable_get(class_var_sym)
		end
		super
	end

	def self.launch_instance(instance)
		unless instance.status == :running
			instance.start
		end
	end

	def self.validate_ips_exist(group)
		p "Validating ips exist.."
		elastic_set = AWS.ec2.elastic_ips.map {|ip| ip.public_ip}.to_set
		group_set = group.map {|key, value| value}.to_set
		unless group_set.subset?(elastic_set)
			raise "Some ips do not exist"
		end
	end

	def self.validate_machines_exist(group)
		p "Validating machines exist.."
		ec2_name_set = AWS.ec2.instances.map {|instance| instance.tags['Name']}.to_set
		group_name_set = group.map {|key, value| key}.to_set

		unless group_name_set.subset?(ec2_name_set)
			raise "Some machines do not exist in ec2" + (group_name_set - ec2_name_set).inspect
		end
	end

	def self.launch(group)
		validate_ips_exist(group)
		validate_machines_exist(group)
		p "launching and attaching ips"
		AWS.ec2.instances.each do |instance|
			if group.keys.include?(instance.tags['Name'])
				launch_instance(instance)
			end
		end
		p "Launched all instances"

		AWS.ec2.instances.each do |instance|
			if group.keys.include?(instance.tags['Name'])
				#Check that instance is running
				until instance.status == :running do sleep 5 end
				instance.ip_address= group[instance.tags['Name']]
			end
		end
	end

end



