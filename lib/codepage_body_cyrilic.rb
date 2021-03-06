# encoding: ascii-8bit

# Mappings between UTF-8 and ISO 8859/5-1988.

module EbuStl
    module CodePage
        module Body
            module Cyrilic
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa1] = 0x00d081
                BYTE_TO_UTF8[0xa2] = 0x00d082
                BYTE_TO_UTF8[0xa3] = 0x00d083
                BYTE_TO_UTF8[0xa4] = 0x00d084
                BYTE_TO_UTF8[0xa5] = 0x00d085
                BYTE_TO_UTF8[0xa6] = 0x00d086
                BYTE_TO_UTF8[0xa7] = 0x00d087
                BYTE_TO_UTF8[0xa8] = 0x00d088
                BYTE_TO_UTF8[0xa9] = 0x00d089
                BYTE_TO_UTF8[0xaa] = 0x00d08a
                BYTE_TO_UTF8[0xab] = 0x00d08b
                BYTE_TO_UTF8[0xac] = 0x00d08c
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xae] = 0x00d08e
                BYTE_TO_UTF8[0xaf] = 0x00d08f
                
                BYTE_TO_UTF8[0xb0] = 0x00d090
                BYTE_TO_UTF8[0xb1] = 0x00d091
                BYTE_TO_UTF8[0xb2] = 0x00d092
                BYTE_TO_UTF8[0xb3] = 0x00d093
                BYTE_TO_UTF8[0xb4] = 0x00d094
                BYTE_TO_UTF8[0xb5] = 0x00d095
                BYTE_TO_UTF8[0xb6] = 0x00d096
                BYTE_TO_UTF8[0xb7] = 0x00d097
                BYTE_TO_UTF8[0xb8] = 0x00d098
                BYTE_TO_UTF8[0xb9] = 0x00d099
                BYTE_TO_UTF8[0xba] = 0x00d09a
                BYTE_TO_UTF8[0xbb] = 0x00d09b
                BYTE_TO_UTF8[0xbc] = 0x00d09c
                BYTE_TO_UTF8[0xbd] = 0x00d09d
                BYTE_TO_UTF8[0xbe] = 0x00d09e
                BYTE_TO_UTF8[0xbf] = 0x00d09f
                
                BYTE_TO_UTF8[0xc0] = 0x00d0a0
                BYTE_TO_UTF8[0xc1] = 0x00d0a1
                BYTE_TO_UTF8[0xc2] = 0x00d0a2
                BYTE_TO_UTF8[0xc3] = 0x00d0a3
                BYTE_TO_UTF8[0xc4] = 0x00d0a4
                BYTE_TO_UTF8[0xc5] = 0x00d0a5
                BYTE_TO_UTF8[0xc6] = 0x00d0a6
                BYTE_TO_UTF8[0xc7] = 0x00d0a7
                BYTE_TO_UTF8[0xc8] = 0x00d0a8
                BYTE_TO_UTF8[0xc9] = 0x00d0a9
                BYTE_TO_UTF8[0xca] = 0x00d0aa
                BYTE_TO_UTF8[0xcb] = 0x00d0ab
                BYTE_TO_UTF8[0xcc] = 0x00d0ac
                BYTE_TO_UTF8[0xcd] = 0x00d0ad
                BYTE_TO_UTF8[0xce] = 0x00d0ae
                BYTE_TO_UTF8[0xcf] = 0x00d0af
                
                BYTE_TO_UTF8[0xd0] = 0x00d0b0
                BYTE_TO_UTF8[0xd1] = 0x00d0b1
                BYTE_TO_UTF8[0xd2] = 0x00d0b2
                BYTE_TO_UTF8[0xd3] = 0x00d0b3
                BYTE_TO_UTF8[0xd4] = 0x00d0b4
                BYTE_TO_UTF8[0xd5] = 0x00d0b5
                BYTE_TO_UTF8[0xd6] = 0x00d0b6
                BYTE_TO_UTF8[0xd7] = 0x00d0b7
                BYTE_TO_UTF8[0xd8] = 0x00d0b8
                BYTE_TO_UTF8[0xd9] = 0x00d0b9
                BYTE_TO_UTF8[0xda] = 0x00d0ba
                BYTE_TO_UTF8[0xdb] = 0x00d0bb
                BYTE_TO_UTF8[0xdc] = 0x00d0bc
                BYTE_TO_UTF8[0xdd] = 0x00d0bd
                BYTE_TO_UTF8[0xde] = 0x00d0be
                BYTE_TO_UTF8[0xdf] = 0x00d0bf
                
                BYTE_TO_UTF8[0xe0] = 0x00d180
                BYTE_TO_UTF8[0xe1] = 0x00d181
                BYTE_TO_UTF8[0xe2] = 0x00d182
                BYTE_TO_UTF8[0xe3] = 0x00d183
                BYTE_TO_UTF8[0xe4] = 0x00d184
                BYTE_TO_UTF8[0xe5] = 0x00d185
                BYTE_TO_UTF8[0xe6] = 0x00d186
                BYTE_TO_UTF8[0xe7] = 0x00d187
                BYTE_TO_UTF8[0xe8] = 0x00d188
                BYTE_TO_UTF8[0xe9] = 0x00d189
                BYTE_TO_UTF8[0xea] = 0x00d18a
                BYTE_TO_UTF8[0xeb] = 0x00d18b
                BYTE_TO_UTF8[0xec] = 0x00d18c
                BYTE_TO_UTF8[0xed] = 0x00d18d
                BYTE_TO_UTF8[0xee] = 0x00d18e
                BYTE_TO_UTF8[0xef] = 0x00d18f
                
                BYTE_TO_UTF8[0xf0] = 0xe28496
                BYTE_TO_UTF8[0xf1] = 0x00d191
                BYTE_TO_UTF8[0xf2] = 0x00d192
                BYTE_TO_UTF8[0xf3] = 0x00d193
                BYTE_TO_UTF8[0xf4] = 0x00d194
                BYTE_TO_UTF8[0xf5] = 0x00d195
                BYTE_TO_UTF8[0xf6] = 0x00d196
                BYTE_TO_UTF8[0xf7] = 0x00d197
                BYTE_TO_UTF8[0xf8] = 0x00d198
                BYTE_TO_UTF8[0xf9] = 0x00d199
                BYTE_TO_UTF8[0xfa] = 0x00d19a
                BYTE_TO_UTF8[0xfb] = 0x00d19b
                BYTE_TO_UTF8[0xfc] = 0x00d19c
                BYTE_TO_UTF8[0xfd] = 0x00c2a7
                BYTE_TO_UTF8[0xfe] = 0x00d19e
                BYTE_TO_UTF8[0xff] = 0x00d19f
                
                CHARSET = BYTE_TO_UTF8.join
            end
        end
    end
end
