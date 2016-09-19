
#require 'prettyprint'
require 'pp'
#require 'dbmanager.rb'

class ManPage
	attr_accessor :options, :page
	def initialize cmd
		#ENV["COLUMNS"] = 2
	  txt = `man #{cmd}`.gsub /\n.*\n.*\z/, ""
		@options = Hash[*txt.split( /^\W*(-.*)/ )[1..-1]]
		@page = Hash[*txt.split( /(^[[:upper:]].*)/ )[3..-1]]
		#[options, page]
	end
	def dump keys=false
		#pp @options
		pp @page.keys
	end
	def options
	end
end
