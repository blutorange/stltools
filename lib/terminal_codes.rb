# encoding: ascii-8bit

# ANSI escape code

module EbuStl
    module TerminalCode
        RESET  = "\x30"
        PREFIX = "\x1b\x5b"
        SUFFIX = "\x6d"
        
        FOREGROUND = {
            :black   => "\x33\x30",
            :red     => "\x33\x31",
            :green   => "\x33\x32",
            :yellow  => "\x33\x33",
            :blue    => "\x33\x34",
            :magenta => "\x33\x35",
            :cyan    => "\x33\x36",
            :white   => "\x33\x37"
        }
        BACKGROUND = {
            :black   => "\x34\x30",
            :red     => "\x34\x31",
            :green   => "\x34\x32",
            :yellow  => "\x34\x33",
            :blue    => "\x34\x34",
            :magenta => "\x34\x35",
            :cyan    => "\x34\x36",
            :white   => "\x34\x37"
        }
        
        UNDERLINE = { true => "\x34", false => "\x32\x34" }
        BOLD      = { true => "\x31", false => "\x32\x32" }
        ITALICS   = { true => "\x37", false => "\x32\x37" }       
        INVERT    = { true => "\x37", false => "\x32\x37" }
        
        BYTE_TO_CODE = {}
       
        FOREGROUND.each do |name,code|
            BYTE_TO_CODE[CodePage::ControlCode::TeleText::COLORS[:text][name]] = code
        end
        [false,true].each do |bool|
            BYTE_TO_CODE[CodePage::ControlCode::TeleText::BOLD[bool]]      = BOLD[bool]
            BYTE_TO_CODE[CodePage::ControlCode::InVision::ITALICS[bool]]   = ITALICS[bool]
            BYTE_TO_CODE[CodePage::ControlCode::InVision::UNDERLINE[bool]] = UNDERLINE[bool]
        end
       
        NAMES = { UNDERLINE[true] => [:u,true], UNDERLINE[false] => [:u,false],
                  BOLD[true]      => [:b,true], BOLD[false]      => [:b,false],
                  ITALICS[true]   => [:i,true], ITALICS[false]   => [:i,false],
                  FOREGROUND[:white]   => [:color,:white],
                  FOREGROUND[:black]   => [:color,:black],
                  FOREGROUND[:red]     => [:color,:red],
                  FOREGROUND[:green]   => [:color,:green],
                  FOREGROUND[:blue]    => [:color,:blue],
                  FOREGROUND[:yellow]  => [:color,:yellow],
                  FOREGROUND[:cyan]    => [:color,:cyan],
                  FOREGROUND[:magenta] => [:color,:magenta]
                }       
    end
end
