# encoding: ascii-8bit

# Pretty prints subtitles of EBU-STL files.

require_relative 'boxdrawings.rb'
require_relative 'prettyprint_style.rb'

module EbuStl
    class StlTools
        public
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
            
            bdr      = BoxDrawings::BOXDRAWINGS
            
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
                    
                    if block.ebn==255
                        horl =  bdr[:bar][:hor]
                        verl = bdr[:comb][:verl]
                        verr = bdr[:comb][:verr]
                    else
                        horl = ' '
                        verl = bdr[:bar][:ver]
                        verr = verl
                    end
                            
                    #-----------00314/00334------------#
                    if idx != idx_max                  #
                        of << verr                     # 
                        of << horl*(bln/2-5)           #
                        of << idx.to_s.rjust(5,'0').   #
                         chars.map{|x|num_sup[x]}.join #
                        of << slash                    #
                        of << block.sn.to_s.rjust(5,'0').
                         chars.map{|x|num_sub[x]}.join #
                        of << parenthesis_s_left       #
                        of << block.sgn.to_s.rjust(3,'0').
                         chars.map{|x|num_sub[x]}.join #
                        of << parenthesis_s_right      #
                        of << horl * (bln-bln/2-6)     #
                        of << verl                     #
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
    end
end
