# encoding: ascii-8bit

# Shortcut names for the EBU-STL header values.

module EbuStl
    module HeaderNames
        CCT = { HeaderOption::CCT::LATIN   => :latin,
                HeaderOption::CCT::CYRILIC => :cyrilic,
                HeaderOption::CCT::ARABIC  => :arabic,
                HeaderOption::CCT::GREEK   => :greek,
                HeaderOption::CCT::HEBREW  => :hebrew }
        
        CPN = { HeaderOption::CPN::UNITED_STATES    => :us,
                HeaderOption::CPN::MULTILINGUAL     => :multi,
                HeaderOption::CPN::PORTUGAL         => :portugal,
                HeaderOption::CPN::CANADA_FRENCH    => :canada_french,
                HeaderOption::CPN::NORWAY           => :norway }
        
        DFC = { HeaderOption::DFC::STL_25           => :stl25,
                HeaderOption::DFC::STL_30           => :stl30 }
        
        DSC = { HeaderOption::DSC::BLANK            => :none,
                HeaderOption::DSC::OPEN_SUBTITLING  => :open_sub,
                HeaderOption::DSC::TELETEXT_LEVEL_1 => :teletext_lv1,
                HeaderOption::DSC::TELETEXT_LEVEL_2 => :teletext_lv2 }
        
        TCS = { HeaderOption::TCS::NOT_FOR_USE      => :do_no_use,
                HeaderOption::TCS::FOR_USE          => :use }

        CO  = {}
        LC  = {}
        HeaderOption::CO.constants.each do |co|
            CO[HeaderOption::CO.const_get(co)] = co.to_s.downcase
        end
        HeaderOption::LC.constants.each do |co|
            LC[HeaderOption::LC.const_get(co)] = co.to_s.downcase
        end
    end
end
