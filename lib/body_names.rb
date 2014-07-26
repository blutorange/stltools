# encoding: ascii-8bit

# Shortcut names for the EBU-STL header values.

module EbuStl
    module BodyNames
        CS = { BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET          => :single,
               BodyOption::CS::FIRST_PART_OF_CUMULATIVE_SET        => :first,
               BodyOption::CS::INTERMEDIATE_PART_OF_CUMULATIVE_SET => :middle,
               BodyOption::CS::LAST_PART_OF_CUMULATIVE_SET         => :last }
        
        JC = { BodyOption::JC::UNCHANGED       => :default,
               BodyOption::JC::LEFT_JUSTIFIED  => :left,
               BodyOption::JC::CENTERED        => :centered,
               BodyOption::JC::RIGHT_JUSTIFIED => :right }
        
        CF = { BodyOption::CF::SUBTITLE_DATA        => :subtitle,
              BodyOption::CF::NOT_FOR_TRANSMISSION  => :comment } 
    end
end
