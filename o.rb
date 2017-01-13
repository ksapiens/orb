#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2016 kilian reitmayr

#$LOAD_PATH 
$: << __dir__ #"#{File.dirname __FILE__}/."
require 'logger'
#require 'yaml'
require 'psych'
require 'view/terminal'
require "helpers.rb"
require "manual.rb"
require "entities.rb"
require "writer.rb"

INVOKED = (__FILE__ == $0)
#eval "config.default".read
halt if INVOKED

NEXT, PREVIOUS = 1, -1
LOG = Logger.new("orb.log")
#$DEBUG = true
"~/.orb".mkdir unless "~/.orb/".exists?
"./config.default".copy "~/.orb/config" unless 
	"~/.orb/config".exists?
eval "~/.orb/config".read

init if INVOKED

$world,$selection = [],[]
$focus,$choice,$counter = 2,0,0
$filter=""

DEFAULT = [
	Directory.new( "/", "root" ),
	Directory.new( ENV["HOME"], "home" ),
	Directory.new( ENV["PWD"], "work"),
	Container.new( (ENV["PATH"].split(":")-["."]).map{ |path| 
		Directory.new path, :short }, "commands" ),
	Collection.new( ( [User,Host,Command] + 
		Entry.descendants ).map{|c| Type.new(c)}, "types"),
#	Type.new(User, "people"),
#	Type.new(Host, "web"),
#	Type.new(Config, "config"),
#	Type.new(Command, "history")
	
]

$world << (HEAD = Writer.new content:[ User.new, Host.new, 
	Directory.new(ENV["PWD"],ENV["PWD"][1..-1]) ],
	x: LEFT, y: 0, height:0, delimiter:'', selection:false)
$world << (COMMAND = Writer.new content:[],
	prefix: ">",	x: LEFT, y: lines-1, height:0,
	delimiter:' ', selection:false)

# main class
class ORB #< Window
	def initialize
		if "~/.orb/stack".exists?			
			$stack = Writer.new x: LEFT, file: "~/.orb/stack", 
				content: Psych.load_file( "~/.orb/stack".path ),
			  #height:10,y:TOP,
				delimiter:$/, selection:true#, raw: false
		else
			"~/.orb/stack".touch
			#for shell in %w[ bash zsh ]
			log = "__LOG\n"
			#log += ("~/.zsh_history").read.force_encoding(
			#	"Windows-1254").gsub /^:\s\d*:\d;/, '' if 
			#	"~/.zsh_history".exists?
			log += ("~/.bash_history").read if 
				"~/.bash_history".exists?
			#end  
			$stack = Writer.new( content:log,
				x: LEFT, selection:true, raw: false,
				file: "~/.orb/stack", delimiter:$/ )
		end
		$stack << DEFAULT
		$world << $stack
		#$help=Writer.new input: "help.txt".read
		#$world << $help
	end
	def help
		$stack << DEFAULT
		$world << $help
	end
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			setpos i,LEFT
			attron color_pair i
			addstr "#{color[0]} - #{color_content i}"
		end
		getch 
		clear
		$world.each( &:work )
	end
	def action id, x, y
		for area in $world

			if 	x.between?( area.left, area.right ) && 
					y.between?( area.top, area.bottom )
				#LOG.debug area.inspect
				#LOG.debug "x: %s y: %s" % [x, y]
				
				area.action id, x - area.left, y - area.top
				break
			end
		end
	end
	def run
		loop do
#			$world[$focus].work
 			$counter = 0
# 			$world.each( &:update )
 			$world.each( &:work )
    	#halt
    	input = getch #Event.poll 
			LOG.debug "input :#{input}"
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			action input, mouse.x, mouse.y
				when KEY_ESC || KEY_EXIT
        	exit
				when KEY_F12
					colortest
				when KEY_F1
					help
				when KEY_F2
					halt
				when KEY_BACKSPACE
					$filter.chop!
				when KEY_NPAGE
					$world[$focus].page NEXT
				when KEY_PPAGE
					$world[$focus].page PREVIOUS
				when KEY_DOWN
					$choice=$choice.cycle NEXT, 0, $selection.size-1 
					$selection.clear
				when KEY_UP
					$choice=$choice.cycle PREVIOUS, 0, $selection.size-1 
					$selection.clear
				when KEY_RIGHT
					$focus=$focus.cycle NEXT, 2, $world.size-1					
				when KEY_LEFT
					$focus=$focus.cycle PREVIOUS, 2, $world.size-1
				when KEY_TAB, KEY_CTRL_A
					
					action input, *$selection[$choice]#.first
#					$filter.clear
										
					#$focus.cycle NEXT, 2, $world.size-1		
				when KEY_RETURN #KEY_ENTER || 
					COMMAND.action #primary
        when String
        	$world[$focus].page = 0
        	$counter,$choice = 0,0
					$filter = "" if $selection.empty?        	
        	#	$filter.chop
        	$filter += input
        	$selection.clear
    	end
    end
  end
begin
		ORB.new.run if INVOKED
end
ensure
#	LOG.debug "ensure"
	use_default_colors()
  close_screen if INVOKED
end
