# encoding: ascii-8bit

# Binary description of the body TTI.
# Text and Timing Information block

require 'bindata'
require_relative 'body_option.rb'
require_relative 'body_default.rb'
require_relative 'body_assert.rb'
require_relative 'body_names.rb'

module EbuStl
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
end
