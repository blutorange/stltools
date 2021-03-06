# encoding: ascii-8bit

# Reads and writes EBU-STL files.
# First argument can be either a writable IO stream, or a file name.
# Raises IOError.

module EbuStl
    class StlTools
        public

        def write(fof)
            finalize! # header data, block count
            Util::iostream(fof, 'wb') do |io|
                @stl.write(io)
            end
        end
        alias_method :output, :write
        
        # Try skipping the header, some programs might not care about the header.
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

        # Provides backtrace information, useful when #read fails.
        def self.backtrace_read(fin)
            BinData::trace_reading do
                return read(fin)
            end
        end
    end
end
