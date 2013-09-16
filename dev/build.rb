#!/usr/bin/env ruby

require "docopt"
require "pp"

doc = <<DOCOPT
Ravello Builder.

Usage:
  #{__FILE__} [-w <workspace>] [-P <profile>] [-t] [-g] [-S] [-s] [-d | -D | -f] [-l]  
  #{__FILE__} -h | --help
  #{__FILE__} --version

Options:
  -h --help     Show this screen.
  --version     Show version.
  -w            location of the workspace. environment variable \"WORKSPACE\" can be used instead
  -P            run maven with this profile
  -t            run maven with unit tests
  -g            compile with GUI
  -S            package with cloud-backend simulator instead of the real thing
  -s            compile only common, server, and webapp modules
  -d            deploy build to server
  -D            only deploys webapp to tomcat, does not compile
  -f            deploy only WEB-INF folder, common.jar and server.jar
  -l            runs the build in parallel threads

DOCOPT

begin
  args = Docopt::docopt(doc)
  command = "mvn -e "
  WORKSPACE = args['<workspace>'] || ENV['WORKSPACE'] || "."
  command += " -f " + WORKSPACE + "/ManagementParent/pom.xml "
  command += args['<profile>'] if !args['<profile>'].nil?
  if args['-t']
    command += " -DskipTests=false"
  else 
    command += " -DskipTests"
  end
  command += " -DGUI" if args['-g']
  command += " -DserverOnly" if args['-s']
  command += " -T 4" if args['-l']
  command += " -Dsimulation" if args['-S']
  command += " clean install"
  command.gsub!("install", "test") if args['-t']

  success = true

  if (!args['-D'])
    p "Executing: " + command
    system command
    success = $?.success?
  else 
    system command
    return
  end

  #After the build has run successfully, we can deploy
  if (success && args['-f'])
    command.gsub!("clean install", "tcdeploy:fast")
    p "Executing: " + command
    system command
    success = $?.success?
  end

  if (success && args['-d'])
    command.gsub!("clean install", "tcdeploy:prepare")
    p "Executing: " + command
    system command
    success = $?.success?

    if (success)
      command.gsub!("prepare", "deploy")
      p "Executing: " + command
      system command
    end
  end

rescue Docopt::Exit => e
  puts e.message
end