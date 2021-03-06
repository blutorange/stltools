# encoding: ascii-8bit

# Collection of useful (?) functions.

require_relative 'util_color.rb'
require_relative 'util_monkey.rb'
require_relative 'util_validutf8.rb'

module EbuStl
    module Util
        # Takes file name or io object
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
                rescue Exception => e
                    raise IOError, e.message, e.backtrace
                end
                io.close if needs_closing
            else
                return io, needs_closing
            end
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
        
        # time in seconds.
        # returns hour, minute, seconds, frame
        def self.timecode(time, fps)
            time = ss2hhmmssms(time.to_f)
            time[3] = (time[3].to_f*fps*0.001).floor
            # enforce bounds
            time[3] = fps.ceil-1 if time[3] >= fps
            return time.pack('CCCC')
        end

        #  inverse of Util#timecode
        def self.seconds(tcode, fps)
            tcode.getbyte(0)*3600.0 + tcode.getbyte(1)*60.0 +
            tcode.getbyte(2)        + tcode.getbyte(3)/fps.to_f
        end
    
        # yymmdd
        def self.date(date)
            date.to_datetime.strftime('%y%m%d')
        end
    end
end
