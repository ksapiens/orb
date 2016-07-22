#!/usr/bin/ruby
require 'sdl2'
include SDL2

init(INIT_EVERYTHING ^ INIT_HAPTIC )
TTF.init

window = Window.create("testsprite",Window::POS_CENTERED, Window::POS_CENTERED, 640, 480, 0)
rnd = window.create_renderer(-1, 0)

font = TTF.open("/usr/share/fonts/freefont/FreeMonoBold.ttf", 30)

#def draw_three_types(rnd, font, x, ybase)
#
#  rnd.copy(rnd.create_texture_from(font.render_shaded("Foo", [255, 255, 255], [0,0,0])),
#                nil, SDL2::Rect.new(x, ybase+40, 100, 30))
#
#  rnd.copy(rnd.create_texture_from(font.render_blended("Foo", [255, 255, 255])),
#                nil, SDL2::Rect.new(x, ybase+80, 100, 30))
#end
rnd.draw_color = [155,0,0]

#rnd.fill_rect(SDL2::Rect.new(0,0,640,480))
#font.outline = 0
#font.style = TTF::Style::BOLD
#draw_three_types(rnd, font, 280, 50)

  surface = font.render_solid "TTF", [120,120,120]
  texture = rnd.create_texture_from surface
	rnd.draw_color = [200,200,200]
  
  rnd.copy(texture, nil, SDL2::Rect.new(50, 50, 100, 30))
  
  
loop do
  while ev = Event.poll
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
  rnd.present
  end

  #GC.start
  sleep 0.1
end
