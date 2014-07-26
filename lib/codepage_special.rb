# encoding: ascii-8bit

module EbuStl
    module CodePage
        module SpecialGlyphs
            NEWLINE          = "\xe2\x80\x96".force_encoding(Encoding::UTF_8)
            UNKNOWN          = "\xef\xbf\xbd".force_encoding(Encoding::UTF_8)
            UNSUPPORTED_CODE = "\xe2\x90\xa3".force_encoding(Encoding::UTF_8)
            UNUSED_DATA      = "\xc2\xb7".force_encoding(Encoding::UTF_8)
        end
    end
end
