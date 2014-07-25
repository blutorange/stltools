# encoding: ascii-8bit
# <do not change this>
#
#
#
# Purpose: Create stl subtitle file supporting colors, boldface, italics,
#          underlining; in order to get formatted subtitles on youtube.
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
# License: None. Do whatever you want. I reccommend you start by fixing bugs. :w
#
#
#
# Based upon http://tech.ebu.ch/docs/tech/tech3264.pdf
#
# See bighole.nl/pub/mirror/homepage.ntlworld.com/kryten_droid/teletext/spec/teletext_spec_1974.htm 
# and riscos.com/support/developers/bbcbasic/part2/teletext.html 
# for more info on formatting with teletext codes.  

require 'bindata'
require 'date'
require_relative 'valid_utf8.rb'
require_relative 'save_stream_simple_parser.rb'


module EbuStl

    module English
        BODY = {
                :sgn => 'subtitle group number',
                :sn  => 'subtitle number',
                :ebn => 'extension block number',
                :cs  => 'cumulative status',
                :tci => 'time code in',
                :tco => 'time code out',
                :vp  => 'vertical position',
                :jc  => 'justification code',
                :cf  => 'comment flag',
                :tf  => 'text field'
        }
        HEADER = {
            :cpn => 'code page number',
            :dfc => 'disk format code',
            :dsc => 'display standard code',
            :cct => 'character code table number',
            :lc  => 'language code',
            :opt => 'original program title',
            :oet => 'original episode title',
            :tpt => 'translated program title',
            :tet => 'translated episode title',
            :tn  => 'translator\'s name',
            :tcd => 'translator\'s contact details',
            :slr => 'subtitle list reference code',
            :cd  => 'creation date',
            :rd  => 'revision date',
            :rn  => 'revision number',
            :tnb => 'total number tti blocks',
            :tns => 'total number subtitles',
            :tng => 'total number subitle groups',
            :mnc => 'maximum number of displayable chars/row',
            :mnr => 'maximum number of displayable rows',
            :tcs => 'time code status',
            :tcp => 'time code: start-of-program',
            :tcf => 'time code: first-in-cue',
            :tnd => 'total number of disks',
            :dsn => 'disc sequence number',
            :co  => 'country of origin',
            :pub => 'publisher',
            :en  => 'editor\'s name',
            :ecd => 'editor\'s contact details',
            :sb  => 'spare bytes',
            :uda => 'user defined area'
        }
    end
    
    module Util
        BOXDRAWINGS = { :bar  => {:hor => "\xe2\x94\x81", :ver => "\xe2\x94\x83"}, #bold
                        :dbar => {:hor => "\xe2\x95\x90", :ver => "\xe2\x95\x91"}, #double
                        :lbar => {:hor => "\xe2\x94\x88", :ver => "\xe2\x94\x8a"}, #light
                        :nbar => {:hor => "\xe2\x94\x80", :ver => "\xe2\x94\x82"}, #normal
                        # bold edges
                        :edge => {:tr => "\xe2\x94\x93",
                                  :tl => "\xe2\x94\x8f",
                                  :bl => "\xe2\x94\x97",
                                  :br => "\xe2\x94\x9b"
                                 },
                        # double edges
                        :dedges => { :tr => "\xe2\x95\x97",
                                     :tl => "\xe2\x95\x94",
                                     :bl => "\xe2\x95\x9a",
                                     :br => "\xe2\x95\x9d"
                                    },
                        # combined forms
                        :comb => { :vernr => "\xe2\x94\xa0", :vernl => "\xe2\x94\xa8", # |-  -|
                                   :verr  => "\xe2\x94\xa3", :verl  => "\xe2\x94\xab",
                                   :cross => "\xe2\x95\x8b",
                                   :horu  => "\xe2\x94\xbb", :hord  => "\xe2\x94\xb3"
                                 }
                      }
        
        BOXDRAWINGS.each_value{ |v| v.each_value { |w| w.force_encoding(Encoding::UTF_8)}}

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
                              ]*2
            
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
        
        def cjust(len, pad=' ')
            rjust((length+len)/2,pad).ljust(len,pad)
        end
        
        def overlap?(rng)
            include?(rng.first) || include?(rng.last) ||
            rng.include?(first) || rng.include?(last)
        end 
        
        # 0x04fc13 => "\x4fc13"
        def self.int_to_bytes(x)
            x.to_s(2).each_char.each_slice(8).map{|b|b.join.to_i(2)}.pack('C*')
        end              

        # converts seconds to hours, minutes, seconds, milliseconds
        def self.ss2hhmmssms(sec)
            hh = (sec/3600).floor
            mm = ((sec-hh*3600)/60).floor
            ss = (sec-hh*3600-mm*60)
            ms = ((ss % 1)*1000).round
            return hh,mm,ss.floor,ms
        end
        
        # time given in seconds
        # hour, minute, seconds, frame
        def self.timecode(time, fps)
            time = ss2hhmmssms(time.to_f)
            time[3] = (time[3].to_f*fps*0.001).floor
            # enforce bounds
            time[3] = fps.ceil-1 if time[3] >= fps
            return time.pack('CCCC')
        end
       
        def self.seconds(tcode, fps)
            tcode.getbyte(0)*3600.0 + tcode.getbyte(1)*60.0 +
            tcode.getbyte(2)        + tcode.getbyte(3)*fps*0.001
        end
    
        # yymmdd
        def self.date(date)
            date.to_datetime.strftime('%y%m%d')
        end

        # takes file name or io object
        # If no block is given, it returns io object and whether the file was
        #  opened by this method, and should be closed manually.
        # If a block is given, calls it with the io object and closes it
        #  afterwards if neccessary. Redirects all exceptions to IOError.
        def self.iostream(file, mode='rb', &block)
            needs_closing = false
            # file name or IO object?
            if ((mode == 'wb' || mode == 'r') && file.respond_to?(:write)) ||
               ((mode == 'rb' || mode == 'w') && file.respond_to?(:read))
                io = file
            elsif file.respond_to?(:to_s)
                file = File.expand_path(file.to_s)
                begin
                  io = File.open(file, mode)
                  needs_closing = true
                rescue Errno, TypeError, ArgumentError => e
                    raise IOError, *e
                end
            else
                raise IOError,:invalid_file_object
            end
            if block_given?
                begin
                    yield io
                rescue Errno, TypeError, ArgumentError, IOError => e
                    raise IOError, e.message, e.backtrace
                end
                io.close if needs_closing
            else
                return io, needs_closing
            end
        end

        # Safe monkey patching for instance methods.
        # new_mets = { :foo => [Bar, instance_method] }
        def self.define_method_locally(new_mets, &block)
            old_mets = []
            new_mets.each_pair do |name,info|
                _class = info[0]
                _met   = info[1]
                # save old method
                if _class.method_defined?(name)
                  old_mets.push([_class,name,_class.instance_method(name)]) 
                end
                #define new methods
                _class.send(:define_method, name, _met)
            end
            yield
            # clear methods
            new_mets.each_pair do |name, info|
                info[0].send(:remove_method, name)
            end
            # restore old methods
            old_mets.each do |old|
                old[0].send(:define_method, old[1], old[2])
            end
        end
        
        # Shortcut for define_method_locally for methods within this module.
        # Example usage:
        #
        #    Util.monkey_patch(:overlap? => Range, :cjust => String) do
        #        puts (1..7).overlap?(2..3)
        #        puts '<' + 'Adjust me'.cjust(30) + '>'
        #    end
        #
        #    (1..7).overlap?(2..3) => NoMethodError
        #
        def self.monkey_patch(typewriter, &bananas)
            hash = {}
            typewriter.each_pair do |_met, _class|
                hash[_met] = [_class, Util.instance_method(_met)]
            end
            define_method_locally(hash, &bananas)
        end
    end
    
    module CodePage
       
        # unit mapping
        UTF8 = Array.new(0x80) { |i| i }
        UTF8.map! { |i| (i<= 0x1f) ? nil : i}
        UTF8.delete_if { |i| i && i >= 0x7f}

        # codepage graphics
        CP_GRAPHICS_B2U = []
        CP_GRAPHICS_B2U[0x01] = 0xe298ba
        CP_GRAPHICS_B2U[0x02] = 0xe298bb
        CP_GRAPHICS_B2U[0x03] = 0xe299a5
        CP_GRAPHICS_B2U[0x04] = 0xe299a6
        CP_GRAPHICS_B2U[0x05] = 0xe299a3
        CP_GRAPHICS_B2U[0x06] = 0xe299a0
        CP_GRAPHICS_B2U[0x07] = 0xe280a2
        CP_GRAPHICS_B2U[0x08] = 0xe29798
        CP_GRAPHICS_B2U[0x09] = 0xe2978b
        CP_GRAPHICS_B2U[0x0a] = 0xe29799
        CP_GRAPHICS_B2U[0x0b] = 0xe29982
        CP_GRAPHICS_B2U[0x0c] = 0xe29980
        CP_GRAPHICS_B2U[0x0d] = 0xe299aa
        CP_GRAPHICS_B2U[0x0e] = 0xe299ac
        CP_GRAPHICS_B2U[0x0f] = 0xe298bc
        CP_GRAPHICS_B2U[0x10] = 0xe296ba
        CP_GRAPHICS_B2U[0x11] = 0xe29784
        CP_GRAPHICS_B2U[0x12] = 0xe28695
        CP_GRAPHICS_B2U[0x13] = 0xe280bc
        CP_GRAPHICS_B2U[0x14] = 0x00c2b6
        CP_GRAPHICS_B2U[0x15] = 0x00c2a7
        CP_GRAPHICS_B2U[0x16] = 0xe296ac
        CP_GRAPHICS_B2U[0x17] = 0xe286a8
        CP_GRAPHICS_B2U[0x18] = 0xe28691
        CP_GRAPHICS_B2U[0x19] = 0xe28693
        CP_GRAPHICS_B2U[0x1a] = 0xe28692
        CP_GRAPHICS_B2U[0x1b] = 0xe28690
        CP_GRAPHICS_B2U[0x1d] = 0xe28694
        CP_GRAPHICS_B2U[0x1e] = 0xe296b2
        CP_GRAPHICS_B2U[0x1f] = 0xe296bc

        module Header
            # Code page 437
            module UnitedStates
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }
                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c3a4
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c3a5
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c3ab
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c3af
                BYTE_TO_UTF8[0x8c] = 0x00c3ae
                BYTE_TO_UTF8[0x8d] = 0x00c3ac
                BYTE_TO_UTF8[0x8e] = 0x00c384
                BYTE_TO_UTF8[0x8f] = 0x00c385
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c3a6
                BYTE_TO_UTF8[0x92] = 0x00c386
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c3b6
                BYTE_TO_UTF8[0x95] = 0x00c3b2
                BYTE_TO_UTF8[0x96] = 0x00c3bb
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c3bf
                BYTE_TO_UTF8[0x99] = 0x00c396
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c2a2
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c2a5
                BYTE_TO_UTF8[0x9e] = 0xe282a7
                BYTE_TO_UTF8[0x9f] = 0x00c692
                BYTE_TO_UTF8[0xa0] = 0x00c3a1
                BYTE_TO_UTF8[0xa1] = 0x00c3ad
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c3b1
                BYTE_TO_UTF8[0xa5] = 0x00c391
                BYTE_TO_UTF8[0xa6] = 0x00c2aa
                BYTE_TO_UTF8[0xa7] = 0x00c2ba
                BYTE_TO_UTF8[0xa8] = 0x00c2bf
                BYTE_TO_UTF8[0xa9] = 0xe28c90
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2a1
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2bb
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0xe295a1
                BYTE_TO_UTF8[0xb6] = 0xe295a2
                BYTE_TO_UTF8[0xb7] = 0xe29596
                BYTE_TO_UTF8[0xb8] = 0xe29595
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0xe2959c
                BYTE_TO_UTF8[0xbe] = 0xe2959b
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0xe2959e
                BYTE_TO_UTF8[0xc7] = 0xe2959f
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0xe295a7
                BYTE_TO_UTF8[0xd0] = 0xe295a8
                BYTE_TO_UTF8[0xd1] = 0xe295a4
                BYTE_TO_UTF8[0xd2] = 0xe295a5
                BYTE_TO_UTF8[0xd3] = 0xe29599
                BYTE_TO_UTF8[0xd4] = 0xe29598
                BYTE_TO_UTF8[0xd5] = 0xe29592
                BYTE_TO_UTF8[0xd6] = 0xe29593
                BYTE_TO_UTF8[0xd7] = 0xe295ab
                BYTE_TO_UTF8[0xd8] = 0xe295aa
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0xe2968c
                BYTE_TO_UTF8[0xde] = 0xe29690
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00ceb1
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00ce93
                BYTE_TO_UTF8[0xe3] = 0x00cf80
                BYTE_TO_UTF8[0xe4] = 0x00cea3
                BYTE_TO_UTF8[0xe5] = 0x00cf83
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00cf84
                BYTE_TO_UTF8[0xe8] = 0x00cea6
                BYTE_TO_UTF8[0xe9] = 0x00ce98
                BYTE_TO_UTF8[0xea] = 0x00cea9
                BYTE_TO_UTF8[0xeb] = 0x00ceb4
                BYTE_TO_UTF8[0xec] = 0xe2889e
                BYTE_TO_UTF8[0xed] = 0x00cf86
                BYTE_TO_UTF8[0xee] = 0x00ceb5
                BYTE_TO_UTF8[0xef] = 0xe288a9
                BYTE_TO_UTF8[0xf0] = 0xe289a1
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe289a5
                BYTE_TO_UTF8[0xf3] = 0xe289a4
                BYTE_TO_UTF8[0xf4] = 0xe28ca0
                BYTE_TO_UTF8[0xf5] = 0xe28ca1
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0xe28988
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0xe28899
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0xe2889a
                BYTE_TO_UTF8[0xfc] = 0xe281bf
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
            end
            
            # Code page 850
            module Multilingual
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }
                
                BYTE_TO_UTF8[0x16] = nil
                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c3a4
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c3a5
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c3ab
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c3af
                BYTE_TO_UTF8[0x8c] = 0x00c3ae
                BYTE_TO_UTF8[0x8d] = 0x00c3ac
                BYTE_TO_UTF8[0x8e] = 0x00c384
                BYTE_TO_UTF8[0x8f] = 0x00c385
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c3a6
                BYTE_TO_UTF8[0x92] = 0x00c386
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c3b6
                BYTE_TO_UTF8[0x95] = 0x00c3b2
                BYTE_TO_UTF8[0x96] = 0x00c3bb
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c3bf
                BYTE_TO_UTF8[0x99] = 0x00c396
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c3b8
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c398
                BYTE_TO_UTF8[0x9e] = 0x00c397
                BYTE_TO_UTF8[0x9f] = 0x00c692
                BYTE_TO_UTF8[0xa0] = 0x00c3a1
                BYTE_TO_UTF8[0xa1] = 0x00c3ad
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c3b1
                BYTE_TO_UTF8[0xa5] = 0x00c391
                BYTE_TO_UTF8[0xa6] = 0x00c2aa
                BYTE_TO_UTF8[0xa7] = 0x00c2ba
                BYTE_TO_UTF8[0xa8] = 0x00c2bf
                BYTE_TO_UTF8[0xa9] = 0x00c2ae
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2a1
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2bb
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0x00c381
                BYTE_TO_UTF8[0xb6] = 0x00c382
                BYTE_TO_UTF8[0xb7] = 0x00c380
                BYTE_TO_UTF8[0xb8] = 0x00c2a9
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0x00c2a2
                BYTE_TO_UTF8[0xbe] = 0x00c2a5
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0x00c3a3
                BYTE_TO_UTF8[0xc7] = 0x00c383
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0x00c2a4
                BYTE_TO_UTF8[0xd0] = 0x00c3b0
                BYTE_TO_UTF8[0xd1] = 0x00c390
                BYTE_TO_UTF8[0xd2] = 0x00c38a
                BYTE_TO_UTF8[0xd3] = 0x00c38b
                BYTE_TO_UTF8[0xd4] = 0x00c388
                BYTE_TO_UTF8[0xd5] = 0x00c4b1
                BYTE_TO_UTF8[0xd6] = 0x00c38d
                BYTE_TO_UTF8[0xd7] = 0x00c38e
                BYTE_TO_UTF8[0xd8] = 0x00c38f
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0x00c2a6
                BYTE_TO_UTF8[0xde] = 0x00c38c
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00c393
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00c394
                BYTE_TO_UTF8[0xe3] = 0x00c392
                BYTE_TO_UTF8[0xe4] = 0x00c3b5
                BYTE_TO_UTF8[0xe5] = 0x00c395
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00c3be
                BYTE_TO_UTF8[0xe8] = 0x00c39e
                BYTE_TO_UTF8[0xe9] = 0x00c39a
                BYTE_TO_UTF8[0xea] = 0x00c39b
                BYTE_TO_UTF8[0xeb] = 0x00c399
                BYTE_TO_UTF8[0xec] = 0x00c3bd
                BYTE_TO_UTF8[0xed] = 0x00c39d
                BYTE_TO_UTF8[0xee] = 0x00c2af
                BYTE_TO_UTF8[0xef] = 0x00c2b4
                BYTE_TO_UTF8[0xf0] = 0x00c2ad
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe28097
                BYTE_TO_UTF8[0xf3] = 0x00c2be
                BYTE_TO_UTF8[0xf4] = 0x00c2b6
                BYTE_TO_UTF8[0xf5] = 0x00c2a7
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0x00c2b8
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0x00c2a8
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0x00c2b9
                BYTE_TO_UTF8[0xfc] = 0x00c2b3
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
            end
            
            # Code page 860
            module Portugal
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }

                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c3a3
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c381
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c38a
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c38d
                BYTE_TO_UTF8[0x8c] = 0x00c394
                BYTE_TO_UTF8[0x8d] = 0x00c3ac
                BYTE_TO_UTF8[0x8e] = 0x00c383
                BYTE_TO_UTF8[0x8f] = 0x00c382
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c380
                BYTE_TO_UTF8[0x92] = 0x00c388
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c3b5
                BYTE_TO_UTF8[0x95] = 0x00c3b2
                BYTE_TO_UTF8[0x96] = 0x00c39a
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c38c
                BYTE_TO_UTF8[0x99] = 0x00c395
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c2a2
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c399
                BYTE_TO_UTF8[0x9e] = 0xe282a7
                BYTE_TO_UTF8[0x9f] = 0x00c393
                BYTE_TO_UTF8[0xa0] = 0x00c3a1
                BYTE_TO_UTF8[0xa1] = 0x00c3ad
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c3b1
                BYTE_TO_UTF8[0xa5] = 0x00c391
                BYTE_TO_UTF8[0xa6] = 0x00c2aa
                BYTE_TO_UTF8[0xa7] = 0x00c2ba
                BYTE_TO_UTF8[0xa8] = 0x00c2bf
                BYTE_TO_UTF8[0xa9] = 0x00c392
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2a1
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2bb
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0xe295a1
                BYTE_TO_UTF8[0xb6] = 0xe295a2
                BYTE_TO_UTF8[0xb7] = 0xe29596
                BYTE_TO_UTF8[0xb8] = 0xe29595
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0xe2959c
                BYTE_TO_UTF8[0xbe] = 0xe2959b
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0xe2959e
                BYTE_TO_UTF8[0xc7] = 0xe2959f
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0xe295a7
                BYTE_TO_UTF8[0xd0] = 0xe295a8
                BYTE_TO_UTF8[0xd1] = 0xe295a4
                BYTE_TO_UTF8[0xd2] = 0xe295a5
                BYTE_TO_UTF8[0xd3] = 0xe29599
                BYTE_TO_UTF8[0xd4] = 0xe29598
                BYTE_TO_UTF8[0xd5] = 0xe29592
                BYTE_TO_UTF8[0xd6] = 0xe29593
                BYTE_TO_UTF8[0xd7] = 0xe295ab
                BYTE_TO_UTF8[0xd8] = 0xe295aa
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0xe2968c
                BYTE_TO_UTF8[0xde] = 0xe29690
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00ceb1
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00ce93
                BYTE_TO_UTF8[0xe3] = 0x00cf80
                BYTE_TO_UTF8[0xe4] = 0x00cea3
                BYTE_TO_UTF8[0xe5] = 0x00cf83
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00cf84
                BYTE_TO_UTF8[0xe8] = 0x00cea6
                BYTE_TO_UTF8[0xe9] = 0x00ce98
                BYTE_TO_UTF8[0xea] = 0x00cea9
                BYTE_TO_UTF8[0xeb] = 0x00ceb4
                BYTE_TO_UTF8[0xec] = 0xe2889e
                BYTE_TO_UTF8[0xed] = 0x00cf86
                BYTE_TO_UTF8[0xee] = 0x00ceb5
                BYTE_TO_UTF8[0xef] = 0xe288a9
                BYTE_TO_UTF8[0xf0] = 0xe289a1
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe289a5
                BYTE_TO_UTF8[0xf3] = 0xe289a4
                BYTE_TO_UTF8[0xf4] = 0xe28ca0
                BYTE_TO_UTF8[0xf5] = 0xe28ca1
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0xe28988
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0xe28899
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0xe2889a
                BYTE_TO_UTF8[0xfc] = 0xe281bf
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
            end
            
            # Code page 863
            module CanadaFrench
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }
                
                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c382
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c2b6
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c3ab
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c3af
                BYTE_TO_UTF8[0x8c] = 0x00c3ae
                BYTE_TO_UTF8[0x8d] = 0xe28097
                BYTE_TO_UTF8[0x8e] = 0x00c380
                BYTE_TO_UTF8[0x8f] = 0x00c2a7
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c388
                BYTE_TO_UTF8[0x92] = 0x00c38a
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c38b
                BYTE_TO_UTF8[0x95] = 0x00c38f
                BYTE_TO_UTF8[0x96] = 0x00c3bb
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c2a4
                BYTE_TO_UTF8[0x99] = 0x00c394
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c2a2
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c399
                BYTE_TO_UTF8[0x9e] = 0x00c39b
                BYTE_TO_UTF8[0x9f] = 0x00c692
                BYTE_TO_UTF8[0xa0] = 0x00c2a6
                BYTE_TO_UTF8[0xa1] = 0x00c2b4
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c2a8
                BYTE_TO_UTF8[0xa5] = 0x00c2b8
                BYTE_TO_UTF8[0xa6] = 0x00c2b3
                BYTE_TO_UTF8[0xa7] = 0x00c2af
                BYTE_TO_UTF8[0xa8] = 0x00c38e
                BYTE_TO_UTF8[0xa9] = 0xe28c90
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2be
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2bb
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0xe295a1
                BYTE_TO_UTF8[0xb6] = 0xe295a2
                BYTE_TO_UTF8[0xb7] = 0xe29596
                BYTE_TO_UTF8[0xb8] = 0xe29595
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0xe2959c
                BYTE_TO_UTF8[0xbe] = 0xe2959b
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0xe2959e
                BYTE_TO_UTF8[0xc7] = 0xe2959f
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0xe295a7
                BYTE_TO_UTF8[0xd0] = 0xe295a8
                BYTE_TO_UTF8[0xd1] = 0xe295a4
                BYTE_TO_UTF8[0xd2] = 0xe295a5
                BYTE_TO_UTF8[0xd3] = 0xe29599
                BYTE_TO_UTF8[0xd4] = 0xe29598
                BYTE_TO_UTF8[0xd5] = 0xe29592
                BYTE_TO_UTF8[0xd6] = 0xe29593
                BYTE_TO_UTF8[0xd7] = 0xe295ab
                BYTE_TO_UTF8[0xd8] = 0xe295aa
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0xe2968c
                BYTE_TO_UTF8[0xde] = 0xe29690
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00ceb1
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00ce93
                BYTE_TO_UTF8[0xe3] = 0x00cf80
                BYTE_TO_UTF8[0xe4] = 0x00cea3
                BYTE_TO_UTF8[0xe5] = 0x00cf83
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00cf84
                BYTE_TO_UTF8[0xe8] = 0x00cea6
                BYTE_TO_UTF8[0xe9] = 0x00ce98
                BYTE_TO_UTF8[0xea] = 0x00cea9
                BYTE_TO_UTF8[0xeb] = 0x00ceb4
                BYTE_TO_UTF8[0xec] = 0xe2889e
                BYTE_TO_UTF8[0xed] = 0x00cf86
                BYTE_TO_UTF8[0xee] = 0x00ceb5
                BYTE_TO_UTF8[0xef] = 0xe288a9
                BYTE_TO_UTF8[0xf0] = 0xe289a1
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe289a5
                BYTE_TO_UTF8[0xf3] = 0xe289a4
                BYTE_TO_UTF8[0xf4] = 0xe28ca0
                BYTE_TO_UTF8[0xf5] = 0xe28ca1
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0xe28988
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0xe28899
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0xe2889a
                BYTE_TO_UTF8[0xfc] = 0xe281bf
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
            end
            
            # Code page 865
            module Norway
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }
                
                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c3a4
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c3a5
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c3ab
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c3af
                BYTE_TO_UTF8[0x8c] = 0x00c3ae
                BYTE_TO_UTF8[0x8d] = 0x00c3ac
                BYTE_TO_UTF8[0x8e] = 0x00c384
                BYTE_TO_UTF8[0x8f] = 0x00c385
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c3a6
                BYTE_TO_UTF8[0x92] = 0x00c386
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c3b6
                BYTE_TO_UTF8[0x95] = 0x00c3b2
                BYTE_TO_UTF8[0x96] = 0x00c3bb
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c3bf
                BYTE_TO_UTF8[0x99] = 0x00c396
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c3b8
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c398
                BYTE_TO_UTF8[0x9e] = 0xe282a7
                BYTE_TO_UTF8[0x9f] = 0x00c692
                BYTE_TO_UTF8[0xa0] = 0x00c3a1
                BYTE_TO_UTF8[0xa1] = 0x00c3ad
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c3b1
                BYTE_TO_UTF8[0xa5] = 0x00c391
                BYTE_TO_UTF8[0xa6] = 0x00c2aa
                BYTE_TO_UTF8[0xa7] = 0x00c2ba
                BYTE_TO_UTF8[0xa8] = 0x00c2bf
                BYTE_TO_UTF8[0xa9] = 0xe28c90
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2a1
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2a4
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0xe295a1
                BYTE_TO_UTF8[0xb6] = 0xe295a2
                BYTE_TO_UTF8[0xb7] = 0xe29596
                BYTE_TO_UTF8[0xb8] = 0xe29595
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0xe2959c
                BYTE_TO_UTF8[0xbe] = 0xe2959b
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0xe2959e
                BYTE_TO_UTF8[0xc7] = 0xe2959f
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0xe295a7
                BYTE_TO_UTF8[0xd0] = 0xe295a8
                BYTE_TO_UTF8[0xd1] = 0xe295a4
                BYTE_TO_UTF8[0xd2] = 0xe295a5
                BYTE_TO_UTF8[0xd3] = 0xe29599
                BYTE_TO_UTF8[0xd4] = 0xe29598
                BYTE_TO_UTF8[0xd5] = 0xe29592
                BYTE_TO_UTF8[0xd6] = 0xe29593
                BYTE_TO_UTF8[0xd7] = 0xe295ab
                BYTE_TO_UTF8[0xd8] = 0xe295aa
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0xe2968c
                BYTE_TO_UTF8[0xde] = 0xe29690
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00ceb1
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00ce93
                BYTE_TO_UTF8[0xe3] = 0x00cf80
                BYTE_TO_UTF8[0xe4] = 0x00cea3
                BYTE_TO_UTF8[0xe5] = 0x00cf83
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00cf84
                BYTE_TO_UTF8[0xe8] = 0x00cea6
                BYTE_TO_UTF8[0xe9] = 0x00ce98
                BYTE_TO_UTF8[0xea] = 0x00cea9
                BYTE_TO_UTF8[0xeb] = 0x00ceb4
                BYTE_TO_UTF8[0xec] = 0xe2889e
                BYTE_TO_UTF8[0xed] = 0x00cf86
                BYTE_TO_UTF8[0xee] = 0x00ceb5
                BYTE_TO_UTF8[0xef] = 0xe288a9
                BYTE_TO_UTF8[0xf0] = 0xe289a1
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe289a5
                BYTE_TO_UTF8[0xf3] = 0xe289a4
                BYTE_TO_UTF8[0xf4] = 0xe28ca0
                BYTE_TO_UTF8[0xf5] = 0xe28ca1
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0xe28988
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0xe28899
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0xe2889a
                BYTE_TO_UTF8[0xfc] = 0xe281bf
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
            end  
        end
        module Body
            # ISO 6937/2-1983, Addendum 1-1989)           
            module Latin
                BYTE_TO_UTF8 = UTF8.clone

                BYTE_TO_UTF8[0x24] = 0xc2a4

                BYTE_TO_UTF8[0xa0] = 0xc2a0
                BYTE_TO_UTF8[0xa1] = 0xc2a1
                BYTE_TO_UTF8[0xa2] = 0xc2a2
                BYTE_TO_UTF8[0xa3] = 0xc2a3
                BYTE_TO_UTF8[0xa4] = 0x0024             
                BYTE_TO_UTF8[0xa5] = 0xc2b5
                BYTE_TO_UTF8[0xa6] = nil
                BYTE_TO_UTF8[0xa7] = 0xc2a7
                BYTE_TO_UTF8[0xa8] = nil
                BYTE_TO_UTF8[0xa9] = 0xe2809b
                BYTE_TO_UTF8[0xaa] = 0xe2809f
                BYTE_TO_UTF8[0xab] = 0xc2ab
                BYTE_TO_UTF8[0xac] = 0xe28690
                BYTE_TO_UTF8[0xad] = 0xe28691
                BYTE_TO_UTF8[0xae] = 0xe28692
                BYTE_TO_UTF8[0xaf] = 0xe28693
                
                BYTE_TO_UTF8[0xb0] = 0xc2b0
                BYTE_TO_UTF8[0xb1] = 0xc2b1
                BYTE_TO_UTF8[0xb2] = 0xc2b2
                BYTE_TO_UTF8[0xb3] = 0xc2b3
                BYTE_TO_UTF8[0xb4] = 0xc397
                BYTE_TO_UTF8[0xb5] = 0xc2b5
                BYTE_TO_UTF8[0xb6] = 0xc2b6
                BYTE_TO_UTF8[0xb7] = 0xc2b7
                BYTE_TO_UTF8[0xb8] = 0xc3b7
                BYTE_TO_UTF8[0xb9] = 0xe28099
                BYTE_TO_UTF8[0xba] = 0xe2809d
                BYTE_TO_UTF8[0xbb] = 0xc2bb
                BYTE_TO_UTF8[0xbc] = 0xc2bc
                BYTE_TO_UTF8[0xbd] = 0xc2bd
                BYTE_TO_UTF8[0xbe] = 0xc2be
                BYTE_TO_UTF8[0xbf] = 0xc2bf
                
                BYTE_TO_UTF8[0xc0] = nil
                BYTE_TO_UTF8[0xc1] = 0x60
                BYTE_TO_UTF8[0xc2] = 0xc2b4
                BYTE_TO_UTF8[0xc3] = 0x5e
                BYTE_TO_UTF8[0xc4] = 0xcb9c
                BYTE_TO_UTF8[0xc5] = 0xcb89
                BYTE_TO_UTF8[0xc6] = 0xcb98
                BYTE_TO_UTF8[0xc7] = 0xcb99
                BYTE_TO_UTF8[0xc8] = 0xc2a8
                BYTE_TO_UTF8[0xc9] = nil
                BYTE_TO_UTF8[0xca] = 0xcb9a
                BYTE_TO_UTF8[0xcb] = 0xcca2
                BYTE_TO_UTF8[0xcc] = 0xcb8d
                BYTE_TO_UTF8[0xcd] = 0xcb9d
                BYTE_TO_UTF8[0xce] = 0xcb9b
                BYTE_TO_UTF8[0xcf] = 0xcb87
                
                BYTE_TO_UTF8[0xd0] = 0xe28095
                BYTE_TO_UTF8[0xd1] = 0xc2b9
                BYTE_TO_UTF8[0xd2] = 0xc2ae
                BYTE_TO_UTF8[0xd3] = 0xc2a9
                BYTE_TO_UTF8[0xd4] = 0xe284a2
                BYTE_TO_UTF8[0xd5] = 0xe299aa
                BYTE_TO_UTF8[0xd6] = 0xc2ac
                BYTE_TO_UTF8[0xd7] = 0xc2a6
                BYTE_TO_UTF8[0xd8] = nil
                BYTE_TO_UTF8[0xd9] = nil
                BYTE_TO_UTF8[0xda] = nil
                BYTE_TO_UTF8[0xdb] = nil
                BYTE_TO_UTF8[0xdc] = 0xe2859b
                BYTE_TO_UTF8[0xdd] = 0xe2859c
                BYTE_TO_UTF8[0xde] = 0xe2859d
                BYTE_TO_UTF8[0xdf] = 0xe2859e
                
                BYTE_TO_UTF8[0xe0] = 0xcea9
                BYTE_TO_UTF8[0xe1] = 0xc386
                BYTE_TO_UTF8[0xe2] = 0xc490
                BYTE_TO_UTF8[0xe3] = 0xc2aa
                BYTE_TO_UTF8[0xe4] = 0xc4a6
                BYTE_TO_UTF8[0xe5] = nil
                BYTE_TO_UTF8[0xe6] = 0xc4b2
                BYTE_TO_UTF8[0xe7] = 0xc4bf
                BYTE_TO_UTF8[0xe8] = 0xc581
                BYTE_TO_UTF8[0xe9] = 0xc398
                BYTE_TO_UTF8[0xea] = 0xc592
                BYTE_TO_UTF8[0xeb] = 0xc2ba
                BYTE_TO_UTF8[0xec] = 0xc39e
                BYTE_TO_UTF8[0xed] = 0xc5a6
                BYTE_TO_UTF8[0xee] = 0xc58a
                BYTE_TO_UTF8[0xef] = 0xc589

                BYTE_TO_UTF8[0xf0] = 0xc4b8
                BYTE_TO_UTF8[0xf1] = 0xc3a6
                BYTE_TO_UTF8[0xf2] = 0xc491
                BYTE_TO_UTF8[0xf3] = 0xc3b0
                BYTE_TO_UTF8[0xf4] = 0xc4a7
                BYTE_TO_UTF8[0xf5] = 0xc4b1
                BYTE_TO_UTF8[0xf6] = 0xc4b3
                BYTE_TO_UTF8[0xf7] = 0xc580
                BYTE_TO_UTF8[0xf8] = 0xc582
                BYTE_TO_UTF8[0xf9] = 0xc3b8
                BYTE_TO_UTF8[0xfa] = 0xc593
                BYTE_TO_UTF8[0xfb] = 0xc39f
                BYTE_TO_UTF8[0xfc] = 0xc3be
                BYTE_TO_UTF8[0xfd] = 0xc5a7
                BYTE_TO_UTF8[0xfe] = 0xc58b
                BYTE_TO_UTF8[0xff] = 0xc2ad
            end
                
            # ISO 8859/5-1988
            module Cyrilic
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa1] = 0x00d081
                BYTE_TO_UTF8[0xa2] = 0x00d082
                BYTE_TO_UTF8[0xa3] = 0x00d083
                BYTE_TO_UTF8[0xa4] = 0x00d084
                BYTE_TO_UTF8[0xa5] = 0x00d085
                BYTE_TO_UTF8[0xa6] = 0x00d086
                BYTE_TO_UTF8[0xa7] = 0x00d087
                BYTE_TO_UTF8[0xa8] = 0x00d088
                BYTE_TO_UTF8[0xa9] = 0x00d089
                BYTE_TO_UTF8[0xaa] = 0x00d08a
                BYTE_TO_UTF8[0xab] = 0x00d08b
                BYTE_TO_UTF8[0xac] = 0x00d08c
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xae] = 0x00d08e
                BYTE_TO_UTF8[0xaf] = 0x00d08f
                
                BYTE_TO_UTF8[0xb0] = 0x00d090
                BYTE_TO_UTF8[0xb1] = 0x00d091
                BYTE_TO_UTF8[0xb2] = 0x00d092
                BYTE_TO_UTF8[0xb3] = 0x00d093
                BYTE_TO_UTF8[0xb4] = 0x00d094
                BYTE_TO_UTF8[0xb5] = 0x00d095
                BYTE_TO_UTF8[0xb6] = 0x00d096
                BYTE_TO_UTF8[0xb7] = 0x00d097
                BYTE_TO_UTF8[0xb8] = 0x00d098
                BYTE_TO_UTF8[0xb9] = 0x00d099
                BYTE_TO_UTF8[0xba] = 0x00d09a
                BYTE_TO_UTF8[0xbb] = 0x00d09b
                BYTE_TO_UTF8[0xbc] = 0x00d09c
                BYTE_TO_UTF8[0xbd] = 0x00d09d
                BYTE_TO_UTF8[0xbe] = 0x00d09e
                BYTE_TO_UTF8[0xbf] = 0x00d09f
                
                BYTE_TO_UTF8[0xc0] = 0x00d0a0
                BYTE_TO_UTF8[0xc1] = 0x00d0a1
                BYTE_TO_UTF8[0xc2] = 0x00d0a2
                BYTE_TO_UTF8[0xc3] = 0x00d0a3
                BYTE_TO_UTF8[0xc4] = 0x00d0a4
                BYTE_TO_UTF8[0xc5] = 0x00d0a5
                BYTE_TO_UTF8[0xc6] = 0x00d0a6
                BYTE_TO_UTF8[0xc7] = 0x00d0a7
                BYTE_TO_UTF8[0xc8] = 0x00d0a8
                BYTE_TO_UTF8[0xc9] = 0x00d0a9
                BYTE_TO_UTF8[0xca] = 0x00d0aa
                BYTE_TO_UTF8[0xcb] = 0x00d0ab
                BYTE_TO_UTF8[0xcc] = 0x00d0ac
                BYTE_TO_UTF8[0xcd] = 0x00d0ad
                BYTE_TO_UTF8[0xce] = 0x00d0ae
                BYTE_TO_UTF8[0xcf] = 0x00d0af
                
                BYTE_TO_UTF8[0xd0] = 0x00d0b0
                BYTE_TO_UTF8[0xd1] = 0x00d0b1
                BYTE_TO_UTF8[0xd2] = 0x00d0b2
                BYTE_TO_UTF8[0xd3] = 0x00d0b3
                BYTE_TO_UTF8[0xd4] = 0x00d0b4
                BYTE_TO_UTF8[0xd5] = 0x00d0b5
                BYTE_TO_UTF8[0xd6] = 0x00d0b6
                BYTE_TO_UTF8[0xd7] = 0x00d0b7
                BYTE_TO_UTF8[0xd8] = 0x00d0b8
                BYTE_TO_UTF8[0xd9] = 0x00d0b9
                BYTE_TO_UTF8[0xda] = 0x00d0ba
                BYTE_TO_UTF8[0xdb] = 0x00d0bb
                BYTE_TO_UTF8[0xdc] = 0x00d0bc
                BYTE_TO_UTF8[0xdd] = 0x00d0bd
                BYTE_TO_UTF8[0xde] = 0x00d0be
                BYTE_TO_UTF8[0xdf] = 0x00d0bf
                
                BYTE_TO_UTF8[0xe0] = 0x00d180
                BYTE_TO_UTF8[0xe1] = 0x00d181
                BYTE_TO_UTF8[0xe2] = 0x00d182
                BYTE_TO_UTF8[0xe3] = 0x00d183
                BYTE_TO_UTF8[0xe4] = 0x00d184
                BYTE_TO_UTF8[0xe5] = 0x00d185
                BYTE_TO_UTF8[0xe6] = 0x00d186
                BYTE_TO_UTF8[0xe7] = 0x00d187
                BYTE_TO_UTF8[0xe8] = 0x00d188
                BYTE_TO_UTF8[0xe9] = 0x00d189
                BYTE_TO_UTF8[0xea] = 0x00d18a
                BYTE_TO_UTF8[0xeb] = 0x00d18b
                BYTE_TO_UTF8[0xec] = 0x00d18c
                BYTE_TO_UTF8[0xed] = 0x00d18d
                BYTE_TO_UTF8[0xee] = 0x00d18e
                BYTE_TO_UTF8[0xef] = 0x00d18f
                
                BYTE_TO_UTF8[0xf0] = 0xe28496
                BYTE_TO_UTF8[0xf1] = 0x00d191
                BYTE_TO_UTF8[0xf2] = 0x00d192
                BYTE_TO_UTF8[0xf3] = 0x00d193
                BYTE_TO_UTF8[0xf4] = 0x00d194
                BYTE_TO_UTF8[0xf5] = 0x00d195
                BYTE_TO_UTF8[0xf6] = 0x00d196
                BYTE_TO_UTF8[0xf7] = 0x00d197
                BYTE_TO_UTF8[0xf8] = 0x00d198
                BYTE_TO_UTF8[0xf9] = 0x00d199
                BYTE_TO_UTF8[0xfa] = 0x00d19a
                BYTE_TO_UTF8[0xfb] = 0x00d19b
                BYTE_TO_UTF8[0xfc] = 0x00d19c
                BYTE_TO_UTF8[0xfd] = 0x00c2a7
                BYTE_TO_UTF8[0xfe] = 0x00d19e
                BYTE_TO_UTF8[0xff] = 0x00d19f
            end

            # ISO 8859/6-1987
            module Arabic
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa4] = 0x00c2a4
                BYTE_TO_UTF8[0xac] = 0x00d88c
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                
                BYTE_TO_UTF8[0xbb] = 0x00d89b
                BYTE_TO_UTF8[0xbf] = 0x00d89f

                BYTE_TO_UTF8[0xc1] = 0x00d8a1
                BYTE_TO_UTF8[0xc2] = 0x00d8a2
                BYTE_TO_UTF8[0xc3] = 0x00d8a3
                BYTE_TO_UTF8[0xc4] = 0x00d8a4
                BYTE_TO_UTF8[0xc5] = 0x00d8a5
                BYTE_TO_UTF8[0xc6] = 0x00d8a6
                BYTE_TO_UTF8[0xc7] = 0x00d8a7
                BYTE_TO_UTF8[0xc8] = 0x00d8a8
                BYTE_TO_UTF8[0xc9] = 0x00d8a9
                BYTE_TO_UTF8[0xca] = 0x00d8aa
                BYTE_TO_UTF8[0xcb] = 0x00d8ab
                BYTE_TO_UTF8[0xcc] = 0x00d8ac
                BYTE_TO_UTF8[0xcd] = 0x00d8ad
                BYTE_TO_UTF8[0xce] = 0x00d8ae
                BYTE_TO_UTF8[0xcf] = 0x00d8af
                
                BYTE_TO_UTF8[0xd0] = 0x00d8b0
                BYTE_TO_UTF8[0xd1] = 0x00d8b1
                BYTE_TO_UTF8[0xd2] = 0x00d8b2
                BYTE_TO_UTF8[0xd3] = 0x00d8b3
                BYTE_TO_UTF8[0xd4] = 0x00d8b4
                BYTE_TO_UTF8[0xd5] = 0x00d8b5
                BYTE_TO_UTF8[0xd6] = 0x00d8b6
                BYTE_TO_UTF8[0xd7] = 0x00d8b7
                BYTE_TO_UTF8[0xd8] = 0x00d8b8
                BYTE_TO_UTF8[0xd9] = 0x00d8b9
                BYTE_TO_UTF8[0xda] = 0x00d8ba
                
                BYTE_TO_UTF8[0xe0] = 0x00d980
                BYTE_TO_UTF8[0xe1] = 0x00d981
                BYTE_TO_UTF8[0xe2] = 0x00d982
                BYTE_TO_UTF8[0xe3] = 0x00d983
                BYTE_TO_UTF8[0xe4] = 0x00d984
                BYTE_TO_UTF8[0xe5] = 0x00d985
                BYTE_TO_UTF8[0xe6] = 0x00d986
                BYTE_TO_UTF8[0xe7] = 0x00d987
                BYTE_TO_UTF8[0xe8] = 0x00d988
                BYTE_TO_UTF8[0xe9] = 0x00d989
                BYTE_TO_UTF8[0xea] = 0x00d98a
                BYTE_TO_UTF8[0xeb] = 0x00d98b
                BYTE_TO_UTF8[0xec] = 0x00d98c
                BYTE_TO_UTF8[0xed] = 0x00d98d
                BYTE_TO_UTF8[0xee] = 0x00d98e
                BYTE_TO_UTF8[0xef] = 0x00d98f
                
                BYTE_TO_UTF8[0xf0] = 0x00d990
                BYTE_TO_UTF8[0xf1] = 0x00d991
                BYTE_TO_UTF8[0xf2] = 0x00d992
            end

            # ISO 8859/7-1987
            module Greek
                BYTE_TO_UTF8 = UTF8.clone

                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa1] = 0xe28098
                BYTE_TO_UTF8[0xa2] = 0xe28099
                BYTE_TO_UTF8[0xa3] = 0x00c2a3
                BYTE_TO_UTF8[0xa6] = 0x00c2a6
                BYTE_TO_UTF8[0xa7] = 0x00c2a7
                BYTE_TO_UTF8[0xa8] = 0x00c2a8
                BYTE_TO_UTF8[0xa9] = 0x00c2a9
                BYTE_TO_UTF8[0xab] = 0x00c2ab
                BYTE_TO_UTF8[0xac] = 0x00c2ac
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xaf] = 0xe28095
                
                BYTE_TO_UTF8[0xb0] = 0x00c2b0
                BYTE_TO_UTF8[0xb1] = 0x00c2b1
                BYTE_TO_UTF8[0xb2] = 0x00c2b2
                BYTE_TO_UTF8[0xb3] = 0x00c2b3
                BYTE_TO_UTF8[0xb4] = 0x00ce84
                BYTE_TO_UTF8[0xb5] = 0x00ce85
                BYTE_TO_UTF8[0xb6] = 0x00ce86
                BYTE_TO_UTF8[0xb7] = 0x00c2b7
                BYTE_TO_UTF8[0xb8] = 0x00ce88
                BYTE_TO_UTF8[0xb9] = 0x00ce89
                BYTE_TO_UTF8[0xba] = 0x00ce8a
                BYTE_TO_UTF8[0xbb] = 0x00c2bb
                BYTE_TO_UTF8[0xbc] = 0x00ce8c
                BYTE_TO_UTF8[0xbd] = 0x00c2bd
                BYTE_TO_UTF8[0xbe] = 0x00ce8e
                BYTE_TO_UTF8[0xbf] = 0x00ce8f
                
                BYTE_TO_UTF8[0xc0] = 0x00ce90
                BYTE_TO_UTF8[0xc1] = 0x00ce91
                BYTE_TO_UTF8[0xc2] = 0x00ce92
                BYTE_TO_UTF8[0xc3] = 0x00ce93
                BYTE_TO_UTF8[0xc4] = 0x00ce94
                BYTE_TO_UTF8[0xc5] = 0x00ce95
                BYTE_TO_UTF8[0xc6] = 0x00ce96
                BYTE_TO_UTF8[0xc7] = 0x00ce97
                BYTE_TO_UTF8[0xc8] = 0x00ce98
                BYTE_TO_UTF8[0xc9] = 0x00ce99
                BYTE_TO_UTF8[0xca] = 0x00ce9a
                BYTE_TO_UTF8[0xcb] = 0x00ce9b
                BYTE_TO_UTF8[0xcc] = 0x00ce9c
                BYTE_TO_UTF8[0xcd] = 0x00ce9d
                BYTE_TO_UTF8[0xce] = 0x00ce9e
                BYTE_TO_UTF8[0xcf] = 0x00ce9f
                
                BYTE_TO_UTF8[0xd0] = 0x00cea0
                BYTE_TO_UTF8[0xd1] = 0x00cea1
                BYTE_TO_UTF8[0xd3] = 0x00cea3
                BYTE_TO_UTF8[0xd4] = 0x00cea4
                BYTE_TO_UTF8[0xd5] = 0x00cea5
                BYTE_TO_UTF8[0xd6] = 0x00cea6
                BYTE_TO_UTF8[0xd7] = 0x00cea7
                BYTE_TO_UTF8[0xd8] = 0x00cea8
                BYTE_TO_UTF8[0xd9] = 0x00cea9
                BYTE_TO_UTF8[0xda] = 0x00ceaa
                BYTE_TO_UTF8[0xdb] = 0x00ceab
                BYTE_TO_UTF8[0xdc] = 0x00ceac
                BYTE_TO_UTF8[0xdd] = 0x00cead
                BYTE_TO_UTF8[0xde] = 0x00ceae
                BYTE_TO_UTF8[0xdf] = 0x00ceaf
                
                BYTE_TO_UTF8[0xe0] = 0x00ceb0
                BYTE_TO_UTF8[0xe1] = 0x00ceb1
                BYTE_TO_UTF8[0xe2] = 0x00ceb2
                BYTE_TO_UTF8[0xe3] = 0x00ceb3
                BYTE_TO_UTF8[0xe4] = 0x00ceb4
                BYTE_TO_UTF8[0xe5] = 0x00ceb5
                BYTE_TO_UTF8[0xe6] = 0x00ceb6
                BYTE_TO_UTF8[0xe7] = 0x00ceb7
                BYTE_TO_UTF8[0xe8] = 0x00ceb8
                BYTE_TO_UTF8[0xe9] = 0x00ceb9
                BYTE_TO_UTF8[0xea] = 0x00ceba
                BYTE_TO_UTF8[0xeb] = 0x00cebb
                BYTE_TO_UTF8[0xec] = 0x00cebc
                BYTE_TO_UTF8[0xed] = 0x00cebd
                BYTE_TO_UTF8[0xee] = 0x00cebe
                BYTE_TO_UTF8[0xef] = 0x00cebf
                
                BYTE_TO_UTF8[0xf0] = 0x00cf80
                BYTE_TO_UTF8[0xf1] = 0x00cf81
                BYTE_TO_UTF8[0xf2] = 0x00cf82
                BYTE_TO_UTF8[0xf3] = 0x00cf83
                BYTE_TO_UTF8[0xf4] = 0x00cf84
                BYTE_TO_UTF8[0xf5] = 0x00cf85
                BYTE_TO_UTF8[0xf6] = 0x00cf86
                BYTE_TO_UTF8[0xf7] = 0x00cf87
                BYTE_TO_UTF8[0xf8] = 0x00cf88
                BYTE_TO_UTF8[0xf9] = 0x00cf89
                BYTE_TO_UTF8[0xfa] = 0x00cf8a
                BYTE_TO_UTF8[0xfb] = 0x00cf8b
                BYTE_TO_UTF8[0xfc] = 0x00cf8c
                BYTE_TO_UTF8[0xfd] = 0x00cf8d
                BYTE_TO_UTF8[0xfe] = 0x00cf8e
            end

            # ISO 8859/8-1988
            module Hebrew
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa2] = 0x00c2a2
                BYTE_TO_UTF8[0xa3] = 0x00c2a3
                BYTE_TO_UTF8[0xa4] = 0x00c2a4
                BYTE_TO_UTF8[0xa5] = 0x00c2a5
                BYTE_TO_UTF8[0xa6] = 0x00c2a6
                BYTE_TO_UTF8[0xa7] = 0x00c2a7
                BYTE_TO_UTF8[0xa8] = 0x00c2a8
                BYTE_TO_UTF8[0xa9] = 0x00c2a9
                BYTE_TO_UTF8[0xaa] = 0x00c397
                BYTE_TO_UTF8[0xab] = 0x00c2ab
                BYTE_TO_UTF8[0xac] = 0x00c2ac
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xae] = 0x00c2ae
                BYTE_TO_UTF8[0xaf] = 0x00c2af
                
                BYTE_TO_UTF8[0xb0] = 0x00c2b0
                BYTE_TO_UTF8[0xb1] = 0x00c2b1
                BYTE_TO_UTF8[0xb2] = 0x00c2b2
                BYTE_TO_UTF8[0xb3] = 0x00c2b3
                BYTE_TO_UTF8[0xb4] = 0x00c2b4
                BYTE_TO_UTF8[0xb5] = 0x00c2b5
                BYTE_TO_UTF8[0xb6] = 0x00c2b6
                BYTE_TO_UTF8[0xb7] = 0x00c2b7
                BYTE_TO_UTF8[0xb8] = 0x00c2b8
                BYTE_TO_UTF8[0xb9] = 0x00c2b9
                BYTE_TO_UTF8[0xba] = 0x00c3b7
                BYTE_TO_UTF8[0xbb] = 0x00c2bb
                BYTE_TO_UTF8[0xbc] = 0x00c2bc
                BYTE_TO_UTF8[0xbd] = 0x00c2bd
                BYTE_TO_UTF8[0xbe] = 0x00c2be
                
                BYTE_TO_UTF8[0xdf] = 0xe28097
                
                BYTE_TO_UTF8[0xe0] = 0x00d790
                BYTE_TO_UTF8[0xe1] = 0x00d791
                BYTE_TO_UTF8[0xe2] = 0x00d792
                BYTE_TO_UTF8[0xe3] = 0x00d793
                BYTE_TO_UTF8[0xe4] = 0x00d794
                BYTE_TO_UTF8[0xe5] = 0x00d795
                BYTE_TO_UTF8[0xe6] = 0x00d796
                BYTE_TO_UTF8[0xe7] = 0x00d797
                BYTE_TO_UTF8[0xe8] = 0x00d798
                BYTE_TO_UTF8[0xe9] = 0x00d799
                BYTE_TO_UTF8[0xea] = 0x00d79a
                BYTE_TO_UTF8[0xeb] = 0x00d79b
                BYTE_TO_UTF8[0xec] = 0x00d79c
                BYTE_TO_UTF8[0xed] = 0x00d79d
                BYTE_TO_UTF8[0xee] = 0x00d79e
                BYTE_TO_UTF8[0xef] = 0x00d79f
                
                BYTE_TO_UTF8[0xf0] = 0x00d7a0
                BYTE_TO_UTF8[0xf1] = 0x00d7a1
                BYTE_TO_UTF8[0xf2] = 0x00d7a2
                BYTE_TO_UTF8[0xf3] = 0x00d7a3
                BYTE_TO_UTF8[0xf4] = 0x00d7a4
                BYTE_TO_UTF8[0xf5] = 0x00d7a5
                BYTE_TO_UTF8[0xf6] = 0x00d7a6
                BYTE_TO_UTF8[0xf7] = 0x00d7a7
                BYTE_TO_UTF8[0xf8] = 0x00d7a8
                BYTE_TO_UTF8[0xf9] = 0x00d7a9
                BYTE_TO_UTF8[0xfa] = 0x00d7aa
            end
        end
        module ControlCode
            NEWLINE = "\x8a"
            FILLER  = "\x8f"

            DEFAULT_FORMAT = { :b => false, :u => false,
                               :i => false, :color => :white,
                               :bgcolor => :black }
            
            # To produce colored backgrounds:
            #   COLOR[:alpha][:yellow]
            #   BACKGROUND[:new]
            #   COLOR[:green]
            # This will produce green letter on a yellow background.
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
            
            # Youtube seems to allow teletext mixed with invision codes.
            module InVision
                DEFINED = { "\x80" => true, "\x81" => true,
                            "\x82" => true, "\x83" => true,
                            "\x84" => true, "\x85" => true}
                        
                ITALICS   = { true => "\x80", false => "\x81" }
                UNDERLINE = { true => "\x82", false => "\x83" }
                BOXING    = { true => "\x84", false => "\x85" }
                
                ITALICS.default   = ITALICS[false]
                UNDERLINE.default = UNDERLINE[false]
                BOXING.default    = BOXING[false]
                
                NEWLINE = ControlCode::NEWLINE
                FILLER  = ControlCode::FILLER
            end
            
            DEFINED = {}
            TeleText::DEFINED.each_pair { |k,v| DEFINED[k] = v }
            InVision::DEFINED.each_pair { |k,v| DEFINED[k] = v }
            
        end
        module SpecialGlyphs
            NEWLINE          = "\xe2\x80\x96".force_encoding(Encoding::UTF_8)
            UNKNOWN          = "\xef\xbf\xbd".force_encoding(Encoding::UTF_8)
            UNSUPPORTED_CODE = "\xe2\x90\xa3".force_encoding(Encoding::UTF_8)
            UNUSED_DATA      = "\xc2\xb7".force_encoding(Encoding::UTF_8)
        end

        # convert layout to control codes and plain text to given codepage
        # lines must be encoded in (valid) utf-8
        def self.encode_body(lines, codepage, max_chars, teletext=true, invision=true)
            bytes   = ''
            
            # formatting of the last printed character
            cur_fmt = ControlCode::DEFAULT_FORMAT.clone
            
            # history of opened tags, initialize to default
            tags    = { :b => [cur_fmt[:b]], :u     => [cur_fmt[:u]],
                        :i => [cur_fmt[:i]], :color => [cur_fmt[:color]],
                        :bgcolor => [cur_fmt[:bgcolor]]}
            tags.default = [] # ignore non-existing tags
            
            # update formatting only when a character need to be printed
            needs_reformat = false
            
            # keep track of the number of printed characters on the current row
            chars = 0
            
            converter = codepage::HASH_UTF8_TO_BYTE
            colorizer = Util::Color
            
            # parse layout
            SimpleParser.each_char(lines.join("\n")) do |type, tag, opt|
                case type
                when :chr
                    # plain text
                    if opt == "\x0a"
                        # newline
                        bytes << ControlCode::NEWLINE
                        # bold and bgcolor get reset on a newline
                        cur_fmt[:b] = ControlCode::DEFAULT_FORMAT[:b]
                        cur_fmt[:bgcolor] = ControlCode::DEFAULT_FORMAT[:bgcolor]
                        needs_reformat = true
                        # reset chars on current row count
                        chars = 0
                        char_limit_reached = false
                    else
                        chars += 1
                        # add formatting codes
                        if needs_reformat
                        # (only!) invision codes are getting ignored
                        # (by youtube) after the limit has been reached
                          bytes << apply_formatting(tags, cur_fmt, teletext, invision && chars<=max_chars )
                          needs_reformat = false
                        end
                        # discard characters beyond the row limit
                        if chars <= max_chars
                            # convert to iso
                            bytes << converter[opt].to_s
                            # (only!) invision codes are getting ignored
                            # (by youtube) after the limit has been reached
                        end
                    end
                when :tcl
                    # closing
                    needs_reformat = true
                    tags[tag].pop
                else
                    # opening
                    needs_reformat = true
                    case tag
                    when :b
                        tags[:b].push(true)
                    when :u
                        tags[:u].push(true)
                    when :i
                        tags[:i].push(true)
                    when :color
                        tags[:color].push(colorizer.nearest_color(opt.to_i))
                    when :bgcolor
                        tags[:bgcolor].push(colorizer.nearest_color(opt.to_i))
                    end
                end
            end
            
            return bytes
        end
        
        # Returns control code bytes for desired formatting.
        # Formatting to be applied in tags, formatting of most recently
        # printed character in cur_fmt.
        def self.apply_formatting(tags, cur_fmt, teletext, invision)
            include ControlCode::TeleText
            include ControlCode::InVision
            codes = ''
            # supported by invision
            if invision
                if cur_fmt[:i] != (val = tags[:i].last)
                    codes << ITALICS[val]
                    cur_fmt[:i] = val
                end
                if cur_fmt[:u] != (val = tags[:u].last)
                    codes << UNDERLINE[val]
                    cur_fmt[:u] = val
                end
            end
            # supported by teletext
            if teletext
                if cur_fmt[:b] != (val = tags[:b].last)
                    codes << BOLD[val]
                    cur_fmt[:b] = val
                end
                # setting the background color changes the text color as well
                # this is corrected by checking the text color afterwards
                # DO NOT CHANGE THE ORDER OF THE TWO IF CLAUSES BELOW #|
                if cur_fmt[:bgcolor] != (val = tags[:bgcolor].last)   #|
                    codes << COLORS[:text][val]                       #|
                    codes << BACKGROUND[:new]                         #|
                    cur_fmt[:color]   = val                           #|
                    cur_fmt[:bgcolor] = val                           #|
                end                                                   #|
                if cur_fmt[:color] != (val = tags[:color].last)       #|
                    codes << COLORS[:text][val]                       #|
                    cur_fmt[:color] = val                             #| 
                end                                                   #|
                #------------------------------------------------------/
            end
            return codes
        end
        
        # generate mappings (hashes) for header and body code pages
        [Header, Body].each do |section|
            section.constants.each do |const|
                page = section.const_get(const)
                b_hash = {}
                page.const_get(:BYTE_TO_UTF8).each_with_index do |i,j|
                    next if i.nil?
                    b_hash[Util.int_to_bytes(j)] = 
                        Util.int_to_bytes(i).force_encoding(Encoding::UTF_8)
                end
                page.const_set(:HASH_BYTE_TO_UTF8, b_hash)
                page.const_set(:HASH_UTF8_TO_BYTE, b_hash.invert)
            end
        end
    end
    module TerminalCode
        RESET  = "\x30"
        PREFIX = "\x1b\x5b"
        SUFFIX = "\x6d"
        
        FOREGROUND = {
            :black   => "\x33\x30",
            :red     => "\x33\x31",
            :green   => "\x33\x32",
            :yellow  => "\x33\x33",
            :blue    => "\x33\x34",
            :magenta => "\x33\x35",
            :cyan    => "\x33\x36",
            :white   => "\x33\x37"
        }
        BACKGROUND = {
            :black   => "\x34\x30",
            :red     => "\x34\x31",
            :green   => "\x34\x32",
            :yellow  => "\x34\x33",
            :blue    => "\x34\x34",
            :magenta => "\x34\x35",
            :cyan    => "\x34\x36",
            :white   => "\x34\x37"
        }
        
        UNDERLINE = { true => "\x34", false => "\x32\x34" }
        BOLD      = { true => "\x31", false => "\x32\x32" }
        ITALICS   = { true => "\x37", false => "\x32\x37"}
        
        INVERT    = {true => "\x37", false => "\x32\x37" }
        
        BYTE_TO_CODE = {}
       
        FOREGROUND.each do |name,code|
            BYTE_TO_CODE[CodePage::ControlCode::TeleText::COLORS[:text][name]] = code
        end
        #BACKGROUND.each do |name,code|
        #    BYTE_TO_CODE[CodePage::ControlCode::TeleText::COLORS[:text][name]] = code
        #end
        [false,true].each do |bool|
            BYTE_TO_CODE[CodePage::ControlCode::TeleText::BOLD[bool]]      = BOLD[bool]
            BYTE_TO_CODE[CodePage::ControlCode::InVision::ITALICS[bool]]   = ITALICS[bool]
            BYTE_TO_CODE[CodePage::ControlCode::InVision::UNDERLINE[bool]] = UNDERLINE[bool]
            #BYTE_TO_CODE[CodePage::ControlCode::TeleText::BACKGROUND[:new]]= INVERT[bool]
        end
       
        NAMES = { UNDERLINE[true] => [:u,true], UNDERLINE[false] => [:u,false],
                  BOLD[true]      => [:b,true], BOLD[false]      => [:b,false],
                  ITALICS[true]   => [:i,true], ITALICS[false]   => [:i,false],
                  FOREGROUND[:white]   => [:color,:white],
                  FOREGROUND[:black]   => [:color,:black],
                  FOREGROUND[:red]     => [:color,:red],
                  FOREGROUND[:green]   => [:color,:green],
                  FOREGROUND[:blue]    => [:color,:blue],
                  FOREGROUND[:yellow]  => [:color,:yellow],
                  FOREGROUND[:cyan]    => [:color,:cyan],
                  FOREGROUND[:magenta] => [:color,:magenta]
                }       
    end
    
    module HeaderOption
        FILLER = "\x20"
        module CPN
            UNITED_STATES = "\x34\x33\x37"
            MULTILINGUAL  = "\x38\x35\x30"
            PORTUGAL      = "\x38\x36\x30"
            CANADA_FRENCH = "\x38\x36\x33"
            NORWAY        = "\x38\x36\x35"
        end
        module DFC
            STL_25 = 'STL25.01'
            STL_30 = 'STL30.01'
        end
        module DSC
           BLANK            = "\x20"
           OPEN_SUBTITLING  = "\x30"
           TELETEXT_LEVEL_1 = "\x31"
           TELETEXT_LEVEL_2 = "\x32"
        end
        module CCT
           LATIN   = "\x30\x30"
           CYRILIC = "\x30\x31"
           ARABIC  = "\x30\x32"
           GREEK   = "\x30\x33"
           HEBREW  = "\x30\x34"
        end
        module LC
            UNKNOWN       = '00'
            ALBANIAN      = '01'
            BRETON        = '02'
            CATALAN       = '03'
            CROATIAN      = '04'
            WELSH         = '05'
            CZECH         = '06'
            DANISH        = '07'
            GERMAN        = '08'
            ENGLISH       = '09'
            SPANISH       = '0A'
            ESPERANTO     = '0B'
            ESTONIAN      = '0C'
            BASQUE        = '0D'
            FAROESE       = '0E'
            FRISIAN       = '10'
            IRISH         = '11'
            GAELIC        = '12'
            GALICIAN      = '13'
            ICELANDIC     = '14'
            ITALIAN       = '15'
            LAPPISH       = '16'
            LATIN         = '17'
            LATVIAN       = '18'
            LUXEMBOURGIAN = '19'
            LITHUANIAN    = '1A'
            HUNGARIAN     = '1B'
            MALTESE       = '1C'
            DUTCH         = '1D'
            NORWEGIAN     = '1E'
            OCCITAN       = '1F'
            POLISH        = '20'
            PORTUGESE     = '21'
            ROMANIAN      = '22'
            ROMANSH       = '23'
            SERBIAN       = '24'
            SLOVAK        = '25'
            SLOVENIAN     = '26'
            FINNISH       = '27'
            SWEDISH       = '28'
            TURKISH       = '29'
            FLEMISH       = '2A'
            WALLON        = '2B'
            ZULU          = '45'
            VIETNAMESE    = '46'
            UZBEK         = '47'
            URDU          = '48'
            UKRAINIAN     = '49'
            THAI          = '4A'
            TELUGU        = '4B'
            TATAR         = '4C'
            TAMIL         = '4D'
            TADZHIK       = '4E'
            SWAHILI       = '4F'
            SRANAN_TONGO  = '50'
            SOMALI        = '51'
            SINHALESE     = '52'
            SHONA         = '53'
            SERBO_CROAT   = '54'
            RUTHENIAN     = '55'
            RUSSIAN       = '56'
            QUECHUA       = '57'
            PUSHTU        = '58'
            PUNJABI       = '59'
            PERSIAN       = '5A'
            PAPAMIENTO    = '5B'
            ORIYA         = '5C'
            NEPALI        = '5D'
            NDEBELE       = '5E'
            MARATHI       = '5F'
            MOLDAVIAN     = '60'
            MALAYSIAN     = '61'
            MALAGASAY     = '62'
            MACEDONIAN    = '63'
            LAOTIAN       = '64'
            KOREAN        = '65'
            KHMER         = '66'
            KAZAKH        = '67'
            KANNADA       = '68'
            JAPANESE      = '69'
            INDONESIAN    = '6A'
            HINDI         = '6B'
            HEBREW        = '6C'
            HAUSA         = '6D'
            GURANI        = '6E'
            GUJURATI      = '6F'
            GREEK         = '70'
            GEORGIAN      = '71'
            FULANI        = '72'
            DARI          = '73'
            CHURASH       = '74'
            CHINESE       = '75'
            BURMESE       = '76'
            BULGARIAN     = '77'
            BENGALI       = '78'
            BIELORUSSIAN  = '79'
            BAMBORA       = '7A'
            AZERBAIJANI   = '7B'
            ASSAMESE      = '7C'
            ARMENIAN      = '7D'
            ARABIC        = '7E'
            AMHARIC       = '7F'
        end
        module TNB
            # we are not limited to floppy discs anymore...
            # youtube ignore the entire header other than the magic bytes,
            # but it will not accept anything larger than 1440000 bytes
            # according to the specs
            MAX = '11242'
        end
        module TCS
            NOT_FOR_USE = "\x30"
            FOR_USE     = "\x31"
        end
        module CO
            ARUBA                                    = 'ABW'
            AFGHANISTAN                              = 'AFG'
            ANGOLA                                   = 'AGO'
            ANGUILLA                                 = 'AIA'
            ALBANIA                                  = 'ALB'
            ANDORRA                                  = 'AND'
            NETHERLANDS_ANTILLES                     = 'ANT'
            UNITED_ARAB_EMIRATES                     = 'ARE'
            ARGENTINA                                = 'ARG'
            AMERICAN_SAMOA                           = 'ASM'
            ANTARCTICA                               = 'ATA'
            FRENCH_SOUTHERN_TERRITORIES              = 'ATF'
            ANTIGUA_AND_BARBUDA                      = 'ATG'
            DRONNING_MAUD_LAND                       = 'ATN'
            AUSTRALIA                                = 'AUS'
            AUSTRIA                                  = 'AUT'
            BURUNDI                                  = 'BDI'
            BELGIUM                                  = 'BEL'
            BENIN                                    = 'BEN'
            BURKINA_FASO                             = 'BFA'
            BANGLADESH                               = 'BGD'
            BULGARIA                                 = 'BGR'
            BAHRAIN                                  = 'BHR'
            BAHAMAS                                  = 'BHS'
            BELIZE                                   = 'BLZ'
            BERMUDA                                  = 'BMU'
            BOLIVIA                                  = 'BOL'
            BRAZIL                                   = 'BRA'
            BARBADOS                                 = 'BRB'
            BRUNEI_DARUSSALAM                        = 'BRN'
            BHUTAN                                   = 'BTN'
            BURMA                                    = 'BUR'
            BOUVET_ISLAND                            = 'BVT'
            BOTSWANA                                 = 'BWA'
            BYELORUSSIAN_SSR                         = 'BYS'
            CENTRAL_AFRICAN_REPUBLIC                 = 'CAF'
            CANADA                                   = 'CAN'
            COCOS_ISLANDS                            = 'CCK'
            SWITZERLAND                              = 'CHE'
            CHILE                                    = 'CHL'
            CHINA                                    = 'CHN'
            COTE_DIVOIRE                             = 'CIV'
            CAMEROON                                 = 'CMR'
            CONGO                                    = 'COG'
            COOK_ISLANDS                             = 'COK'
            COLOMBIA                                 = 'COL'
            COMOROS                                  = 'COM'
            CAPE_VERDE                               = 'CPV'
            COSTA_RICA                               = 'CRI'
            CZECHOSLOVAKIA                           = 'CSK'
            CANTON_AND_ENDERBURY_ISLANDS             = 'CTE'
            CUBA                                     = 'CUB'
            CHRISTMAS_ISLAND                         = 'CXR'
            CAYMAN_ISLANDS                           = 'CYM'
            CYPRUS                                   = 'CYP'
            GERMAN_DEMOCRATIC_REPUBLIC               = 'DDR'
            FEDERAL_REPUBLIC_GERMANY                 = 'DEU'
            KAMPUCHEA                                = 'DHM'
            DJIBOUTI                                 = 'DJI'
            DOMINICA                                 = 'DMA'
            DENMARK                                  = 'DNK'
            DOMINICAN_REPUBLIC                       = 'DOM'
            ALGERIA                                  = 'DZA'
            ECUADOR                                  = 'ECU'
            EGYPT                                    = 'EGY'
            WESTERN_SAHARA                           = 'ESH'
            SPAIN                                    = 'ESP'
            ETHIOPIA                                 = 'ETH'
            FINLAND                                  = 'FIN'
            FIJI                                     = 'FJI'
            FALKLAND_ISLANDS                         = 'FLK'
            FRANCE                                   = 'FRA'
            FAROE_ISLANDS                            = 'FRO'
            MICRONESIA                               = 'FSM'
            GABON                                    = 'GAB'
            UNITED_KINGDOM                           = 'GBR'
            GHANA                                    = 'GHA'
            GIBRALTAR                                = 'GIB'
            GUINEA                                   = 'GIN'
            GUADELOUPE                               = 'GLP'
            GAMBIA                                   = 'GMB'
            GUINEA_BISSAU                            = 'GNB'
            EQUATORIAL_GUINEA                        = 'GNQ'
            GREECE                                   = 'GRC'
            GRENADA                                  = 'GRD'
            GREENLAND                                = 'GRL'
            GUATEMALA                                = 'GTM'
            FRENCH_GUINEA                            = 'GUF'
            GUAM                                     = 'GUM'
            GUYANA                                   = 'GUY'
            HONG_KONG                                = 'HKG'
            HEARD_AND_MC_DONALD_ISLANDS              = 'HMD'
            HONDURAS                                 = 'HND'
            HAITI                                    = 'HTI'
            HUNGARY                                  = 'HUN'
            UPPER_VOLTA                              = 'HVO'
            INDONESIA                                = 'IDN'
            INDIA                                    = 'IDN'
            BRITISH_INDIAN_OCEAN_TERRITORY           = 'IOT'
            IRELAND                                  = 'IRL'
            IRAN                                     = 'IRN'
            IRAQ                                     = 'IRQ'
            ICELAND                                  = 'ISL'
            ISRAEL                                   = 'ISR'
            ITALY                                    = 'ITA'
            JAMAICA                                  = 'JAM'
            JORDAN                                   = 'JOR'
            JAPAN                                    = 'JPN'
            JOHNSTON_ATOLL                           = 'JTN'
            KENYA                                    = 'KEN'
            KIRIBATI                                 = 'KIR'
            SAINT_KITTS_AND_NEVIS                    = 'KNA'
            REPUBLIC_OF_KOREA                        = 'KOR'
            KUWAIT                                   = 'KWT'
            DEMOCRATIC_REPUBLIC_OF_LAO               = 'LAO'
            LEBANON                                  = 'LBN'
            LIBERIA                                  = 'LBR'
            LIBYAN_ARAB_JAMAHIRIYA                   = 'LBY'
            SAINT_LUCIA                              = 'LCA'
            LIECHTENSTEIN                            = 'LIE'
            SRI_LANKA                                = 'LKA'
            LESOTHO                                  = 'LSO'
            LUXEMBOURG                               = 'LUX'
            MACAU                                    = 'MAC'
            MOROCCO                                  = 'MAR'
            MONACO                                   = 'MCO'
            MADAGASCAR                               = 'MDG'
            MALDIVES                                 = 'MDV'
            MEXICO                                   = 'MEX'
            MARSHALL_ISLANDS                         = 'MHL'
            MIDWAY_ISLANDS_                          = 'MID'
            MALI                                     = 'MLI'
            MALTA                                    = 'MLT'
            MONGOLIA                                 = 'MNG'
            NORTHERN_MARIANA_ISLANDS                 = 'MNP'
            MOZAMBIQUE                               = 'MOZ'
            MAURITANIA                               = 'MRT'
            MONTSERRAT                               = 'MSR'
            MARTINIQUE                               = 'MTQ'
            MAURITIUS                                = 'MUS'
            MALAWI                                   = 'MWI'
            MALAYSIA                                 = 'MYS'
            NAMIBIA                                  = 'NAM'
            NEW_CALEDONIA                            = 'NCL'
            NIGER                                    = 'NER'
            NORFOLK_ISLAND                           = 'NFK'
            NIGERIA                                  = 'NGA'
            NICARAGUA                                = 'NIC'
            NIUE                                     = 'NIU'
            NETHERLANDS                              = 'NLD'
            NORWAY                                   = 'NOR'
            NEPAL                                    = 'NPL'
            NAURU                                    = 'NRU'
            NEUTRAL_ZONE                             = 'NTZ'
            NEW_ZEALAND                              = 'NZL'
            OMAN                                     = 'OMN'
            ESCAPE_CODE                              = 'OOO'
            PAKISTAN                                 = 'PAK'
            PANAMA                                   = 'PAN'
            MICRONESIA_ALT                           = 'PCI'
            PITCAIRN                                 = 'PCN'
            PERU                                     = 'PER'
            PHILIPPINES                              = 'PHL'
            PALAU                                    = 'PLW'
            PAPUA_NEW_GUINEA                         = 'PNG'
            POLAND                                   = 'POL'
            PUERTO_RICO                              = 'PRI'
            PEOPLES_REPUBLIC_OF_KOREA                = 'PRK'
            PORTUGAL                                 = 'PRT'
            PARAGUAY                                 = 'PRY'
            US_MISC_PACIFIC_ISLANDS                  = 'PUS'
            FRENCH_POLYNESIA                         = 'PYF'
            QATAR                                    = 'QAT'
            REUNION                                  = 'REU'
            ROMANIA                                  = 'ROM'
            RWANDA                                   = 'RWA'
            SAUDI_ARABIA                             = 'SAU'
            SUDAN                                    = 'SDN'
            SENEGAL                                  = 'SEN'
            SINGAPORE                                = 'SGP'
            ST_HELENA                                = 'SHN'
            SVALBARD_AND_JAN_MAYEN_ISLANDS           = 'SJM'
            SOLOMON_ISLANDS                          = 'SLB'
            SIERRA_LEONE                             = 'SLE'
            EL_SALVADOR                              = 'SLV'
            SAN_MARINO                               = 'SMR'
            SOMALIA                                  = 'SOM'
            ST_PIERRE_AND_MIQUELON                   = 'SPM'
            SAO_TOME_AND_PRINCIPE                    = 'STP'
            USSR                                     = 'SUN'
            SURINAM                                  = 'SUR'
            SWEDEN                                   = 'SWE'
            SWAZILAND                                = 'SWZ'
            SEYCHELLES                               = 'SYC'
            SYRIAN_ARAB_REPUBLIC                     = 'SYR'
            TURKS_AND_CAICOS_ISLANDS                 = 'TCA'
            CHAD                                     = 'TCD'
            TOGO                                     = 'TGO'
            THAILAND                                 = 'THA'
            TOKELAU                                  = 'TKL'
            EAST_TIMOR                               = 'TMP'
            TONGA                                    = 'TON'
            TRINIDAD_AND_TOBAGO                      = 'TTO'
            TUNISIA                                  = 'TUN'
            TURKEY                                   = 'TUR'
            TUVALU                                   = 'TUV'
            TAIWAN                                   = 'TWN'
            TANZANIA                                 = 'TZA'
            UGANDA                                   = 'UGA'
            UKRAINIAN_SSR                            = 'UKR'
            US_MINOR_OUTLYING_ISLANDSS               = 'UMI'
            URUGUAY                                  = 'URY'
            UNITED_STATES                            = 'USA'
            HOLY_VATICAN_CITY                        = 'VAT'
            SAINT_VINCENT_AND_GRENADINES             = 'VCT'
            VENEZUELA                                = 'VEN'
            VIRGIN_ISLANDS_BRITISH                   = 'VGB'
            VIRGIN_ISLANDS_US                        = 'VIR'
            VIET_NAM                                 = 'VNM'
            VANUATU                                  = 'VUT'
            WAKE_ISLAND                              = 'WAK'
            WALLIS_AND_FUTUNA_ISLANDS                = 'WLF'
            SAMOA                                    = 'WSM'
            YEMEN                                    = 'YEM'
            DEMOCRATIC_YEMEN                         = 'YMD'
            YUGOSLAVIA                               = 'YUG'
            SOUTH_AFRICA                             = 'ZAF'
            ZAIRE                                    = 'ZAR'
            ZAMBIA                                   = 'ZMB'
            ZIMBABWE                                 = 'ZWE'
        end
    end
    module HeaderDefault
        CPN = HeaderOption::CPN::UNITED_STATES
        DFC = HeaderOption::DFC::STL_30
        DSC = HeaderOption::DSC::TELETEXT_LEVEL_2
        CCT = HeaderOption::CCT::LATIN
        LC  = HeaderOption::LC::UNKNOWN
        OPT = 'stl file created by ruby script '
        OET = HeaderOption::FILLER * 32
        TPT = HeaderOption::FILLER * 32
        TET = HeaderOption::FILLER * 32
        TN  = HeaderOption::FILLER * 32
        TCD = HeaderOption::FILLER * 32
        SLR = HeaderOption::FILLER * 16
        CD  = '900522'
        RD  = '900522'
        RN  = '00'
        TNB = '00000'
        TNS = '00000'
        TNG = '000'
        MNC = '32'
        MNR = '16'
        TCS = HeaderOption::TCS::FOR_USE
        TCP = '00000000'
        TCF = '00000000'
        TND = '1'
        DSN = '1'
        CO  = HeaderOption::CO::NEUTRAL_ZONE
        PUB = HeaderOption::FILLER * 32
        EN  = HeaderOption::FILLER * 32
        ECD = HeaderOption::FILLER * 32
        SB  = HeaderOption::FILLER * 75
        UDA = HeaderOption::FILLER * 576
    end
    module HeaderAssert
        VALID_CODEPAGE = [ "\x34\x33\x37", "\x38\x35\x30", "\x38\x36\x30",
                           "\x38\x36\x33", "\x38\x36\x35"
                         ]
        CPN = lambda { VALID_CODEPAGE.include?(value) }
        DFC = lambda { value == 'STL25.01' || value == 'STL30.01' }
        DSC = lambda { value == "\x20" || value >= "\x30" && value <= "\x32" }
        CCT = lambda { value[0] == "\x30" && value[1] >= "\x30" && value[1] <= "\x34" }
        TCS = lambda { value == "\x30" || value == "\x31" }
        TND = lambda { value >= '1' && value <= '9' }
        DSN = lambda { value >= "\x31" && value <= "\x39" }
        CO  = lambda { !HeaderNames::CO[value.upcase].nil? }
        LC  = lambda { !HeaderNames::LC[value.to_i.to_s.rjust(2,'0')].nil? }
        MNC = lambda { x=value.chomp.strip.rjust(2,'0') ; x >= "\x30\x30" && x <= "\x39\x39" }
        MNR = lambda { x=value.chomp.strip.rjust(2,'0') ; x >= "\x30\x30" && x <= "\x39\x39" }
        TNB = lambda { x=value.chomp.strip.rjust(5,'0') ; x >= "\x30\x30\x30\x30\x30" && x <= "\x31\x31\x32\x34\x32" }
        TNS = lambda { x=value.chomp.strip.rjust(5,'0') ; x >= "\x30\x30\x30\x30\x30" && x <= "\x39\x39\x39\x39\x39" }
        TNG = lambda { x=value.chomp.strip.rjust(3,'0') ; x >= "\x30\x30\x30" && x <= "\x39\x39\x39" }
        TCP = lambda { (0..99).include?(value[0..1].chomp.strip.to_i) && (0..59).include?(value[2..3].chomp.strip.to_i) && (0..59).include?(value[4..5].chomp.strip.to_i) && (0..29).include?(value[6..7].chomp.strip.to_i) }
        TCF = TCP
    end
    module HeaderNames
        CCT = { HeaderOption::CCT::LATIN   => :latin,
                HeaderOption::CCT::CYRILIC => :cyrilic,
                HeaderOption::CCT::ARABIC  => :arabic,
                HeaderOption::CCT::GREEK   => :greek,
                HeaderOption::CCT::HEBREW  => :hebrew }
        
        CPN = { HeaderOption::CPN::UNITED_STATES    => :us,
                HeaderOption::CPN::MULTILINGUAL     => :multi,
                HeaderOption::CPN::PORTUGAL         => :portugal,
                HeaderOption::CPN::CANADA_FRENCH    => :canada_french,
                HeaderOption::CPN::NORWAY           => :norway }
        
        DFC = { HeaderOption::DFC::STL_25           => :stl25,
                HeaderOption::DFC::STL_30           => :stl30 }
        
        DSC = { HeaderOption::DSC::BLANK            => :none,
                HeaderOption::DSC::OPEN_SUBTITLING  => :open_sub,
                HeaderOption::DSC::TELETEXT_LEVEL_1 => :teletext_lv1,
                HeaderOption::DSC::TELETEXT_LEVEL_2 => :teletext_lv2 }
        
        TCS = { HeaderOption::TCS::NOT_FOR_USE      => :do_no_use,
                HeaderOption::TCS::FOR_USE          => :use }

        CO  = {}
        LC  = {}
        HeaderOption::CO.constants.each do |co|
            CO[HeaderOption::CO.const_get(co)] = co.to_s
        end
        HeaderOption::LC.constants.each do |co|
            LC[HeaderOption::LC.const_get(co)] = co.to_s
        end
    end
    
    module BodyOption
        module EBN
            LAST_BLOCK = 0xff
            MAX        = 0xef
        end
        module CS
            NOT_PART_OF_CUMULATIVE_SET          = 0
            FIRST_PART_OF_CUMULATIVE_SET        = 1
            INTERMEDIATE_PART_OF_CUMULATIVE_SET = 2
            LAST_PART_OF_CUMULATIVE_SET         = 3
        end
        module JC
            UNCHANGED       = 0
            LEFT_JUSTIFIED  = 1
            CENTERED        = 2
            RIGHT_JUSTIFIED = 3
        end
        module CF
            SUBTITLE_DATA        = 0
            NOT_FOR_TRANSMISSION = 1
        end
        module TF
            FILLER          = CodePage::ControlCode::FILLER
            MAX_DATA_LENGTH = 112
        end
        module SN
            MAX = 0xFFFF
        end
        module SGN
            MAX = 0xFF
        end
    end
    module BodyDefault
        SGN = 0x00
        SN  = 0x0000
        EBN = 0xFF
        CS  = BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET
        TCI = "\x00\x00\x00\x00"
        TCO = "\x17\x3b\x3b\x18"
        VP  = 0x01
        JC  = BodyOption::JC::UNCHANGED
        CF  = BodyOption::CF::SUBTITLE_DATA
        TF  = CodePage::ControlCode::FILLER * 112
    end
    module BodyAssert
        CS  = lambda { value <= 0x03 }
        TCI = lambda { value.getbyte(0) <= 23 &&
                       value.getbyte(1) <= 59 &&
                       value.getbyte(2) <= 59 &&
                       value.getbyte(3) <= 29
                     }
        TCO = TCI
        VP  = lambda { value <= 0x63 }
        JC  = lambda { value <= 0x03 }
        CF  = lambda { value <= 0x01 }
        EBN = lambda { !("\xf0".."\xfd").include?(value) }
    end
    module BodyNames
        CS = { BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET          => :single,
               BodyOption::CS::FIRST_PART_OF_CUMULATIVE_SET        => :first,
               BodyOption::CS::INTERMEDIATE_PART_OF_CUMULATIVE_SET => :middle,
               BodyOption::CS::LAST_PART_OF_CUMULATIVE_SET         => :last }
        
        JC = { BodyOption::JC::UNCHANGED       => :default,
               BodyOption::JC::LEFT_JUSTIFIED  => :left,
               BodyOption::JC::CENTERED        => :centered,
               BodyOption::JC::RIGHT_JUSTIFIED => :right }
        
        CF = { BodyOption::CF::SUBTITLE_DATA        => :subtitle,
              BodyOption::CF::NOT_FOR_TRANSMISSION  => :comment } 
    end
    
    # header gsi
    # general subtitle information
    class Gsi < BinData::Record
        string :cpn, :length => 3,  :initial_value => HeaderDefault::CPN, :assert => HeaderAssert::CPN  # code page number
        string :dfc, :length => 8,  :initial_value => HeaderDefault::DFC, :assert => HeaderAssert::DFC  # disk format code
        string :dsc, :length => 1,  :initial_value => HeaderDefault::DSC, :assert => HeaderAssert::DSC  # display standard code
        string :cct, :length => 2,  :initial_value => HeaderDefault::CCT, :assert => HeaderAssert::CCT  # character code table number
        string :lc,  :length => 2,  :initial_value => HeaderDefault::LC,  :assert => HeaderAssert::LC   # language code
        string :opt, :length => 32, :initial_value => HeaderDefault::OPT                                # original program title
        string :oet, :length => 32, :initial_value => HeaderDefault::OET                                # original episode title
        string :tpt, :length => 32, :initial_value => HeaderDefault::TPT                                # translated program title
        string :tet, :length => 32, :initial_value => HeaderDefault::TET                                # translated episode title
        string :tn,  :length => 32, :initial_value => HeaderDefault::TN                                 # translator's name
        string :tcd, :length => 32, :initial_value => HeaderDefault::TCD                                # translator's contact details
        string :slr, :length => 16, :initial_value => HeaderDefault::SLR                                # subtitle list reference code
        string :cd,  :length => 6,  :initial_value => HeaderDefault::CD                                 # creation date
        string :rd,  :length => 6,  :initial_value => HeaderDefault::RD                                 # revision date
        string :rn,  :length => 2,  :initial_value => HeaderDefault::RN                                 # revision number
        string :tnb, :length => 5,  :initial_value => HeaderDefault::TNB, :assert => HeaderAssert::TNB  # total number tti blocks
        string :tns, :length => 5,  :initial_value => HeaderDefault::TNS, :assert => HeaderAssert::TNS  # total number subtitles
        string :tng, :length => 3,  :initial_value => HeaderDefault::TNG, :assert => HeaderAssert::TNG  # total number subitle groups
        string :mnc, :length => 2,  :initial_value => HeaderDefault::MNC, :assert => HeaderAssert::MNC  # maximum number of displayable chars/row
        string :mnr, :length => 2,  :initial_value => HeaderDefault::MNR, :assert => HeaderAssert::MNR  # maximum number of displayable rows
        string :tcs, :length => 1,  :initial_value => HeaderDefault::TCS, :assert => HeaderAssert::TCS  # time code status
        string :tcp, :length => 8,  :initial_value => HeaderDefault::TCP, :assert => HeaderAssert::TCP  # time code: start-of-program
        string :tcf, :length => 8,  :initial_value => HeaderDefault::TCF, :assert => HeaderAssert::TCF  # time code: first-in-cue
        string :tnd, :length => 1,  :initial_value => HeaderDefault::TND, :assert => HeaderAssert::TND  # total number of disks
        string :dsn, :length => 1,  :initial_value => HeaderDefault::DSN, :assert => HeaderAssert::DSN  # disc sequence number
        string :co,  :length => 3,  :initial_value => HeaderDefault::CO,  :assert => HeaderAssert::CO   # country of origin
        string :pub, :length => 32, :initial_value => HeaderDefault::PUB                                # publisher
        string :en,  :length => 32, :initial_value => HeaderDefault::EN                                 # editor's name
        string :ecd, :length => 32, :initial_value => HeaderDefault::ECD                                # editor's contact details
        string :sb,  :length => 75, :initial_value => HeaderDefault::SB                                 # spare bytes
        string :uda, :length => 576,:initial_value => HeaderDefault::UDA                                # user defined area

        virtual :assert => lambda { 
            if dfc=='STL30.01' || tcp[6..7].to_i<=24 && tcf[6..7].to_i<=24
                true
            else
                raise BinData::ValidityError,
                'tcp/tcf, time code: frames must be <= fps'
            end
        }
    end
   
    # body tti
    # text and timing information block
    class Tti < BinData::Record
       uint8    :sgn, :length => 1,   :initial_value => BodyDefault::SGN                             # subtitle group number
       uint16be :sn,  :length => 2,   :initial_value => BodyDefault::SN                              # subtitle number
       uint8    :ebn, :length => 1,   :initial_value => BodyDefault::EBN, :assert => BodyAssert::EBN # extension block number
       uint8    :cs,  :length => 1,   :initial_value => BodyDefault::CS,  :assert => BodyAssert::CS  # cumulative status
       string   :tci, :length => 4,   :initial_value => BodyDefault::TCI, :assert => BodyAssert::TCI # time code in
       string   :tco, :length => 4,   :initial_value => BodyDefault::TCO, :assert => BodyAssert::TCO # time code out
       uint8    :vp,  :length => 1,   :initial_value => BodyDefault::VP,  :assert => BodyAssert::VP  # vertical position
       uint8    :jc,  :length => 1,   :initial_value => BodyDefault::JC,  :assert => BodyAssert::JC  # justification code
       uint8    :cf,  :length => 1,   :initial_value => BodyDefault::CF,  :assert => BodyAssert::CF  # comment flag
       string   :tf,  :length => 112, :initial_value => BodyDefault::TF,  :pad_byte => BodyOption::TF::FILLER # text field
    end

    # gsi header + many tti blocks
    class EbuStl < BinData::Record
        gsi     :gsi
        array   :tti, :type => :tti, :read_until => :eof
       
        # check time codes (tci, tco) and vertical position (vp)
        virtual :assert => lambda {
            ass_tc = { 'STL25.01' => 24, 'STL30.01' => 29 }
            ass_vp = { "\x30" => (0..99), "\x31" => (1..23), "\x32" => (1..23), "\x20" => (0..99) }
            if tti.any? do |block|
                    block.tci.getbyte(3) > ass_tc[gsi.dfc] ||
                    block.tco.getbyte(3) > ass_tc[gsi.dfc] ||
                    !ass_vp[gsi.dsc].include?(block.vp)
                end
                raise BinData::ValidityError,
                      'timecode: frames must be <= fps'
            else
                true
            end
        }
      
        # disc number must not exceed total number of discs
        virtual :assert => lambda {
            if gsi.dsn <= gsi.tnd
                true
            else
                raise BinData::ValidityError,
                      'disc number exceeds total number of discs'
            end
        }
              
        # check tti count
        virtual :assert => lambda { 
            if gsi.tnb.to_i == tti.length
                true
            else
                raise BinData::ValidityError,
                'actual tti block count does not match the header info'
            end
        }
    end

    class StlTools

        include Converter
        
        BEHEADED = true
        
        public
       
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
                    
        # Add subtitle line(s)
        # Time is in seconds relative to the beginning of the video file
        # Raises NoMemoryError if no more block can be stored, or not all lines
        # could be added.
        # Raises ArgumentError when lines cannot be  not an array consisting of string.
        # Does not check lines for proper formatting.
        def push(t1, t2, lines, row=1,
            adjust=BodyNames::JC[BodyOption::JC::CENTERED], 
            cum=BodyNames::CS[BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET])
            
            # sanity checks
            raise NoMemoryError, :maximum_size_reached if full? # storage size

            return if (t1-t2).abs < 1.0/30.0                    # no subframes
            
            return unless lines = sanitize_lines(lines)         # invalid subs
            
            # get constants
            filler          = CodePage::ControlCode::FILLER           
            max_text_length = BodyOption::TF::MAX_DATA_LENGTH # 111
            max_data_length = BodyOption::TF::MAX_DATA_LENGTH # 112
            max_tti_blocks  = HeaderOption::TNB::MAX.to_i
            
            # extension block number
            ebn = 0
            
            # comment flag
            cf = BodyOption::CF::SUBTITLE_DATA

            # cumulative status
            cs = get_option(:Body,:CS,cum)#  to_cumulative_status(cum)
           
            # justification code (jc)
            jc = get_option(:Body,:JC,adjust)#to_justification_code(adjust)

            # get vertical position (vp) and trim lines
            vp = to_internal_row(row, lines)
            
            # time code (tci, tco)
            tci, tco = to_timecode(t1,t2)
            
            # text field
            
            # clean extra newlines and coerce input into valid utf8 encoding
            lines.map! { |line| line.tr("\n",'').valid_utf8('')}

            # apply styling and convert to iso
            bytes = CodePage::encode_body(lines, @codepage_body, @gsi.mnc.to_i)
            
            # we are using binary encoding, so it *should* be equal to #length
            # one byte is added because the last block must end on \x8f
            bytesize = bytes.bytesize + 1

            # at most 0xf0 extension blocks
            # that's 26640 letters on screen - simultaneously
            if bytesize > (BodyOption::EBN::MAX+1) * max_text_length
                raise NoMemoryError, :long_subtitle
            end
            
            # create data blocks, split data into slices of max_text_length
            ((bytesize-1)/max_text_length+1).times do
                slice = bytes.slice!(0,max_text_length)
                # set options
                block = Tti.new
                block.sgn = @sgn
                block.sn  = @sn
                block.ebn = ebn
                block.cs  = cs
                block.tci = tci
                block.tco = tco
                block.vp  = vp
                block.jc  = jc
                block.cf  = cf
                block.tf  = slice.ljust(max_data_length, filler)
                # add block to subtitles
                @tti.push(block)
                # increment extension block number
                ebn += 1
                # check data block count
                if @tti.length >= max_tti_blocks
                    @full = true
                    @full.freeze
                    break
                end
            end

            # correct extension block number (last block need 0xFF)
            @tti.last.ebn = BodyOption::EBN::LAST_BLOCK
            
            # last byte of subtitle needs to be "\x8f"
            tf_string =@tti.last.tf.to_s
            tf_string[BodyOption::TF::MAX_DATA_LENGTH-1] = filler
            @tti.last.tf = tf_string
           
            raise NoMemoryError, :subtitle_truncated if full?
            
            increment_subtitle
            finalize!
        end
        alias_method :subtitle, :push
        
        # writes to given file or file handler,
        # raises IOError if it fails to write to file
        def write(fof)
            # header data, block count
            finalize!
            Util::iostream(fof, 'wb') do |io|
                # yes, all these errors can be raised when calling #write
                @stl.write(io)
            end
        end
        alias_method :output, :write
        
        # Creates and return new stl file from an IO object or file.
        # Try skipping the header, many stl exports don't care about the header.
        def self.read(fin, skip_header = false)
            new_stl = nil
            Util::iostream(fin,'rb') do |io|
                if skip_header
                    io.read(1024)
                    ebu_stl = EbuStl.new
                    ebu_stl.tti.read(io)
                else
                    ebu_stl = EbuStl.read(io)
                end
                new_stl = StlTools.new(ebu_stl)
            end
            # normalize
            new_stl.send(:normalize_header!)
            return new_stl
        end

        # Ignore header when assertion fails.
        def self.backtrace_read(fin)
            BinData::trace_reading do
                return read(fin)
            end
        end

        # Returns a new stl handler with all subitles within the interval
        # TODO adjust cumulative status (stl.tti.cs)
        def slice(t1=0.0, t2=359999.96, trim_to_interval=true)
            t1, t2 = t1.to_f, t2.to_f
            return if t2 <= t1
            new_stl     = EbuStl.new
            new_stl.gsi = @gsi
            # time code: first in cue
            new_stl.gsi.tcf = Util.timecode(t1, @fps).bytes.map do |x|
                x.to_s.rjust(2,'0')
            end.join
            #
            new_tti     = new_stl.tti
            interval    = (t1..t2)
            # must not split extension blocks
            must_keep = false
            sn  = 0
            sgn = 0
            Util.monkey_patch(:overlap? => Range) do
                @tti.each do |block|
                    tci = Util.seconds(block.tci, @fps)
                    tco = Util.seconds(block.tco, @fps)
                    if must_keep || (tci..tco).overlap?(interval)
                        new_tti.push(block)
                        # limit subtitle to the interval
                        new_block = new_tti.last
                        if trim_to_interval
                            new_block.tci = Util.timecode(t1, @fps) if tci < t1
                            new_block.tco = Util.timecode(t2, @fps) if tco > t2
                        end
                        # adjust subtitle number
                        new_block.sn  = sn
                        new_block.sgn = sgn
                        # 255 marks the end of an extension block
                        must_keep = (new_block.ebn != 255)
                        # splitting from a valid file, sgn cannt exceed its maximum
                        sn += 1
                        if @sn > BodyOption::SN::MAX
                            @sn = 0x00
                            @sgn += 0x01
                        end
                    end
                end
            end
            return StlTools.new(new_stl)
        end
        
        def split(t)
            #            null byte             magic   ntsc-pal conversion
            return slice(0x000000,t), slice(t,0x057e3f+060/50.to_f)
        end
        
        # prettry printing with terminal color codes
        def pprint(of = $stdout, len = 91, colors=true)
            return unless of.respond_to?(:<<)
            pprint_info(of, len)
            of << "\n" * 2
            pprint_subs(of, len, colors)
            of << "\n" * 2
            pprint_meta(of, len)
        end
 
        def pprint_info(of = $stdout, len=91)
            return unless of.respond_to?(:<<)
            len  = 91 if len < 91
            endl = "\n"
            bdr  = Util::BOXDRAWINGS
            sep   = (len-78)/2
            empty = ''.force_encoding(Encoding::UTF_8)            
            spc   = ' '.force_encoding(Encoding::UTF_8)            
            codepage = @codepage_header::HASH_BYTE_TO_UTF8
            
            Util.monkey_patch(:cjust => String) do 

                # Header
                
                #/====================================\#
                of << bdr[:dedges][:tl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:tr]                #
                of << endl                             #
                #                                      #
                #................Header................#
                of << bdr[:dbar][:ver]                 #
                of << '  Header  '.cjust(len-2,bdr[:lbar][:hor])
                of << bdr[:dbar][:ver]                 #
                of << endl                             #
                #                                      #
                of << bdr[:dedges][:bl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:br]                #
                of << endl                             #
                #\====================================/#
                
                
                #/------------------------------------\#                
                of << bdr[:edge][:tl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:tr]                  #
                of << endl                             #
                #                                      #
                @gsi.each_pair do |field, value|
                    # map to unicode
                    value = value.gsub(/./) { |chr| codepage[chr] || empty }

                    # add name for value
                    name = field.to_s.upcase
                    
                    # normalize
                    if field == :lc || field == 'cct'
                        value = value.to_i.to_s.rjust(2,'0')
                    elsif field == :co
                        value = value.chomp.upcase
                    end
                    if HeaderNames.const_defined?(name)
                        if desc = HeaderNames.const_get(name)[value]
                            value = value + ' (' + desc.to_s + ') '
                        end
                    elsif field == :sb
                        value = '---'
                    elsif field == :uda
                        value = '(see below)'
                    end                  

                    sep_adj = value.length-32
                    sep_adj = 0 if sep_adj < 0
                    of << bdr[:bar][:ver] << spc
                    of << field.to_s.ljust(3)
                    of << spc * sep
                    of << value.ljust(32)
                    of << spc * (sep-sep_adj)
                    of << English::HEADER[field.to_s.downcase.to_sym].ljust(39)
                    of << spc * (len-77-2*sep) << bdr[:bar][:ver]
                    of << endl
                end

                #                                      #
                of << bdr[:edge][:bl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:br]                  #
                of << endl                             #
                #\------------------------------------/#

                of << endl * 2

                
                # User Defined Area
                
                #/====================================\#
                of << bdr[:dedges][:tl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:tr]                #
                of << endl                             #
                #                                      #
                #...........User-Defined-Area..........#
                of << bdr[:dbar][:ver]                 #
                of << '  User-Defined-Area  '.cjust(len-2,bdr[:lbar][:hor])
                of << bdr[:dbar][:ver]                 #
                of << endl                             #
                #                                      #
                of << bdr[:dedges][:bl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:br]                #
                of << endl                             #
                #\====================================/#


                #/------------------------------------\#                
                of << bdr[:edge][:tl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:tr]                  #
                of << endl                             #
                #                                      #
                @gsi.uda.each_char.map{|chr|codepage[chr]|| empty}.
                each_slice(len-4) do |slice|           #
                    of << bdr[:bar][:ver] << spc       #
                    of << slice.join.ljust(len-4)      #
                    of << spc                          #
                    of << bdr[:bar][:ver] << endl      #
                end                                    #
                #                                      #
                of << bdr[:edge][:bl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:br]                  #
                of << endl                             #
                #\------------------------------------/#
            end
        end
        
        def pprint_subs(of=$stdout, len=91, colors=true)
            return if @tti.length == 0
            return unless of.respond_to?(:<<)

            # text is upto 112 characters and should not be broken
            len  = 91 if len < 91
            len = len < 114 ? 114 : len            
            
            endl     = "\n"
            spc      = ' '.force_encoding(Encoding::UTF_8)
            slash    = "\xe2\x81\x84".force_encoding(Encoding::UTF_8)
            
            idx_max = @tti.length - 1 
            bln     = len-7
            
            bdr      = Util::BOXDRAWINGS
            
            num_sup  = {'0' => "\xe2\x81\xb0",
                        '1' => "\xc2\xb9",
                        '2' => "\xc2\xb2",
                        '3' => "\xc2\xb3",
                        '4' => "\xe2\x81\xb4",
                        '5' => "\xe2\x81\xb5",
                        '6' => "\xe2\x81\xb6",
                        '7' => "\xe2\x81\xb7",
                        '8' => "\xe2\x81\xb8",
                        '9' => "\xe2\x81\xb9"
                       }.each_value{|x|x.force_encoding(Encoding::UTF_8)}
            num_sub  = {'0' => "\xe2\x82\x80",
                        '1' => "\xe2\x82\x81",
                        '2' => "\xe2\x82\x82",
                        '3' => "\xe2\x82\x83",
                        '4' => "\xe2\x82\x84",
                        '5' => "\xe2\x82\x85",
                        '6' => "\xe2\x82\x86",
                        '7' => "\xe2\x82\x87",
                        '8' => "\xe2\x82\x88",
                        '9' => "\xe2\x82\x89"
                       }.each_value{|x|x.force_encoding(Encoding::UTF_8)}            
            parenthesis_s_left  = "\xe2\x82\x8d".force_encoding(Encoding::UTF_8)
            parenthesis_s_right = "\xe2\x82\x8e".force_encoding(Encoding::UTF_8)
            
            Util.monkey_patch(:cjust => String) do
                # SUBTITLES

                #/====================================\#
                of << bdr[:dedges][:tl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:tr]                #
                of << endl                             #
                #                                      #
                #...............Subtitles..............#
                of << bdr[:dbar][:ver]                 #
                of << '  Subtitles  '.cjust(len-2,bdr[:lbar][:hor])
                of << bdr[:dbar][:ver]                 #
                of << endl                             #
                #                                      #
                of << bdr[:dedges][:bl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:br]                #
                of << endl                             #
                #\====================================/#
                
                of << endl

                of << 'block number / subtitle number (group number)'.cjust(len)

                of << endl
                
                #/------------------------------------\#                
                of << bdr[:edge][:tl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:tr]                  #
                of << endl                             #
                
                # calls block with tti-block, its index, the formatted text,
                # and the number of printable characters excluding control codes
                each_block_with_index_styled(@tti, colors) do |block,idx,text,n|
                    # colorize and decode
                     m    = len-n-2
                     text = spc * (m/2) + text + spc*(m-m/2)

                    #|--------this is a subtitle-------#
                    of << bdr[:bar][:ver]              #
                    of << text                         #
                    of << bdr[:bar][:ver]              #
                   
                    of << endl
                    
                    #-----------00314/00334------------#
                    if idx != idx_max                  #
                        of << bdr[:comb][:vernr]       # 
                        of << bdr[:nbar][:hor]*(bln/2-5)#
                        of << idx.to_s.rjust(5,'0').   #
                         chars.map{|x|num_sup[x]}.join #
                        of << slash                    #
                        of << block.sn.to_s.rjust(5,'0').
                         chars.map{|x|num_sub[x]}.join #
                        of << parenthesis_s_left     #
                        of << block.sgn.to_s.rjust(3,'0').
                         chars.map{|x|num_sub[x]}.join #
                        of << parenthesis_s_right    #
                        of << bdr[:nbar][:hor] * (bln-bln/2-6)
                        of << bdr[:comb][:vernl]       #
                        of << endl                     #
                    end                                #
                end

                of << bdr[:edge][:bl]                  #
                of << ''.cjust(len-2,bdr[:bar][:hor])  #
                of << bdr[:edge][:br]                  #
                of << endl                             #
                #\------------------------------------/#
            end
        end
        
        def pprint_meta(of=$stdout, len=91)
            return if @tti.length == 0
            return unless of.respond_to?(:<<)
            len  = 91 if len < 91          
            endl     = "\n"
            bdr      = Util::BOXDRAWINGS
            empty    = ''.force_encoding(Encoding::UTF_8)            
            spc      = ' '.force_encoding(Encoding::UTF_8)
            
            Util.monkey_patch(:cjust => String) do               
                # TIMING & TYPESETTING
                keys = @tti.first.field_names
                keys.delete(:tf)
                keys.sort!{ |a,b| a.to_s <=> b.to_s }
                length = keys.length - 1
                sep = (len - 5*keys.length-2-length)/(keys.length)
                len = sep*keys.length + 5*keys.length + 2 + length
                adj = {:tco => 2, :tci => 2, :vp => -2, :cf => -2, :jc => -2, :cs=>-2, :sn=>2,:sgn=>1, :ebn=> 1}

                #/====================================\#
                of << bdr[:dedges][:tl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:tr]                #
                of << endl                             #
                #                                      #
                #.........Timing & Typesetting.........#
                of << bdr[:dbar][:ver]                 #
                of << '  Timing & Typesetting  '.cjust(len-2,bdr[:lbar][:hor])
                of << bdr[:dbar][:ver]                 #
                of << endl                             #
                #                                      #
                of << bdr[:dedges][:bl]                #
                of << ''.cjust(len-2,bdr[:dbar][:hor]) #
                of << bdr[:dedges][:br]                #
                of << endl                             #
                #\====================================/#
                
                of << endl
                
                #/----+-----+-----+----+----+---\
                of << bdr[:edge][:tl]
                of << bdr[:bar][:hor]*(sep+5+adj[keys.first]*2)
                of << bdr[:comb][:hord]
                1.upto(length-1) do |idx|
                    key = keys[idx]
                    of << bdr[:bar][:hor]*(sep+5+adj[key]*2) << bdr[:comb][:hord]
                end
                of << bdr[:bar][:hor]*(sep+5+adj[keys.last]*2)
                of << bdr[:edge][:tr]
                ##################################
                
                of << endl
                
                #----key-----key----key----key---key---#
                of << bdr[:bar][:ver]
                keys.each_with_index do |key,idx|
                    of << spc * (sep/2+adj[key])
                    of << key.to_s.cjust(5)
                    of << spc * (sep-sep/2+adj[key])
                    of << bdr[:bar][:ver]
                end
                ##################################
                
                of << endl
                
                #|----+-----+-----+----+----+---|
                of << bdr[:comb][:verr]
                of << bdr[:bar][:hor]*(sep+5+adj[keys.first]*2)
                of << bdr[:comb][:cross]
                1.upto(length-1) do |idx|
                    key = keys[idx]
                    of << bdr[:bar][:hor]*(sep+5+adj[key]*2) << bdr[:comb][:cross]
                end
                of << bdr[:bar][:hor]*(sep+5+adj[keys.last]*2)
                of << bdr[:comb][:verl]
                ##################################
                
                of << endl
                
                #|-----data-----time-----pos----|
                @tti.each_with_index do |block, idx|
                    of << bdr[:bar][:ver]
                    keys.each_with_index do |key,idx|
                        if key == :tci || key == :tco
                            red = -3
                            time = block[key]
                            data = Array.new(3) do |i|
                                time.getbyte(i).to_s.rjust(2,'0')
                            end.join(':')
                            data << '.' << (((time.getbyte(3).to_f*@fps)*100)).round.
                                             to_s.slice(0,2).rjust(2,'0')
                        else
                            red = 0
                            data = block[key].to_s
                        end
                        of << spc * (sep/2+adj[key]+red)
                        of << data.cjust(5)
                        of << spc * (sep-sep/2+adj[key]+red)
                        of << bdr[:bar][:ver]
                    end
                    of << endl
                end
                ##################################
                
                ##################################
                of << bdr[:edge][:bl]
                of << bdr[:bar][:hor]*(sep+5+adj[keys.first]+adj[keys.first])
                of << bdr[:comb][:horu]
                1.upto(length-1) do |idx|
                    key = keys[idx]
                    of << bdr[:bar][:hor]*(sep+5+adj[key]+adj[key]) << bdr[:comb][:horu]
                end
                of << bdr[:bar][:hor]*(sep+5+adj[keys.last]+adj[keys.last])
                of << bdr[:edge][:br]
                #\----+-----+-----+----+----+---/
                
                of << endl
            end
        end
        
        def to_s
            "#{@gsi.dfc}, full: #{full?}, #{@rows} lines, upto #{@cols} chars, #{@sn} subtitles"
        end
        
        # do not use it
        def debug_access(inst_var)
            var = '@' + inst_var.to_s
            instance_variable_get(var) if instance_variable_defined?(var)
        end
        
        private
        
        # other header options can be set later
        def initialize(rows=16, cols=32,
                       version=HeaderDefault::DFC,
                       codepage_header=HeaderDefault::CPN,
                       codepage_body=HeaderDefault::CCT,
                       &block)
            
            # True when all subtitle groups and numbers are used up, or when the
            # the tti block count limit is reached.
            # While the block count (tnb) allows for upto 100,000 blocks,
            # the format specifications restrict them to 12,242.
            @full = false           

            # I may add support for multiple (upto 9) disks (1.44MB each) later.
            if rows.class == EbuStl
                # overloading, initialize from existing record
                @disks  = [rows]
                version = rows.gsi.dfc
                codepage_header, codepage_body = rows.gsi.cpn, rows.gsi.cct
                rows, cols = rows.gsi.mnr.to_i, rows.gsi.mnc.to_i
            else
                @disks = [EbuStl.new]
            end
            @stl   = @disks.last
            @gsi   = @stl.gsi
            @tti   = @stl.tti
            
            # subtitles are numbered incrementally
            set_increments
            
            # apply options
            set_char_matrix      rows, cols
            set_version          version
            set_codepage_header  codepage_header
            set_codepage_body    codepage_body

            freeze_header!
            finalize!
            
            instance_eval(&block) if block_given?
        end

        # maximum number of characters in any dimension
        def set_char_matrix(rows,cols)
            # maximum number of displayable characters in any row
            cols = 0  if cols < 0
            cols = 99 if cols > 99
            @cols = cols
            @gsi.mnc = @cols.to_s.rjust(2,' ')

            # maximum number of displayable rows
            rows = 0  if rows < 0
            rows = 99 if rows > 99
            @rows = rows
            @gsi.mnr = @rows.to_s.rjust(2,' ')
        end
        
        # dfc, disk format code
        def set_version(version)
            begin
                version = HeaderNames::DFC[version] || version
                case version.downcase.to_sym
                when HeaderNames::DFC[HeaderOption::DFC::STL_30]
                    @fps = 29.97
                    @gsi.dfc = HeaderOption::DFC::STL_30
                when HeaderNames::DFC[HeaderOption::DFC::STL_25]
                    @fps = 25.0
                    @gsi.dfc = HeaderOption::DFC::STL_25
                else
                    version = HeaderDefault::DFC
                    raise ArgumentError
                end
            rescue ArgumentError
                retry
            end
        end

        # cpn, code page number        
        def set_codepage_header(codepage_header)
            begin
                codepage_header = HeaderNames::CPN[codepage_header] || codepage_header
                case codepage_header.downcase.to_sym
                when HeaderNames::CPN[HeaderOption::CPN::UNITED_STATES]
                    @gsi.cpn = HeaderOption::CPN::UNITED_STATES
                    @codepage_header = CodePage::Header::UnitedStates
                when HeaderNames::CPN[HeaderOption::CPN::MULTILINGUAL]
                    @gsi.cpn = HeaderOption::CPN::MULTILINGUAL
                    @codepage_header = CodePage::Header::Multilingual
                when HeaderNames::CPN[HeaderOption::CPN::PORTUGAL]
                    @gsi.cpn = HeaderOption::CPN::PORTUGAL
                    @codepage_header = CodePage::Header::Portugal
                when HeaderNames::CPN[HeaderOption::CPN::CANADA_FRENCH]
                    @gsi.cpn = HeaderOption::CPN::CANADA_FRENCH
                    @codepage_header = CodePage::Header::CanadaFrench
                when HeaderNames::CPN[HeaderOption::CPN::NORWAY]
                    @gsi.cpn = HeaderOption::CPN::NORWAY
                    @codepage_header = CodePage::Header::Norway
                else
                    codepage_header = HeaderDefault::CPN
                    raise ArgumentError
                end
            rescue ArgumentError
                retry
            end
        end

        # cct, character code table        
        def set_codepage_body(codepage_body)          
            begin
                codepage_body = HeaderNames::CCT[codepage_body] || codepage_body
                case codepage_body.downcase.to_sym
                when HeaderNames::CCT[HeaderOption::CCT::LATIN]
                    @gsi.cct = HeaderOption::CCT::LATIN
                    @codepage_body = CodePage::Body::Latin
                when HeaderNames::CCT[HeaderOption::CCT::CYRILIC]
                    @gsi.cct = HeaderOption::CCT::CYRILIC
                    @codepage_body = CodePage::Body::Cyrilic
                when HeaderNames::CCT[HeaderOption::CCT::ARABIC]
                    @gsi.cct = HeaderOption::CCT::ARABIC
                    @codepage_body = CodePage::Body::Arabic
                when HeaderNames::CCT[HeaderOption::CCT::GREEK]
                    @gsi.cct = HeaderOption::CCT::GREEK
                    @codepage_body = CodePage::Body::Greek
                when HeaderNames::CCT[HeaderOption::CCT::HEBREW]
                    @gsi.cct = HeaderOption::CCT::HEBREW
                    @codepage_body = CodePage::Body::Hebrew
                else
                    codepage_body = HeaderDefault::CCT
                    raise ArgumentError
                end
            rescue
                retry
            end
        end
        
        # support for reading files
        def set_increments
            if @tti.length == 0
                @sgn = 0   # subtitle group number
                @sn  = 0   # subtitle number
            else
                @sgn = @tti.last.sgn
                @sn  = @tti.last.sn
                increment_subtitle
            end
        end
        
        # check input subtitles for validity
        def sanitize_lines(lines)

            # coerce type
            if lines.class == String                        
                lines = lines.valid_utf8.split('\n')          #  strings can
            elsif lines.respond_to?(:to_a)                    #  be split
                lines = lines.to_a.flatten
                if lines.any?{|line|!line.respond_to?(:to_s)} # array entries
                    return false                              # convertible?
                end
            else
                return false
            end

            # convert lines to valid strings
            lines = lines.map! do |line| 
                line = line.to_s.valid_utf8
                Util::Color.human_colors(line).split("\n")               
            end.flatten             
            
            # no subtitles exists
            return if lines.empty?
            return if lines.reduce(true){|x,l| x && l.strip.empty?}
            
            # everything checked out
            return lines
        end
        
        # increase subtitle and group number
        def increment_subtitle
            @sn += 0x01
            if @sn > BodyOption::SN::MAX
                @sn = 0x00
                @sgn += 0x01
                if @sgn > BodyOption::SGN::MAX
                    @sgn = BodyOption::SGN::MAX
                    @full = true
                    @full.freeze
                end
            end
        end

        # get_option(:Body,:CS,:single) 
        #   => returns BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET
        def get_option(part, field, english)
            namespace = Module.nesting[1]
            part = part.to_s
            namespace.const_get("#{part}Names").const_get(field).each_pair do |option, name|
               return option if english.to_s.downcase == name.to_s.downcase
            end
            return namespace.const_get("#{part}Default").const_get(field)
        end
        
        # enforces row limit, and caps text
        def to_internal_row(row, lines)
            # row = (1..23)
            max_row = @gsi.mnr.to_i
            row = row.to_i
            row = 1  if row < 1
            row = 23 if row > 23
            row = max_row if row > max_row
            # drop lines
            lines_to_drop = lines.length-max_row+row-1
            lines.pop(lines_to_drop) if lines_to_drop > 0
            return row
        end
        
        # converts interval, eg 12h, 40m, 33s and 4 frames => "\x12\x40\x33\x04"
        def to_timecode(t1,t2)
            # enforce type
            t1 = t1.to_f
            t2 = t2.to_f
            
            # enforce bounds
            t1 = 0.0 if t1 < 0.0
            t2 = 0.0 if t2 < 0.0
            t1 = 86399.0 if t1 > 86399.0
            t2 = 86399.0 if t2 > 86399.0
            
            # start <= end
            t1,t2 = t2,t1 if t2 < t1
            
            return Util.timecode(t1,@fps), Util.timecode(t2,@fps)
        end

        # converts string representations of numbers to some canonical form
        def normalize_header!
            @gsi.dsc = HeaderOption::DSC::TELETEXT_LEVEL_2
            @gsi.lc  = @gsi.lc.to_i.to_s.rjust(2,'0')
            @gsi.tnb = @gsi.tnb.to_i.to_s.rjust(5,'0')
            @gsi.tns = @gsi.tns.to_i.to_s.rjust(5,'0')
            @gsi.tng = @gsi.tng.to_i.to_s.rjust(3,'0')
            @gsi.tcp = @gsi.tcp[0..1].to_i.to_s.ljust(2,'0') + 
                       @gsi.tcp[2..3].to_i.to_s.ljust(2,'0') +
                       @gsi.tcp[4..5].to_i.to_s.ljust(2,'0') +
                       @gsi.tcp[6..7].to_i.to_s.ljust(2,'0')
            @gsi.tcf = @gsi.tcf[0..1].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[2..3].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[4..5].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[6..7].to_i.to_s.ljust(2,'0')
            @gsi.co  = @gsi.co.upcase
        end
        
        # set and check data that depends on other fields
        def finalize!          
            # counts
            @gsi.tnb = @tti.length.to_s.rjust(5,'0')
            @gsi.tns = (@sgn*0x10000 + @sn).to_s.rjust(5,'0')
            @gsi.tng = (@sgn+1).to_s.rjust(3,'0')
            
            # initial subtitle
            if @tti.length > 0
              time = @tti.first.tci
              @gsi.tcf = "%02d%02d%02d%02d" % [time.getbyte(0),time.getbyte(1),time.getbyte(2),time.getbyte(3)]
            end
        end
        
        # freeze global header attributes
        def freeze_header!
            @fps.freeze
            @codepage_header.freeze
            @codepage_body.freeze
            @rows.freeze
            @cols.freeze
            
            @gsi.dfc.freeze
            @gsi.cpn.freeze
            @gsi.cct.freeze
            @gsi.mnc.freeze
            @gsi.mnr.freeze
        end

        # adds appropriate terminal colors to emulate stl formatting
        def each_block_with_index_styled(tti, colors)
            endl = CodePage::ControlCode::NEWLINE
            fill = CodePage::ControlCode::FILLER
            defn = CodePage::ControlCode::DEFINED
            stdf = CodePage::ControlCode::DEFAULT_FORMAT
            ulin = CodePage::ControlCode::InVision::UNDERLINE
            ital = CodePage::ControlCode::InVision::ITALICS
            bold = CodePage::ControlCode::TeleText::BOLD
            colr = CodePage::ControlCode::TeleText::COLORS[:text]
            nwbg = CodePage::ControlCode::TeleText::BACKGROUND[:new]
            b2cd = TerminalCode::BYTE_TO_CODE
            tcbd = TerminalCode::BOLD
            tcit = TerminalCode::ITALICS
            tcul = TerminalCode::UNDERLINE
            tccl = TerminalCode::FOREGROUND
            tcbg = TerminalCode::BACKGROUND
            prfx = TerminalCode::PREFIX
            sufx = TerminalCode::SUFFIX
            rset = TerminalCode::RESET
            eblb = BodyOption::EBN::LAST_BLOCK
            cdpg = @codepage_body::HASH_BYTE_TO_UTF8
            endl_glyph = CodePage::SpecialGlyphs::NEWLINE  
            unkn_glyph = CodePage::SpecialGlyphs::UNKNOWN 
            unsp_glyph = CodePage::SpecialGlyphs::UNSUPPORTED_CODE
            fill_glyph = CodePage::SpecialGlyphs::UNUSED_DATA 
            epty_glyph = ''.force_encoding(Encoding::UTF_8)
            
            # default style for new subtitles
            styl = stdf.clone

            # final replacement table
            fsub = []                   #replacement
            prbl = Array.new(0x100){1}  #length (control characters 0)
            0x100.times do |int|
                char = [int].pack('C')
                if defn[char]
                    if code = b2cd[char] && colors
                        fsub[int] = prfx + b2cd[char] + sufx
                        prbl[int] = 0
                    elsif char == nwbg
                        prbl[int] = 0
                    else
                        fsub[int] = unsp_glyph
                    end
                elsif char == endl
                    # bold and background resets upon line break
                    fsub[int] = prfx + tcbd[false] + sufx + prfx + tcbg[:black] + sufx + endl_glyph
                elsif char== fill
                    # filler (unused data) should not be styled
                    fsub[int] = prfx + rset + sufx + fill_glyph
                elsif utf8 = cdpg[char]
                    fsub[int] = utf8
                else
                    fsub[int] = unkn_glyph
                end
            end

            # Keep track of style changes.
            # For all styling attributes, saves the most recent time it changed.
            # Eg, when stch[_bold_on] > stch[_bold_off], => text currently bold.
            stch = Array.new(0x100){0}
            stch[bold[stdf[:b]].getbyte(0)]     = 1
            stch[ital[stdf[:i]].getbyte(0)]     = 2
            stch[ulin[stdf[:u]].getbyte(0)]     = 3
            stch[colr[stdf[:color]].getbyte(0)] = 4
            stid                                = 5

            # background color support impossible with a static substitution
            # may be slow when there are many background color changes
            dnmc = { nwbg.getbyte(0) =>  lambda do |curr|
                         curr[:bgcolor] = curr[:color]
                         curr_bg_color = colr.max{|a,b| stch[a[1].getbyte(0)] <=> stch[b[1].getbyte(0)]}[0]
                         prfx + tcbg[curr_bg_color] + sufx
                     end
                   }
            dnmc.default = lambda{|x|}
            
            tti.each_with_index do |block, idx|
                # count printed characters (excluding control codes)
                nprt = 0

                # formated line
                fmt = epty_glyph.clone

                # apply current style
                if colors
                    fmt << prfx << tcbd[styl[:b]] << sufx
                    fmt << prfx << tcit[styl[:i]] << sufx
                    fmt << prfx << tcul[styl[:u]] << sufx
                    fmt << prfx << tccl[styl[:color]] << sufx
                    fmt << prfx << tcbg[styl[:bgcolor]] << sufx
                end
                
                # convert each character to utf8 / terminal code
                fmt << block.tf.each_byte.map do |char|
                        nprt += prbl[char]
                        stch[char] = (stid+=1)
                        dnmc[char].call(styl) || fsub[char]
                end.join
                
                # apply most recent style change
                styl[:u] = stch[ulin[true].getbyte(0)] > stch[ulin[false].getbyte(0)]
                styl[:i] = stch[ital[true].getbyte(0)] > stch[ital[false].getbyte(0)]
                styl[:b] = stch[bold[true].getbyte(0)] > stch[bold[false].getbyte(0)]
                styl[:color] = colr.max do |x,y| 
                    stch[x[1].getbyte(0)] <=> stch[y[1].getbyte(0)]
                end[0]

                # only the subtitle text should be styled
                fmt << prfx << rset << sufx
            
                yield block, idx, fmt, nprt
                
                # reset styling when subtitle ends
                styl = stdf.clone if block.ebn == eblb
            end
        end
    end
    
end # module EbuStl



################################################################################
###############################TESTING/DEBUG####################################
################################################################################

# For testing, run
#  Write a simple file
#    ruby 'this_script.rb' > /tmp/test.stl
#  Read a file and pretty print in utf-8
#    ruby 'this_script.rb' < /tmp/test.stl

# Testing: Read data from stdin. Write to stdout
avail = IO.select([$stdin],[$stdout],[$stderr],0)
if caller.empty? &&  !avail[0].empty? && !avail[1].empty?
    # This would run some checks on the header.
    #   stl   = EbuStl::StlTools.read($stdin)
    # Which fails because some programs just ignore the header.
    # Use the below to skip the header and use the default one.
    stl   = EbuStl::StlTools.read($stdin,EbuStl::StlTools::BEHEADED)
    stl.pprint($stdout)
    
    
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

        # generates 200 random bytes and sets a random encoding
        bad_data= Array.new(200){[rand(0x100)].pack('C')}.each_slice(30).
                  map{|x|x.join}.join("\n").force_encoding(Encoding.list.sample)
        
        subtitle 45,50, 'It tries to convert non-utf8.'.encode(Encoding::UTF_16)
                  
        # Invalid encodings won't make it crash.
        subtitle 50, 55, bad_data
      
        output   $stdout
        #output   '/path/to/file.stl'
    end
end