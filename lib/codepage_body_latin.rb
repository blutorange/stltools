# encoding: ascii-8bit

# Mappings between UTF-8 and ISO 6937/2-1983, Addendum 1-1989.

module EbuStl
    module CodePage
        module Body
            module Latin
                BYTE_TO_UTF8 = UTF8.clone

                BYTE_TO_UTF8[0x24] = 0xc2a4

                BYTE_TO_UTF8[0xa0] = 0xc2a0
                BYTE_TO_UTF8[0xa1] = 0xc2a1
                BYTE_TO_UTF8[0xa2] = 0xc2a2
                BYTE_TO_UTF8[0xa3] = 0xc2a3
                BYTE_TO_UTF8[0xa4] = 0x0024             
                BYTE_TO_UTF8[0xa5] = 0xc2b5
                BYTE_TO_UTF8[0xa6] = nil
                BYTE_TO_UTF8[0xa7] = 0xc2a7
                BYTE_TO_UTF8[0xa8] = nil
                BYTE_TO_UTF8[0xa9] = 0xe2809b
                BYTE_TO_UTF8[0xaa] = 0xe2809f
                BYTE_TO_UTF8[0xab] = 0xc2ab
                BYTE_TO_UTF8[0xac] = 0xe28690
                BYTE_TO_UTF8[0xad] = 0xe28691
                BYTE_TO_UTF8[0xae] = 0xe28692
                BYTE_TO_UTF8[0xaf] = 0xe28693
                
                BYTE_TO_UTF8[0xb0] = 0xc2b0
                BYTE_TO_UTF8[0xb1] = 0xc2b1
                BYTE_TO_UTF8[0xb2] = 0xc2b2
                BYTE_TO_UTF8[0xb3] = 0xc2b3
                BYTE_TO_UTF8[0xb4] = 0xc397
                BYTE_TO_UTF8[0xb5] = 0xc2b5
                BYTE_TO_UTF8[0xb6] = 0xc2b6
                BYTE_TO_UTF8[0xb7] = 0xc2b7
                BYTE_TO_UTF8[0xb8] = 0xc3b7
                BYTE_TO_UTF8[0xb9] = 0xe28099
                BYTE_TO_UTF8[0xba] = 0xe2809d
                BYTE_TO_UTF8[0xbb] = 0xc2bb
                BYTE_TO_UTF8[0xbc] = 0xc2bc
                BYTE_TO_UTF8[0xbd] = 0xc2bd
                BYTE_TO_UTF8[0xbe] = 0xc2be
                BYTE_TO_UTF8[0xbf] = 0xc2bf
                
                BYTE_TO_UTF8[0xc0] = nil
                BYTE_TO_UTF8[0xc1] = 0x60
                BYTE_TO_UTF8[0xc2] = 0xc2b4
                BYTE_TO_UTF8[0xc3] = 0x5e
                BYTE_TO_UTF8[0xc4] = 0xcb9c
                BYTE_TO_UTF8[0xc5] = 0xcb89
                BYTE_TO_UTF8[0xc6] = 0xcb98
                BYTE_TO_UTF8[0xc7] = 0xcb99
                BYTE_TO_UTF8[0xc8] = 0xc2a8
                BYTE_TO_UTF8[0xc9] = nil
                BYTE_TO_UTF8[0xca] = 0xcb9a
                BYTE_TO_UTF8[0xcb] = 0xcca2
                BYTE_TO_UTF8[0xcc] = 0xcb8d
                BYTE_TO_UTF8[0xcd] = 0xcb9d
                BYTE_TO_UTF8[0xce] = 0xcb9b
                BYTE_TO_UTF8[0xcf] = 0xcb87
                
                BYTE_TO_UTF8[0xd0] = 0xe28095
                BYTE_TO_UTF8[0xd1] = 0xc2b9
                BYTE_TO_UTF8[0xd2] = 0xc2ae
                BYTE_TO_UTF8[0xd3] = 0xc2a9
                BYTE_TO_UTF8[0xd4] = 0xe284a2
                BYTE_TO_UTF8[0xd5] = 0xe299aa
                BYTE_TO_UTF8[0xd6] = 0xc2ac
                BYTE_TO_UTF8[0xd7] = 0xc2a6
                BYTE_TO_UTF8[0xd8] = nil
                BYTE_TO_UTF8[0xd9] = nil
                BYTE_TO_UTF8[0xda] = nil
                BYTE_TO_UTF8[0xdb] = nil
                BYTE_TO_UTF8[0xdc] = 0xe2859b
                BYTE_TO_UTF8[0xdd] = 0xe2859c
                BYTE_TO_UTF8[0xde] = 0xe2859d
                BYTE_TO_UTF8[0xdf] = 0xe2859e
                
                BYTE_TO_UTF8[0xe0] = 0xcea9
                BYTE_TO_UTF8[0xe1] = 0xc386
                BYTE_TO_UTF8[0xe2] = 0xc490
                BYTE_TO_UTF8[0xe3] = 0xc2aa
                BYTE_TO_UTF8[0xe4] = 0xc4a6
                BYTE_TO_UTF8[0xe5] = nil
                BYTE_TO_UTF8[0xe6] = 0xc4b2
                BYTE_TO_UTF8[0xe7] = 0xc4bf
                BYTE_TO_UTF8[0xe8] = 0xc581
                BYTE_TO_UTF8[0xe9] = 0xc398
                BYTE_TO_UTF8[0xea] = 0xc592
                BYTE_TO_UTF8[0xeb] = 0xc2ba
                BYTE_TO_UTF8[0xec] = 0xc39e
                BYTE_TO_UTF8[0xed] = 0xc5a6
                BYTE_TO_UTF8[0xee] = 0xc58a
                BYTE_TO_UTF8[0xef] = 0xc589

                BYTE_TO_UTF8[0xf0] = 0xc4b8
                BYTE_TO_UTF8[0xf1] = 0xc3a6
                BYTE_TO_UTF8[0xf2] = 0xc491
                BYTE_TO_UTF8[0xf3] = 0xc3b0
                BYTE_TO_UTF8[0xf4] = 0xc4a7
                BYTE_TO_UTF8[0xf5] = 0xc4b1
                BYTE_TO_UTF8[0xf6] = 0xc4b3
                BYTE_TO_UTF8[0xf7] = 0xc580
                BYTE_TO_UTF8[0xf8] = 0xc582
                BYTE_TO_UTF8[0xf9] = 0xc3b8
                BYTE_TO_UTF8[0xfa] = 0xc593
                BYTE_TO_UTF8[0xfb] = 0xc39f
                BYTE_TO_UTF8[0xfc] = 0xc3be
                BYTE_TO_UTF8[0xfd] = 0xc5a7
                BYTE_TO_UTF8[0xfe] = 0xc58b
                BYTE_TO_UTF8[0xff] = 0xc2ad
                
                CHARSET = BYTE_TO_UTF8.join
                
            end
        end
    end
end
