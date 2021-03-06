# encoding: ascii-8bit

# Collection of methods for creating, reading, and manipulating EBU-STL files.

module EbuStl
    class StlTools
        public

        BEHEADED = true

        # header + n tti_blocks
        def bytesize
            1024 + 128 * @tti.length
        end

        def blockcount
            @tti.length
        end

        def full?
            @full
        end

        def to_s      
            "#{@gsi.dfc}, full: #{full?}, #{@rows} lines, " +
            "upto #{@cols} chars, #{@sn} subtitles"
        end
    end
end

require_relative 'prettyprint.rb'
require_relative 'stltools_base.rb'
require_relative 'stltools_io.rb'
require_relative 'stltools_push.rb'
require_relative 'stltools_split.rb'

