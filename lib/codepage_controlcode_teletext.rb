# encoding: ascii-8bit

# Control codes for text color, boldface, and graphics mode.
# See bighole.nl/pub/mirror/homepage.ntlworld.com/kryten_droid/teletext/spec/teletext_spec_1974.htm 
# and riscos.com/support/developers/bbcbasic/part2/teletext.html 
# for more info on formatting with teletext codes.  

module EbuStl
    module CodePage
        module ControlCode
            module TeleText
                DEFINED = {}
                ("\x00".."\x1f").to_a.each { |code| DEFINED[code] = true }
                
                COLORS = { 
                    :text => {
                        :black   => "\x00",
                        :red     => "\x01",
                        :green   => "\x02",
                        :yellow  => "\x03",
                        :blue    => "\x04",
                        :magenta => "\x05",
                        :cyan    => "\x06",
                        :white   => "\x07"
                    },
                    :graphics => {
                        :black   => "\x10",
                        :red     => "\x11",
                        :green   => "\x12",
                        :yellow  => "\x13",
                        :blue    => "\x14",
                        :magenta => "\x15",
                        :cyan    => "\x16",
                        :white   => "\x17"
                    }
                }
                BOLD = { true => "\x08", false => "\x09"}
                SIZE = { :normal       => "\x0c", :double_height => "\x0d",
                         :double_width => "\x0e", :double_both   => "\x0f" }

                GRAPHICS = { :contiguous => "\x19", :separated => "\x1a",
                             :hold       => "\x1e", :release   => "\x1f",
                             :hide       => "\x18"}
                BACKGROUND = { :black => "\x1c", :new => "\x1d" }

                BOLD.default              = BOLD[false]
                SIZE.default              = SIZE[:normal]
                GRAPHICS.default          = GRAPHICS[:release]
                BACKGROUND.default        = BACKGROUND[:black]
                COLORS.default            = COLORS[:text]
                COLORS[:text].default     = COLORS[:text][:white]
                COLORS[:graphics].default = COLORS[:graphics][:black]
                
                NEWLINE = ControlCode::NEWLINE
                FILLER = ControlCode::FILLER
                
                # byte representing a 2x3 black-white image
                #
                # box = [ [0,1],
                #         [0,1]
                #         [0,1]
                #       ]
                # box = [ 0,1,0,1,0,1]
                # => 2x3 image with a white column to the left, black to the right
                def self.box_code(box)
                    box = box.flatten
                    [box.join.reverse.to_i(2)+32+32*box[5]].pack('C')
                end
            end
        end
    end
end
