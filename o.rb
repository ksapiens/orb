#!/usr/bin/env ruby

# ORB - Omnipercipient Resource Browser
# 
# 	Launcher
#
# copyright 2017 kilian reitmayr
$LOAD_PATH  << __dir__ #"#{File.dirname __FILE__}/."
require 'pry'
require 'logger'
require 'sequel'
require "helpers.rb"

"~/.orb".mkdir unless "~/.orb/".exists?
"./config.default".copy "~/.orb/config" unless 
	"~/.orb/config".exists?
eval "~/.orb/config".read
LOG = Logger.new("orb.log")
FIRST = !"~/.orb/db.sqlite".exists? 
DB = Sequel.sqlite "~/.orb/db.sqlite".path
#DB.loggers << LOG

if FIRST	
	DB.create_table( :items ) do #objects
  	primary_key :id
  	Integer :type_id #meaning identity  
  	String :long #, :unique => true 
  	String :short
  	String :extra
  	String :color #_id, :colors
  	#String :found_in #file
  	#Integer :position
  	#TrueClass :executable
  	DateTime :time
	end #unless DB.table_exists? :items
 	
	DB.create_table( :relations ) do
  	primary_key :id
  	foreign_key :first_id, :items#, :on_delete => :cascade
  	foreign_key :second_id, :items#, :on_delete => :cascade
	end 
end
require "entities.rb"
require 'view/terminal'
require "manual.rb"
require "writer.rb"

halt unless ($* & [ "-d", "debug" ]).empty?
LOADED = (__FILE__ != $0)
NEXT, PREVIOUS = 1, -1

if FIRST
	#fork do
	DB.transaction do
		TYPE.each{ |type,var| Type.create long:type, short:var.first,
			color:var[1], extra:var.last }
		Textfile.create( long: "./help.txt".path, short: "help", 
			extra: "click here or type 'help' and press TAB" )
		Directory.create( long: "/", short: "root" )
		Directory.create( long: ENV["HOME"], short: "home" )
		Container.create( long: "commands", items: 
			(ENV["PATH"].split(":")-["."]).map{ |path| 
				Directory.new( long: path, short: :name ) } )
		#Item.descendants.each{ |name|	Type.create long: name }
		#Collection.create( long: "types", items: Type.all )
		#log = "__LOG\n"
		#log += ("~/.zsh_history").read.force_encoding(
		#	"Windows-1254").gsub /^:\s\d*:\d;/, '' if 
		#	"~/.zsh_history".exists?
		log = ("~/.bash_history").read if "~/.bash_history".exists?
		for line in log.lines
			line.strip.split("|").each{ |cmd| 
				Command.build( cmd ) } unless line.strip.empty?
		end if log
	end
	#end
end

DEFAULT = [
	Textfile[ short: "help" ],
	Directory[ short: "root" ],
	Directory[ short: "home" ],
	Directory.new( long: '.'.path, short: "current"),
	Container[ long: "commands" ],
	#Collection[ long: "types" ]
	Type[ long: "Type" ]
]

init unless LOADED

$world,$selection = [],[]
$focus,$choice,$counter = 2,0,0
$filter=""

$world = [ 
	(HEAD = Writer.new content:[
		User.new( long: ENV["USER"] ),
		Host.new( long: (`hostname`.strip or "localhost") ), 
		Directory.new( long: '.'.path, short: '.'.path[1..-1] )],
		x: LEFT, y: 0, height:0, delimiter:'', selection:false),
	(COMMAND = Writer.new	prefix: ">", x: LEFT, 
		y: lines-1, height:0, delimiter:' ', selection:false),
	(STACK = Writer.new content: 
		DEFAULT + Item.order(:time).reverse.all, 
	 	x: LEFT, delimiter:$/,	selection:true ) ]

# main class
class ORB #< Window
	#def help
		#$stack << DEFAULT
	#	$world << Writer.new content: "help.txt".read
	#end
  def colortest
		clear
		COLOR.each_with_index do |color,i|
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
				
				#LOG.debug "e: %s b: %s" % [mouse.eid, mouse.bstate ]
				area.action id, x - area.left, y - area.top
				break
			end
		end
	end
	def run
		loop do
#			$world[$focus].work
 			$counter = 0
#			$world.each( &:update )
 			$world.each( &:work )
    	input = getch #Event.poll 
			LOG.debug "input :#{input}"
    	case input
    		when KEY_MOUSE
    			mouse = getmouse
    			action mouse.bstate, mouse.x, mouse.y
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
				when KEY_TAB, KEY_SHIFT_TAB, KEY_CTRL_A
					action input, *$selection[$choice]#.first
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
		ORB.new.run unless LOADED
end
ensure
#	LOG.debug "ensure"
	use_default_colors()
  close_screen unless LOADED
end
