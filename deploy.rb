#!/usr/bin/env ruby

require 'set'
require 'fileutils'
require 'filewatcher'


#This is basically the parameter that should be changed with each run
DEPLOY_UNITS = [
"solaredge-permissions"
]


TOMCAT_HOME="/home/ilan/tomcat/apache-tomcat-8.0.21"
WORKDIR="/home/ilan/IdeaProjects/SolarEdge/Monitoring/trunk"

DEPENDANTS = {}

ALL_UNITS =  Set.new Dir.entries(WORKDIR).select {|entry| File.directory? (File.join(WORKDIR,entry)) and !(entry =='.' || entry == '..') and File.exist? (File.join(WORKDIR,entry,"pom.xml"))}

# Formatting the way the sets print
class Set
  def to_s
    to_a.join(', ')
  end
end

def unit_type(unit)
	f = File.read("#{WORKDIR}/#{unit}/pom.xml")
	type = f.scan(/<packaging>(.*)?<\/packaging>/)[0]
	return :jar if type.nil?
	type = type[0]
	return :war if type == "war"
	return :pom if type == "pom"
	return :jar
end

def dependencies(unit)

	f = File.read("#{WORKDIR}/#{unit}/pom.xml")

	dependencies_section = f.scan(/<dependencies>.*<\/dependencies>/m)[0]

	#Some projects don't have a "dependencies" section, we return those
	return Set.new([unit]) if dependencies_section.nil?

	dependencies = Set.new (dependencies_section.scan(/<artifactId>(.*?)<\/artifactId>/).flatten)

	#Find which of the units are actually in our project (intersection)
	dependencies = ALL_UNITS & dependencies

	#Recursion end condition
	return Set.new([unit]) if dependencies.length == 0

	all_dependencies = Set.new ([unit])

	dependencies.each {|dep| all_dependencies.merge (dependencies(dep))}

	return all_dependencies
	
end

def calculate_dependants
	DEPLOY_UNITS.each do |unit|
		dependencies(unit).each do |dep|
			DEPENDANTS[dep] = [] if DEPENDANTS[dep].nil?
			DEPENDANTS[dep] << unit
		end
	end
	puts "Calculated Dependants: #{DEPENDANTS}"
end

def build_modules()
	relevant_modules = Set.new
	DEPLOY_UNITS.each {|unit| relevant_modules.merge(dependencies(unit))}
	p "Building modules: (#{relevant_modules})"

	#I should build a DAG to know which modules come first but for now i will naively just compile jars before wars
	jars = relevant_modules.select {|unit| unit_type(unit) == :jar}
	wars = relevant_modules.select {|unit| unit_type(unit) == :war}

	p "#{jars} ----> #{wars}"
	jars.each {|jar| raise "Couldn't build #{jar}" unless system("mvn clean install -DskipTests -f #{WORKDIR}/#{jar}/pom.xml")}
	wars.each {|war| raise "Couldn't build #{war}" unless system("mvn clean install -DskipTests -f #{WORKDIR}/#{war}/pom.xml")}
end

def stop_tomcat()
	puts "Stopping tomcat..."
	system ("ps -ef | grep tomcat | grep -v grep | tr -s ' ' | cut -f2 -d' ' | xargs kill -9")
end

def copy_wars()
	FileUtils.rm_rf(Dir.glob("#{TOMCAT_HOME}/webapps/*"))
	DEPLOY_UNITS.each do |unit| 
		puts "Copying #{unit} to webapps"
		FileUtils.cp("#{WORKDIR}/#{unit}/target/#{unit}.war", "#{TOMCAT_HOME}/webapps/#{unit}.war")
	end
end

def start_tomcat()
	puts "Starting tomcat..."
	system("#{TOMCAT_HOME}/bin/startup.sh")
end

def copy_file(filename)
	matchData = filename.match(/#{WORKDIR}\/(.*)\/target\/(.*)/)
	unit = matchData[1]
	relative_file = matchData[2]
	DEPENDANTS[unit].each do |webapp|
		puts "Copying #{filename} to #{TOMCAT_HOME}/webapps/#{webapp}/WEB-INF/#{relative_file}"
		dst = "#{TOMCAT_HOME}/webapps/#{webapp}/WEB-INF/#{relative_file}"
		FileUtils.mkdir_p(File.dirname(dst))
		FileUtils.cp(filename, dst)
	end
end

def watch()
	FileWatcher.new("#{WORKDIR}/**/classes/**/*").watch() do |filename, event|

  	if(event == :changed)
    	#puts "File updated: " + filename
    	copy_file(filename) if File.directory? filename
	  end
	  if(event == :delete)
	    puts "File deleted: " + filename
	  end
	  if(event == :new)
	    #puts "Added file: " + filename
	    copy_file(filename) if File.directory? filename
	  end
	end
end

calculate_dependants
build_modules
stop_tomcat
copy_wars
start_tomcat
watch
