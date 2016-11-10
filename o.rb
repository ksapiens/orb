#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/."
require 'view/terminal'
require 'logger'
require "data/manual.rb"
require "helpers.rb"
require "entities.rb"
require "areas.rb"

LOG = Logger.new("orb.log")

# Globals
CONF = { 	spacing: 1,
					margin: 1,
				 	top:  1,
				 	left: 1,
				 	bottom: 1,
				 	limit: 12,				 	
					term: "'urxvt -e '",
					colors: {	#			R			G			B
						default:  	[ 100, 100, 100 ],						
						type: 			[ 300, 300, 700 ],
						executable: [ 700, 300, 300 ],
						item: 			[ 300, 700, 300 ],
						chardevice: [ 300, 700, 700 ],
						blockdevice:[ 700, 300, 700 ],
						special: 		[ 700, 300, 700 ],
						directory: 	[ 700, 700, 100 ],
						host: 			[ 100, 300, 700 ],
						highlight: 	[ 200, 200, 200 ] } }
CONF.each{ |k,v| eval "%s=%s" % [k.upcase, v] }#.to_s +"="+ v.to_s }
MENU = List.new ({ entries: [Directory.new( "/", "root" ),
									 	Directory.new( ENV["HOME"], "home" ),
									  Directory.new( ENV["PWD"], "work"),
									  #Type.new( "text", "/" ),
									  #Type.new( "image", "/" ),
									  #Type.new( "video", "/" ),
									  Recent.new,
									  Frequent.new( "frequent"),
									  Directory.new( ENV["HOME"]+"/.hostlist/","web"),
									  Executable.new("/usr/bin/find") ],
										x: LEFT, y: TOP, limit:LIMIT  
								})

 #<= devices, 
 #<= configuration, 
 #<= processes, parameters 
#<= hotplugged devices 

HELP = Text.new( { 
	entries: (open "help.txt").read, 
	x: MENU.right + MARGIN, y: TOP } )

WORKSPACE = [ MENU, HELP ]

@cmd = ""
class Command
	#def initialize args
end

# main class
class ORB 
	def initialize
		#@cmd = ""
		init
		ENV["COLUMNS"] = (cols-LIMIT-10).to_s
	end
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw color[0],-20,5,i,Curses
		end
	end
	def run
		loop do
			clear
			refresh
			WORKSPACE.each( &:draw )
    	input = getch #Event.poll 
			refresh  
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
					#LOG.debug "x: %s y: %s SESSION: %s" % [mouse.x, mouse.y, SESSION.length]
					for area in WORKSPACE
						if 	mouse.x.between?( area.left, area.right ) && 
								mouse.y.between?( area.top, area.bottom )
							area.primary mouse.x, mouse.y 
							break
						end
					end
				when KEY_EXIT
        	exit
				when KEY_F12
					colortest
        else
        	@cmd += input
        	LOG.debug @cmd
    	end
    end
  end

begin
		ORB.new.run if __FILE__ == $0
end
ensure
	use_default_colors()
  close_screen
end
