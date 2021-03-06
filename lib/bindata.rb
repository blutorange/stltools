# encoding: ascii-8bit

# Binary desciption of the EBU-STL format.
# http://tech.ebu.ch/docs/tech/tech3264.pdf

require 'bindata'
require_relative 'bindata_gsi.rb'
require_relative 'bindata_tti.rb'

# 1024 byte GSI-header, many 128-byte TTI blocks
module EbuStl
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
end
