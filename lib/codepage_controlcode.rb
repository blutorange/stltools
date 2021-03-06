# encoding: ascii-8bit

# Byte codes for controlling the layout and format.

module EbuStl
    module CodePage
        module ControlCode
            NEWLINE = "\x8a"
            FILLER  = "\x8f"
            DEFAULT_FORMAT = { :b => false, :u => false,
                               :i => false, :color => :white,
                               :bgcolor => :black }
        end
    end
end

require_relative 'codepage_controlcode_teletext.rb'
require_relative 'codepage_controlcode_invision.rb'

# teletext and invision combined.
module EbuStl::CodePage::ControlCode
    DEFINED = {}
    TeleText::DEFINED.each_pair { |k,v| DEFINED[k] = v }
    InVision::DEFINED.each_pair { |k,v| DEFINED[k] = v }            
end
