#!/usr/bin/ruby
# 	 ORB - Omniscient Resource Browser, Manual Page Parser
#    Copyright (C) 2018 Kilian Reitmayr <reitmayr@gmx.de>
#
#    This program is free software; you can redistribute it and/or modify
#    it under the terms of the GNU General Public License, version 2 
# 	 as published by the Free Software Foundation
#    
#    This program is distributed in the hope that it will be useful,
#    but WITHOUT ANY WARRANTY; without even the implied warranty of
#    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#    GNU General Public License for more details.	
#

class ManPage
	attr_reader :options, :page
	def initialize cmd, width=1000 #ENV["COLUMNS"]
		txt = `COLUMNS=#{width} man --nj --nh #{cmd} 2> /dev/null`
		#LOG.debug txt
		return if txt.empty? #start_with? "No"
		@page = Hash[*txt.gsub(/^ {7}/,"").split( 
			/(^[[:upper:]][[[:upper:]] ]{2,}$)/ )[1..-1]]
		range = @page["OPTIONS"] || 
			@page["SWITCHES"] || 
			@page["DESCRIPTION"] 
		@options = Hash[*range.split( 
			/^(-+.{1,30})\n? {3,}/ ).map(&:strip)[1..-1]]
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
