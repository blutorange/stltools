# encoding: ascii-8bit

# Default values for the EBU-STL header.

module EbuStl
    module BodyDefault
        SGN = 0x00
        SN  = 0x0000
        EBN = 0xFF
        CS  = BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET
        TCI = "\x00\x00\x00\x00"
        TCO = "\x17\x3b\x3b\x18"
        VP  = 0x01
        JC  = BodyOption::JC::UNCHANGED
        CF  = BodyOption::CF::SUBTITLE_DATA
        TF  = CodePage::ControlCode::FILLER * 112
    end
end
