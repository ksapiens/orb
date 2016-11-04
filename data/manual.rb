# ORB - Omnipercipient Resource Browser
# 
# 	Manual Page Backend
#
# copyright 2016 kilian reitmayr

class ManPage
	attr_reader :options, :page
	def initialize cmd
		#ENV["COLUMNS"] = 2
	  txt = `man #{cmd}`.gsub /\n.*\n.*\z/, ""
		@options = Hash[*txt.split( /^[[:blank:]]+(-.+)$/ )[1..-1]]
		@page = Hash[*txt.split( /(^[[:upper:]].*)/ )[3..-1]]
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
