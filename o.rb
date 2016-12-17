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

DEFAULT = [
	Directory.new( "/", "root" ),
	Directory.new( ENV["HOME"], "home" ),
	Directory.new( ENV["PWD"], "work"),
	Container.new( (ENV["PATH"].split(":")-["."]).map{ |path| 
		Directory.new path }, "commands" ),
	Type.new(User),
	Type.new(Host, "web"),
	Type.new(Command, "history"),
	#Type.new(Executable) 
]
#MENU = List.new ({ content: 
#	Psych.load( "menu.default".read ),
#	x: LEFT, y: TOP, limit:LIMIT  
#	})
HEAD = Writer.new content:[ Host.new, User.new,#, 
	Directory.new(ENV["PWD"],ENV["PWD"][1..-1]) ],
	x: LEFT, y: 0, height:1, delimiter:''#, width:cols
#LOG.debug ENV["PWD"]
COMMAND = Writer.new content:[], prefix: "> ",#, delimiter: " ",
	x: LEFT, y: lines-1, height:1, delimiter:' '
$workspace = [ HEAD, COMMAND ]
#$workspace = [ COMMAND ]
#HELP = Writer.new	text: "help.txt".read, width:cols - LIMIT 

#$workspace << HELP

#$history = { commands: {}, directory: {}, web: {} }
$filter=""
$selection = []
$focus = 2
#$stack = 

# main class
class ORB 
	def initialize
		if "~/.orb/stack".exists?			
			$stack = Writer.new x: LEFT, file: "~/.orb/stack", 
				content: Psych.load_file( "~/.orb/stack".path ),
				delimiter:$/, selection:true
		else
			"~/.orb/stack".touch
			$stack = Writer.new content:[], x: LEFT, selection:true, 
				file: "~/.orb/stack", delimiter:$/
			$stack << parse#( "zsh" )
			
		end
		$stack << DEFAULT
		$workspace << $stack
	end
	def help
		$stack << DEFAULT
		$workspace << HELP
	end
	def parse shell="bash" 
	  log = ("~/."+shell+"_history").read
	  result = []
	  if shell == "zsh"
			log = log.force_encoding("Windows-1254").gsub /^:\s\d*:\d;/, ''
		end	  
		shapes = %r[(\w+\.(?:gg|de|com))]
			#|(\d{1,3}.\d{1,3}.\d{1,3}.\d{1,3})
			
		for entry in log.scan( shapes ).flatten.compact
			#entry = `file -i #{file}`.entry
		#	entry = file.item
			result << Host.new( entry) #if entry
		#end
		#for domain in log.scan /\w+\.(?:gg|de|com|org|net)/
		#	result << Host.new( domain )
		#end
		#for ip in log.scan /\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}/
		#	result << Host.new( ip )
		end
		for lines in log.lines
			for line in lines.split "|"
				parts = line.split(/(-{1,2}[^-]*)/)#[1..-1]				
				path = `#{shell} -c "which #{parts[0].split[0]} 2> /dev/null"`
				next if path.empty?#if path[/: no /] || path[/not found/]
				result << command = Executable.new(path)				 
				#command = command[/aliased to (.*)$/]
				command.history << Command.new( [command] + 
					parts[1..-1].reject(&:empty?).map{|part| Option.new part} )
			end
		end if false
		result
	end
  def colortest
		clear
		COLORS.each_with_index do |color,i|
			"#{color[0]} - #{color_content i}".draw \
				color: color[0], x: 5, y: i, area: Curses
		end
		getch 
	end
	def primary x, y
		#LOG.debug $workspace.size #input #$filter
		for area in $workspace
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
	def cycle direction
		return if $workspace.select(&:paging?).empty? #each_with_index.map{|area,index| 
		#	i if area.paging? && index != $focus }.compact[$focus+direction]
		#LOG.debug $focus
		$focus += direction
		$focus = 0 if $focus > $workspace.size-1
		$focus = $workspace.size-1 if $focus < 0
		cycle direction unless $workspace[$focus].paging?
	end
	def run
		loop do
			clear
			refresh
			#"TEST".draw area:Curses
			$workspace.each( &:write )
    	input = getch #Event.poll 
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
					$workspace[$focus].page NEXT
				when KEY_PPAGE
					$workspace[$focus].page PREVIOUS
				when KEY_RIGHT
					cycle NEXT					
				when KEY_LEFT
					cycle PREVIOUS
				when KEY_TAB					
					#LOG.debug "o.rb run 2:#{$workspace[2].top}"
					primary *$selection.first
					$filter.clear
				when KEY_RETURN #KEY_ENTER || 
					COMMAND.primary
        when String
					$filter = "" if $selection.empty?        	
        	$selection.clear
        	$filter += input
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
