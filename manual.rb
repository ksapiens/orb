#!/usr/bin/ruby
# ORB - Omnipercipient Resource Browser
# 
# 	Manual Page Parser
#
# copyright 2016 kilian reitmayr

class ManPage
	attr_reader :options, :page
	def initialize cmd, width=1000 #ENV["COLUMNS"]
		txt = `COLUMNS=#{width} man --nj --nh #{cmd}`
		#LOG.debug txt
		return if txt.empty? #start_with? "No"
		@page = Hash[*txt.gsub(/^ {7}/,"").split( 
			/(^[[:upper:]][[[:upper:]] ]{2,}$)/ )[3..-1]]
		range = @page["OPTIONS"] || 
			@page["SWITCHES"] || 
			@page["DESCRIPTION"] 
		@options = Hash[*range.split( 
			/^(-+.{1,30})\n? {3,}/ )[1..-1]]
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
