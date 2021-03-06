# encoding: ascii-8bit

module Importer
    
    # Does not enforce incrementing subtitle number.
    def read_srt(fof)
        # read file
        Util.iostream(fof,'r') do |io|
            if io.read(3) != "\xef\xbb\xbf" # srt magick number
                io.seek(0, :SET)
            end
            mode = 0
            time_in = 0
            time_of = 0
            lines   = []
            init    = Time.now
            io.each_line do |line|
                line = line.chomp
                case mode
                when 0 # searching for subtitles
                    if line.to_i > 0
                        mode = 1
                    end
                when 1 # searching for timecode
                    if time = line.match(/(\d+):(\d+):(\d+)[,]{0,1}(\d*)[ ]*-->[ ]*(\d+):(\d+):(\d+)[,]{0,1}(\d*)/)
                        time_in = init +
                                  time[1].to_f*3600 + 
                                  time[2].to_f*60 +
                                  time[3].to_f +
                                  time[4].to_f*10.0**(-time[3].length)
                        time_of = init + 
                                  time[5].to_f * 3600 +
                                  time[6].to_f * 60 +
                                  time[7].to_f +
                                  time[8].to_f * 10.0**(-time[3].length)
                        mode = 2
                        lines.clear
                    end
                when 2 # reading subtitles
                    if line.strip.empty?
                        subs.push({ :time_in => time_in,
                                    :time_of => time_of,
                                    :lines   => lines })
                        mode = 0
                    else
                        lines.push(line.valid_utf8('',true))
                    end
                end
            end
        end
        return subs
    end
end
