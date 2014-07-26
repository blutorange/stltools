# encoding: ascii-8bit

# Restrictions on the header value of the EBU-STL header.

module EbuStl
    module HeaderAssert
        VALID_CODEPAGE = [ "\x34\x33\x37", "\x38\x35\x30", "\x38\x36\x30",
                           "\x38\x36\x33", "\x38\x36\x35"
                         ]
        CPN = lambda { VALID_CODEPAGE.include?(value) }
        DFC = lambda { value == 'STL25.01' || value == 'STL30.01' }
        DSC = lambda { value == "\x20" || value >= "\x30" && value <= "\x32" }
        CCT = lambda { value[0] == "\x30" && value[1] >= "\x30" && value[1] <= "\x34" }
        TCS = lambda { value == "\x30" || value == "\x31" }
        TND = lambda { value >= '1' && value <= '9' }
        DSN = lambda { value >= "\x31" && value <= "\x39" }
        CO  = lambda { !HeaderNames::CO[value.upcase].nil? }
        LC  = lambda { !HeaderNames::LC[value.to_i.to_s.rjust(2,'0')].nil? }
        MNC = lambda { x=value.chomp.strip.rjust(2,'0') ; x >= "\x30\x30" && x <= "\x39\x39" }
        MNR = lambda { x=value.chomp.strip.rjust(2,'0') ; x >= "\x30\x30" && x <= "\x39\x39" }
        TNB = lambda { x=value.chomp.strip.rjust(5,'0') ; x >= "\x30\x30\x30\x30\x30" && x <= "\x31\x31\x32\x34\x32" }
        TNS = lambda { x=value.chomp.strip.rjust(5,'0') ; x >= "\x30\x30\x30\x30\x30" && x <= "\x39\x39\x39\x39\x39" }
        TNG = lambda { x=value.chomp.strip.rjust(3,'0') ; x >= "\x30\x30\x30" && x <= "\x39\x39\x39" }
        TCP = lambda { (0..99).include?(value[0..1].chomp.strip.to_i) && (0..59).include?(value[2..3].chomp.strip.to_i) && (0..59).include?(value[4..5].chomp.strip.to_i) && (0..29).include?(value[6..7].chomp.strip.to_i) }
        TCF = TCP
    end
end
