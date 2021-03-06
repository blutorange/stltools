# encoding: ascii-8bit

# Restrictions on the header value of the EBU-STL body.

module EbuStl
    module BodyAssert
        CS  = lambda { value <= 0x03 }
        TCI = lambda { value.getbyte(0) <= 23 &&
                       value.getbyte(1) <= 59 &&
                       value.getbyte(2) <= 59 &&
                       value.getbyte(3) <= 29
                     }
        TCO = TCI
        VP  = lambda { value <= 0x63 }
        JC  = lambda { value <= 0x03 }
        CF  = lambda { value <= 0x01 }
        EBN = lambda { !("\xf0".."\xfd").include?(value) }
    end
end
