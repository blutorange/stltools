# encoding: ascii-8bit

# Default values for the EBU-STL header.

module EbuStl
    module HeaderDefault
        CPN = HeaderOption::CPN::UNITED_STATES
        DFC = HeaderOption::DFC::STL_30
        DSC = HeaderOption::DSC::TELETEXT_LEVEL_2
        CCT = HeaderOption::CCT::LATIN
        LC  = HeaderOption::LC::UNKNOWN
        OPT = 'stl file created by ruby script '
        OET = HeaderOption::FILLER * 32
        TPT = HeaderOption::FILLER * 32
        TET = HeaderOption::FILLER * 32
        TN  = HeaderOption::FILLER * 32
        TCD = HeaderOption::FILLER * 32
        SLR = HeaderOption::FILLER * 16
        CD  = '900522'
        RD  = '900522'
        RN  = '00'
        TNB = '00000'
        TNS = '00000'
        TNG = '000'
        MNC = '32'
        MNR = '16'
        TCS = HeaderOption::TCS::FOR_USE
        TCP = '00000000'
        TCF = '00000000'
        TND = '1'
        DSN = '1'
        CO  = HeaderOption::CO::NEUTRAL_ZONE
        PUB = HeaderOption::FILLER * 32
        EN  = HeaderOption::FILLER * 32
        ECD = HeaderOption::FILLER * 32
        SB  = HeaderOption::FILLER * 75
        UDA = HeaderOption::FILLER * 576
    end
end
