# encoding: ascii-8bit

# Mappings between utf-8 and the internal encoding of the EBU-STL format.
# http://tech.ebu.ch/docs/tech/tech3264.pdf

module EbuStl
    module CodePage
        # Unit mapping, the part of UTF-8 that is ASCII.
        UTF8 = Array.new(0x80) { |i| i }
        UTF8.map! { |i| (i<= 0x1f) ? nil : i}
        UTF8.delete_if { |i| i && i >= 0x7f}
    end
end

require_relative 'codepage_header.rb'
require_relative 'codepage_body.rb'
require_relative 'codepage_controlcode.rb'
require_relative 'codepage_special.rb'
require_relative 'encode_body.rb'

# Generate mappings (hashes) for header and body code pages.
module EbuStl
    module CodePage
        [Header, Body].each do |section|
            section.constants.each do |const|
                page = section.const_get(const)
                b_hash = {}
                page.const_get(:BYTE_TO_UTF8).each_with_index do |i,j|
                    next if i.nil?
                    b_hash[Util.int_to_bytes(j)] = 
                        Util.int_to_bytes(i).force_encoding(Encoding::UTF_8)
                end
                page.const_set(:HASH_BYTE_TO_UTF8, b_hash)
                page.const_set(:HASH_UTF8_TO_BYTE, b_hash.invert)
            end
        end
    end
end
