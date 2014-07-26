# encoding: ascii-8bit

# Implements (most of) the specifications.
# http://tech.ebu.ch/docs/tech/tech3264.pdf
#
#
#
# Purpose:
#   Create stl subtitle file supporting colors, boldface, italics,
#   underlining. I wrote this to get formatted subtitles on youtube.
#
#
#
# Usage:
#   Some simple examples are at the end of this file. A very basic usage:
#
#      EbuStl::StlTools.new do
#         subtitle 0, 10, 'Subtitle from 0s to 10s'
#         output '/path/to/file'
#      end
#
#
#
# License:
#   None. Do whatever you want.
#   I reccommend you start by fixing bugs. :w
#
#
#

require 'bindata'
require 'date'
require_relative 'lib/simple_parser.rb'
require_relative 'lib/valid_utf8.rb'
require_relative 'lib/english.rb'
require_relative 'lib/util.rb'
require_relative 'lib/codepage.rb'
require_relative 'lib/bindata.rb'
require_relative 'lib/terminal_codes.rb'
require_relative 'lib/stltools.rb'


################################################################################
###############################TESTING/DEBUG####################################
################################################################################

# For testing, run
#  Write a simple file
#    ruby 'this_script.rb' > /tmp/test.stl
#  Read a file and pretty print in utf-8
#    ruby 'this_script.rb' < /tmp/test.stl


avail = IO.select([$stdin],[$stdout],[$stderr],0)


# Testing: Read data from stdin. Write to stdout
if caller.empty? &&  !avail[0].empty? && !avail[1].empty?
    # This would run some checks on the header.
    #   stl   = EbuStl::StlTools.read($stdin)
    # Which fails because some programs just ignore the header.
    # Use the below to skip the header and use the default one.
    EbuStl::StlTools.read($stdin, EbuStl::StlTools::BEHEADED).pprint($stdout)
    

# Testing: Write data to stdout.
elsif caller.empty? && !avail[1].empty?
    # Setup new stl container with 17 lines, 38 char/line
    EbuStl::StlTools.new(17,38) do
        
        subtitle 0, 10, 'Times are given in seconds'

         # bad data gets ignored silently
        subtitle 0, 10, Proc.new{}
        
        subtitle 10, 20, <<-styled.gsub(/^\s+/,'')
        none
        <color=green>colored</color>
        <b>bold</b>
        <i>italic</i>
        <u>underline</u>
        <bgcolor=#{0x00FF00}>background color</bgcolor>
        Colors are given in rgb, or by name.
        styled

        # Invalid formatting tags won't make it crash.
        subtitle 0, 5, [Array.new(32){['<','>','u','i'].sample}.join]
        

        subtitle 20, 25, <<-MULTI.gsub(/^\s+/,'')
        <u>+U <b>+B <bgcolor=green>+BG <color=red>+COL</color></bgcolor></b></u>
        MULTI

        subtitle 25,30, <<-SEMIBAD.gsub(/^\s+/,'')
        </color></color><color=blue>blue <color=green>green
        <b>It works</b> <u>I don't reccomend it. And overlong lines get trimmed.
        SEMIBAD

        subtitle 30, 35, <<-ESCAPE.gsub(/^\s+/,'')
        Simple escape sequences: <u>&lt;supported&gt;</u>
        ESCAPE
        
        # All glyphs from the chosen charset are available.
        subtitle 35, 40, "Use unicode: \xe2\x84\xa2, \xe2\x85\x9e".
                         force_encoding(Encoding::UTF_8)

        # Valid encodings are converted (if supported by ruby).
        subtitle 45,50, 'It tries to convert non-utf8.'.encode(Encoding::UTF_16)

        # Generates 200 random bytes and sets a random encoding.
        bad_data= Array.new(0xc8){[rand(0x100)].pack('C')}.each_slice(0x1d).
                  map{|x|x.join}.join("\n").force_encoding(Encoding.list.sample)
        
                  
        # Invalid encodings won't make it crash.
        subtitle 50, 55, bad_data
      
        output $stdout
    end
end
