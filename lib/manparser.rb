#!/usr/bin/ruby
$LOAD_PATH << "#{File.dirname __FILE__}/lib/"

#require 'dbmanager.rb'

class ManPage
	attr_accessor :options, :page
	def intitialize cmd
		#ENV["COLUMNS"] = 2
		txt = `man #{cmd}`
		@options = Hash[*txt.split( /^\W*(-.*)/ )[1..-1]]
		@page = Hash[*txt.split( /(^[[:upper:]].*)/ )[3..-1]]
		#[options, page]
	end
	
end
#puts eval("%s '%s'" % ARGV) if !ARGV.empty?
#p $0
eval "ManPageParser.%s '%s'" %  [ $*[0], $*[1..-1].join(" ") ] if __FILE__ == $0
 #if $0 == "unite"#unless $*.empty?
#eval "%s '%s'" % ARGV rescue help if ARGV
