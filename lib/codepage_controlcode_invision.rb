# encoding: ascii-8bit

# Control codes for italics and underlining.

module EbuStl
    module CodePage
        module ControlCode
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
        end
    end         
end
