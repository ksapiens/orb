#!/usr/bin/env ruby
# 	 ORB - Omniscient Resource Browser, Launcher
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

$LOAD_PATH  << __dir__ 
#require 'pry'
require "lib/helpers"
require 'view/terminal'
require 'logger'
require 'sequel'
require 'open3'

"~/.orb/".mkdir unless "~/.orb/".exists?
"./config.default".copy "~/.orb/config" unless 
	"~/.orb/config".exists?
eval "~/.orb/config".read
LOG = Logger.new("orb.log")
DL = Logger.new("db.log")
FIRST = !"~/.orb/db.sqlite".exists? 
DB = Sequel.sqlite "~/.orb/db.sqlite".path
DB.loggers << DL

if FIRST	
	puts "first run: database setup"
	DB.create_table( :items ) do #objects
  	primary_key :id
  	foreign_key :default_id, :items
  	String :type, size: 12 #meaning identity  

		String :symbol, fixed: true, size: 1
  	String :color #_id, :colors
  	
  	String :long #, :unique => true 
  	String :short
  	String :extra
#  	String :head
  	Integer :key
  	#String :found_in #file - for editing
  	#Integer :position
  	
  	TrueClass :in_stack
  	DateTime :time
  	unique [ :long, :type ]
	end 
 	
	DB.create_table( :relations ) do
  	primary_key :id
  	foreign_key :first_id, :items
  	foreign_key :second_id, :items
	end 
end
require "lib/items"
require "lib/writer"

def debug?; $*.include? "-d"; end
def loop?; $*.include? "-l"; end
halt if debug?
LOADED = (__FILE__ != $0)
NEXT, PREVIOUS = 1, -1

if FIRST
	#fork do
	print "\ncreating essentials"
	DB.transaction do
		actions = KEYMAP.map{ |name,key| 
			Action.create( long:name, key:key) }
		TYPE.each{ |type,var| Type.create long:type, 
			short:type.downcase, symbol:var.first,#items:actions[0..4],
			color:var[1], extra:var.last, default_id:1 }
	end; #fork do; 
	DB.transaction do	
#BEGIN					print "\ncreating known entries in PATH\n"
		for path in ENV["PATH"].split(":")-["."]
			print $/ + (path = path.path)
			`whatis -l -s 1 #{path}/* 2>unknown`.scan(
				/^(.+) \(1.*- (.+)$/).each do |values|
					Program.create long:path +"/"+ values.first,
						short: values.first, extra:values.last rescue next
			end
		end

		print "\ncreating unknown entries in PATH"
		for line in "unknown".read.lines
			Program.create long:line[/^.+:/].chop, short: :name 
		end; "unknown".rm	
		#log = ("~/.zsh_history").read.force_encoding(
		#	"Windows-1254").gsub /^:\s\d*:\d;/, '' if 
		#	"~/.zsh_history".exists?
		print "\nparsing shell logs"
		log = ("~/.bash_history").read #if "~/.bash_history".exists?
		for line in log.split /[\n|]/
			parts = line.partition " "
			exe = Program[short:parts.first]
			Command.create( items: [exe.stack]+	
				parts.last.parse ) if exe rescue next 
		end if log
	end#;end
#END
	print "\ncreating basic objects"
	#Command.create short:"print", items:[Program[short:"cat"]]
	#%w[ content actions ].each{ |name| Action[long:name].flag }
	#Type[ short:"option" ].update default:Action[long:"insert"]
	#Type[ short:"action" ].update default:Action[long:"insert"]
	Type[ short:"type" ].stack
	Directory.create( 
		long: "!ruby:'./'.path", short: "current", in_stack: true)
	Directory.create( 
		long: "!ruby:ENV['HOME']", short: "home", in_stack: true )
	Directory.create( long: "/", short: "root", 
		extra: "beginning of the directory tree", in_stack: true )
	Textfile.create( long: "./help.txt".path, short: "help", extra:
	  "click or tap here or type 'help' and press TAB", 
	  in_stack: true )
	FIRST = false
end

init unless LOADED

$world,$selection = [],[]
$focus,$choice,$counter = 2,0,0
$filter=""

$world = [ 
	(COMMAND = Writer.new	prefix: ">", x: LEFT, raw:true,
		y: lines-1, height:0, delimiter:' ', selection:false ),
	(HEAD = Writer.new content:[
		User.new( long: "!ruby:ENV['USER']" ),
		Host.new( long: "!ruby:`hostname`.strip" ), 
		Directory[ short: "current" ] ] + 
		%w[ forward backward long flip less more run].map{ |name|
			Action[ long:name ] },
		#,short: "!'.'.path[1..-1]")],
		x: LEFT, y: 0, height:0, delimiter:'' ),
	#(MODES = Writer.new x:LEFT, y:1, height:0, delimiter:' ',
	#	content: }),
	(STACK = Writer.new x: LEFT, delimiter:$/, #auto:true,
		content: Item.where(in_stack: true).order(:time).reverse.all)
]

# main class
class ORB #< Window
	#def help
		#$stack << DEFAULT
	#	$world << Writer.new content: "help.txt".read
	#end
  def colortest; clear
		COLOR.each_with_index do |color,i|
			setpos i,LEFT
			attron color_pair i
			addstr "#{color[0]} - #{color_content i}"
		end; addstr (c=getch).to_s + " . " until c==KEY_ESC
		clear; $world.each( &:work )
	end
	def click mouse #id, x, y
		for area in $world
			if mouse.x.between?( area.left_end, area.right_end ) and
				 mouse.y.between?( area.top, area.bottom )
			#LOG.debug "eid: %s bstate: %s" % [mouse.eid,mouse.bstate]
				id = KEY_TAB if mouse.bstate == ONE_FINGER
				id = KEY_SHIFT_TAB if mouse.bstate == TWO_FINGER
				area.action Activity[key:id], 
					mouse.x - area.left_end, mouse.y - area.top
				return
			end
		end
	end
	def run; COMMAND.action; end
	def clear; COMMAND.content.clear; COMMAND.work; end			
	def initialize
		loop do
			(writer = $world[$focus]).update#.work
    	#LOG.debug "focus: #{$focus}\n choice: #{writer.choice} "
    	input = getch #Event.poll 
    	writer.update
			#LOG.debug "input: #{input} "
    	case input
    		when KEY_MOUSE
    			click getmouse
				when KEY_ESC || KEY_EXIT
        	exit#-program
				when KEY_F12
					colortest
#				when KEY_F2
#					halt
				when KEY_UP, KEY_DOWN, KEY_LEFT, KEY_RIGHT
					writer.move input 
				when KEY_BACKSPACE
					$filter.chop!
					COMMAND.backspace#delch
					writer.work
				#when 
				#	$filter += " "
				when KEY_SPACE
					#COMMAND.deleteln
					next if $filter.empty?
					type = Type[symbol:$filter[0]] 
					name = $filter.dup
					$filter.clear	
					COMMAND.add type ? 
						eval(type.long).new(long:name) :
						name.parse.first #Text.new( long:
        when String, KEY_CTRL_SPACE 
        	writer.choice = 0
        	$filter += ((" " if input==KEY_CTRL_SPACE ) or input)
        	#Curses.draw input #$filter
        	COMMAND.draw input
        	COMMAND.update
        	writer.work
        else
        	next unless activity = Activity[key:input]		
        	if activity.is_a? Action and 
        		methods.include? activity.long.to_sym
        		activity.for(self).run 
        	else
						writer.action activity#, *$selection[$choice]#
					end
    	end
    end
  end
begin
#		loop do 
			ORB.new #rescue next
#		end unless LOADED
end #while loop?
#rescue
#	halt
ensure
#	LOG.debug "ensure"
#	use_default_colors()
  close_screen unless LOADED
end
