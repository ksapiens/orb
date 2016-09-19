#!/usr/bin/ruby
$LOAD_PATH << "#{File.dirname __FILE__}/lib/"
require 'manparser.rb'

 
eval "ManPage.new('%s').%s" %  [ $*[0], $*[1..-1].join(" ") ] if __FILE__ == $0


