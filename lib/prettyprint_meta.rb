# encoding: ascii-8bit

# Pretty prints the subtitle meta info of EBU-STL files.

require_relative 'boxdrawings.rb'

module EbuStl
    class StlTools
        public
        def pprint_meta(of=$stdout, len=91)
            return if @tti.length == 0
            return unless of.respond_to?(:<<)
            len  = 91 if len < 91          
            endl     = "\n"
            bdr      = BoxDrawings::BOXDRAWINGS
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
    end
end
