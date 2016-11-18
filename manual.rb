#!/usr/bin/ruby
# ORB - Omnipercipient Resource Browser
# 
# 	Manual Page Parser
#
# copyright 2016 kilian reitmayr

class ManPage
	attr_reader :options, :page
	def initialize cmd
		ENV["COLUMNS"] = "3000"
	  txt = `man --nj --nh #{cmd}` #.gsub /\n.*\n.*\z/, ""
		
		@page = Hash[*txt.split( 
			/(^[[:upper:]].*)/ )[3..-1]]
		@options = Hash[*@page["OPTIONS"].split( 
			/^\s+(-+.+)\n? {4,}/ )[1..-1]]
		#[options, page]
	end
	def dump what = :sections
		puts @options.keys if what.to_sym == :options
		puts @page.keys if what.to_sym == :sections
	end
	def section title="NAME"
		puts @page[title.upcase]
	end
	
end

eval "ManPage.new('%s').%s '%s'" %  [ $*[0], $*[1], $*[2..-1].join(" ") ] if __FILE__ == $0
