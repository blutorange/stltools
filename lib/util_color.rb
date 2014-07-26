# encoding: ascii-8bit

# Color conversion and color names.

module EbuStl
    module Util
        module Color
            NAMES = {
                :white  => 0xFFFFFF, :black   => 0x000000,
                :red    => 0xFF0000, :green   => 0x00FF00,
                :blue   => 0x0000FF, :yellow  => 0xFFFF00,
                :cyan   => 0x00FFFF, :magenta => 0xFF00FF
            }
            DEFAULT_COLOR = 0xFFFFFF
            
            GREY_THRESHOLD  = 0.1 # saturation (black, white, or grey)
            WHITE_THRESHOLD = 0.9 # value
            BLACK_THRESHOLD = 0.1 # value
            HUES            = [:red, :yellow, :green, :cyan, :blue, :magenta]
            SCALE           = 1.0/255.0
            PALETTE         = [ 0xFFFFFF, 0x000000,
                                0xFF0000, 0x00FF00, 0x0000FF,
                                0xFFFF00, 0xFF00FF, 0x00FFFF
                              ]

            # rgb => h(ue)-s(aturation)-v(alue)
            def self.hsv(hex)
                return 0.0,0.0,0.0 if hex == 0
                r = ((hex&0xFF0000) >> 16) * SCALE
                g = ((hex&0x00FF00) >> 8 ) * SCALE
                b =  (hex&0x0000FF) * SCALE
                cmin, cmax = [r,g,b].minmax
                delta = (cmax-cmin).to_f
                case cmax
                when r
                    h = ((g-b)/delta)%6
                when g
                    h = ((b-r)/delta)+2.0
                when b
                    h = ((r-g)/delta)+4.0
                end
                    s = delta / cmax.to_f 
                    v = cmax.to_f
                return h,s,v
            end
            
            # returns the closest color that best matches the argument
            def self.nearest_color(hex)
                # get hsv
                h,s,v = Color.hsv(hex)
                # lookup table
                if s <= GREY_THRESHOLD
                    if v >= WHITE_THRESHOLD
                        return :white
                    elsif v <= BLACK_THRESHOLD
                        return :black
                    end
                else
                    return HUES[h.round % 6]
                end
            end
            
            # replaces humanly readable color names with their rgb equivalent
            def self.human_colors(line)
                line.gsub(/<(bg){0,1}color=([^>0-9]+)>/) do |match|
                    if hex = NAMES[$2.downcase.to_sym]
                        "<#{$1}color=#{hex}>"
                    else
                        "<#{$1}color=#{DEFAULT_COLOR}>"
                    end
                end
            end
        end
    end
end
