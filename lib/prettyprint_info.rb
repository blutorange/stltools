# encoding: ascii-8bit

# Pretty prints the header of EBU-STL files.

require_relative 'boxdrawings.rb'

module EbuStl
    class StlTools
        public
        def pprint_info(of = $stdout, len=91)
            return unless of.respond_to?(:<<)
            len  = 91 if len < 91
            endl = "\n"
            bdr  = BoxDrawings::BOXDRAWINGS
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
    end       
end
