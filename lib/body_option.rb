# encoding: ascii-8bit

# Possible values for the EBU-STL body.

module EbuStl
    module BodyOption
        module EBN
            LAST_BLOCK = 0xff
            MAX        = 0xef
        end
        module CS
            NOT_PART_OF_CUMULATIVE_SET          = 0
            FIRST_PART_OF_CUMULATIVE_SET        = 1
            INTERMEDIATE_PART_OF_CUMULATIVE_SET = 2
            LAST_PART_OF_CUMULATIVE_SET         = 3
        end
        module JC
            UNCHANGED       = 0
            LEFT_JUSTIFIED  = 1
            CENTERED        = 2
            RIGHT_JUSTIFIED = 3
        end
        module CF
            SUBTITLE_DATA        = 0
            NOT_FOR_TRANSMISSION = 1
        end
        module TF
            FILLER          = CodePage::ControlCode::FILLER
            MAX_DATA_LENGTH = 112
        end
        module SN
            MAX = 0xFFFF
        end
        module SGN
            MAX = 0xFF
        end
    end
end
