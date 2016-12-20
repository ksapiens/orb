#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2016 kilian reitmayr

$LOAD_PATH << "#{File.dirname __FILE__}/."
require 'logger'
#require 'yaml'
require 'psych'

require 'view/terminal'
require "helpers.rb"
require "manual.rb"
require "entities.rb"
require "areas.rb"

#eval "config.default".read

NEXT, PREVIOUS = 1, -1
LOG = Logger.new("orb.log")
#$DEBUG = true
"~/.orb".mkdir unless "~/.orb/".exists?
if "~/.orb/config".exists?
	eval "~/.orb/config".read
else
	"./config.default".copy "~/.orb/config"
end	
init if __FILE__ == $0

$world = []
$filter=""
$selection = []
$focus = 2
$choice = 0
$counter = 0

DEFAULT = [
	Directory.new( "/", "root" ),
	Directory.new( ENV["HOME"], "home" ),
	Directory.new( ENV["PWD"], "work"),
	Container.new( (ENV["PATH"].split(":")-["."]).map{ |path| 
		Directory.new path }, "commands" ),
	Type.new(User, "people"),
	Type.new(Host, "web"),
	Type.new(Command, "history")

]

$world << (HEAD = Writer.new content:[ Host.new, User.new,
	Directory.new(ENV["PWD"],ENV["PWD"][1..-1]) ],
	x: LEFT, y: 0, height:1, delimiter:'', selection:false)#, width:cols
#LOG.debug ENV["PWD"]
$world << (COMMAND = Writer.new content:[], prefix: "> ",
	x: LEFT, y: lines-1, height:1, delimiter:' ', selection:false)

# main class
class ORB #< Window
	def initialize
		if "~/.orb/stack".exists?			
			$stack = Writer.new x: LEFT, file: "~/.orb/stack", 
				content: Psych.load_file( "~/.orb/stack".path ),
				delimiter:$/, selection:true
		else
			"~/.orb/stack".touch
			#$stack = Writer.new content:[], x: LEFT, selection:true, 
			#	file: "~/.orb/stack", delimiter:$/
			#for shell in %w[ bash zsh ]
			log = "#LOG\n"
			#log += ("~/.zsh_history").read.force_encoding(
			#	"Windows-1254").gsub /^:\s\d*:\d;/, '' if 
			#	"~/.zsh_history".exists?
			log += ("~/.bash_history").read if 
				"~/.bash_history".exists?
			#end  #parse#( "zsh" )	
			$stack = Writer.new( input:log,# log:true,
				summary:true, x: LEFT, selection:true,
				file: "~/.orb/stack", delimiter:$/ )
						
		end
#		$stack << DEFAULT
		$world << $stack
		#$help=Writer.new input: "help.txt".read
		#$world << $help
		#super 0,0,0,0
	end
	def help
		$stack << DEFAULT
		$world << $help
	end
#	def parse shell="bash" 
#	  log = 
#	  result = []
#	  if shell == "zsh"
#			log = log.force_encoding("Windows-1254").gsub /^:\s\d*:\d;/, ''
#		end	  
#		shapes = %r[(\w+\.(?:gg|de|com))]
			#|(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})
			
#		for entry in log.scan( shapes ).flatten.compact
			#entry = `file -i #{file}`.entry
		#	entry = file.item
#			result << Host.new( entry) #if entry
		#end
		#for domain in log.scan /\w+\.(?:gg|de|com|org|net)/
		#	result << Host.new( domain )
		#end
		#for ip in log.scan /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
		#	result << Host.new( ip )
#		end
#		result
#	end
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw \
				color: color[0], x: 5, y: i, area: Curses
		end
		getch 
	end
	def primary x, y
		#LOG.debug $world.size #input #$filter
		for area in $world
		#LOG.debug "o.rb primary  :#{area.height}"
			if 	x.between?( area.left, area.right ) && 
					y.between?( area.top, area.bottom )
				#LOG.debug "x: %s y: %s" % [area, y]
				area.primary x, y 
				break
			end
		end
		#cycle NEXT
	end
	def run
		loop do
			#clear
			#refresh
			#"TEST".draw area:Curses
			$world.each( &:update )
			$world[$focus].work
    	#p = Pad.new 100,10
    	#20.times do |i|; p.addstr i.to_s+$/; end
    	#p.refresh 0,0,2,2,10,10
    	
    	input = getch #Event.poll 
			$counter = 0
			
			#LOG.debug input
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			primary mouse.x, mouse.y
				when KEY_ESC || KEY_EXIT
        	exit
				when KEY_F12
					colortest
				when KEY_F1
					help
				when KEY_BACKSPACE
					$filter.chop!
				when KEY_NPAGE
					$world[$focus].page NEXT
				when KEY_PPAGE
					$world[$focus].page PREVIOUS
				when KEY_UP
					$choice=$choice.cycle NEXT, 0, $selection.size-1 
					$selection.clear
				when KEY_DOWN
					$choice=$choice.cycle PREVIOUS, 0, $selection.size-1 
					$selection.clear
				when KEY_RIGHT
					$focus=$focus.cycle NEXT, 2, $world.size-1					
				when KEY_LEFT
					$focus=$focus.cycle PREVIOUS, 2, $world.size-1									when KEY_TAB					
					primary *$selection[$choice]#.first
					$filter.clear
					$focus.cycle NEXT, 2, $world.size-1		
				when KEY_RETURN #KEY_ENTER || 
					COMMAND.primary
        when String
        	$counter,$choice = 0,0
					$filter = "" if $selection.empty?        	
        	
        	#	$filter.chop
        	$filter += input
        	$selection.clear
    	end
    end
  end
begin
		ORB.new.run if __FILE__ == $0
end
ensure
#	LOG.debug "ensure"
	use_default_colors()
  close_screen
end
