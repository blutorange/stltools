# encoding: ascii-8bit

# Improves pretty printing terminal output.

module EbuStl
    module BoxDrawings
        BOXDRAWINGS = { :bar  => {:hor => "\xe2\x94\x81", :ver => "\xe2\x94\x83"}, #bold
                        :dbar => {:hor => "\xe2\x95\x90", :ver => "\xe2\x95\x91"}, #double
                        :lbar => {:hor => "\xe2\x94\x88", :ver => "\xe2\x94\x8a"}, #light
                        :tbar => {:hor => "\xe2\x94\x84", :ver => "\xe2\x94\x86"}, #triple
                        :qbar => {:hor => "\xe2\x94\x88", :ver => "\xe2\x94\x8a"}, #triple
                        :nbar => {:hor => "\xe2\x94\x80", :ver => "\xe2\x94\x82"}, #normal
                        # bold edges
                        :edge => {:tr => "\xe2\x94\x93",
                                  :tl => "\xe2\x94\x8f",
                                  :bl => "\xe2\x94\x97",
                                  :br => "\xe2\x94\x9b"
                                 },
                        # double edges
                        :dedges => { :tr => "\xe2\x95\x97",
                                     :tl => "\xe2\x95\x94",
                                     :bl => "\xe2\x95\x9a",
                                     :br => "\xe2\x95\x9d"
                                    },
                        # combined forms
                        :comb => { :vernr => "\xe2\x94\xa0", :vernl => "\xe2\x94\xa8", # |-  -|
                                   :verr  => "\xe2\x94\xa3", :verl  => "\xe2\x94\xab",
                                   :cross => "\xe2\x95\x8b",
                                   :horu  => "\xe2\x94\xbb", :hord  => "\xe2\x94\xb3"
                                 }
                      }
        
        BOXDRAWINGS.each_value{ |v| v.each_value { |w| w.force_encoding(Encoding::UTF_8)}}
    end
end
