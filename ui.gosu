#!/usr/bin/env ruby
$LOAD_PATH << "#{File.dirname __FILE__}/lib/"

require 'rubygems'
require 'gosu'
require 'sdl2'
include SDL2
require "dbmanager.rb"

CONF = { 	:FONT_SIZE => 40,
				 		:PADDING => 20 }
UILOG = Logger.new($stdout)

module Visual
	attr_accessor :x, :y, :image
	def render
		@image = Gosu::Image.from_text( self.to_s,CONF[:FONT_SIZE] )
		UILOG.debug @image
	end
	def draw x,y
		@image.draw x,y,0
	end	
end	
class Tag 
	include Visual
	def to_s
		name
	end
end
class Item
	include Visual
	def to_s
		path.split("/")[-1]
	end	
end

class List < Array
	attr_accessor :x, :y, :width, :height
	def initialize a=[], x=CONF[:PADDING],y=CONF[:PADDING]
		super a
		each( &:render )
		@x, @y = x, y
		@height = length * CONF[:FONT_SIZE]
		@width = max{ |a,b| a.image.width <=> b.image.width }.image.width
	end	
	def draw
		each_with_index do |entry, i|
			entry.draw @x, @y + i * CONF[:FONT_SIZE]
    Gosu::gl(z) { 
    	glEnable(GL_TEXTURE_2D)
    	glBindTexture(GL_TEXTURE_2D, info.tex_name)
    }
		end
	end
		
end
		
MENU = List.new ([ Item[:path=>"/home/key/fun"],
										Tag[:name=>"scan"] ])
SESSION = [ MENU ]

WIDTH, HEIGHT = 600, 600

class SIA < Gosu::Window
  
  def initialize
    super WIDTH, HEIGHT
    self.caption = "SIA UI"
    #@background = Gosu::Image.new "WallpaperXXL.png"
  end
  
  def draw
    #@background.draw 0, 0, 0
    #eX, eY = CONF[:PADDING], CONF[:PADDING]
    #for entry in MENU
    #	entry.draw eX, eY
    # eY += CONF[:FONT_SIZE]
    #end
	
		SESSION.each( &:draw )

    ev = Event.poll 
    case ev
    	when Event::TouchFinger
				p ev 
				
			when Event::KeyDown
      	if ev.scancode == Key::Scan::ESCAPE
        	exit
      	end
    	when Event::Quit
      	exit
    end
  end
  
  def needs_cursor?
    #true
    false
  end
  
end

SIA.new.show if __FILE__ == $0
