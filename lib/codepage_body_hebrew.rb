# encoding: ascii-8bit

# Mappings between UTF-8 and ISO 8859/8-1988.

module EbuStl
    module CodePage
        module Body
            module Hebrew
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa2] = 0x00c2a2
                BYTE_TO_UTF8[0xa3] = 0x00c2a3
                BYTE_TO_UTF8[0xa4] = 0x00c2a4
                BYTE_TO_UTF8[0xa5] = 0x00c2a5
                BYTE_TO_UTF8[0xa6] = 0x00c2a6
                BYTE_TO_UTF8[0xa7] = 0x00c2a7
                BYTE_TO_UTF8[0xa8] = 0x00c2a8
                BYTE_TO_UTF8[0xa9] = 0x00c2a9
                BYTE_TO_UTF8[0xaa] = 0x00c397
                BYTE_TO_UTF8[0xab] = 0x00c2ab
                BYTE_TO_UTF8[0xac] = 0x00c2ac
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xae] = 0x00c2ae
                BYTE_TO_UTF8[0xaf] = 0x00c2af
                
                BYTE_TO_UTF8[0xb0] = 0x00c2b0
                BYTE_TO_UTF8[0xb1] = 0x00c2b1
                BYTE_TO_UTF8[0xb2] = 0x00c2b2
                BYTE_TO_UTF8[0xb3] = 0x00c2b3
                BYTE_TO_UTF8[0xb4] = 0x00c2b4
                BYTE_TO_UTF8[0xb5] = 0x00c2b5
                BYTE_TO_UTF8[0xb6] = 0x00c2b6
                BYTE_TO_UTF8[0xb7] = 0x00c2b7
                BYTE_TO_UTF8[0xb8] = 0x00c2b8
                BYTE_TO_UTF8[0xb9] = 0x00c2b9
                BYTE_TO_UTF8[0xba] = 0x00c3b7
                BYTE_TO_UTF8[0xbb] = 0x00c2bb
                BYTE_TO_UTF8[0xbc] = 0x00c2bc
                BYTE_TO_UTF8[0xbd] = 0x00c2bd
                BYTE_TO_UTF8[0xbe] = 0x00c2be
                
                BYTE_TO_UTF8[0xdf] = 0xe28097
                
                BYTE_TO_UTF8[0xe0] = 0x00d790
                BYTE_TO_UTF8[0xe1] = 0x00d791
                BYTE_TO_UTF8[0xe2] = 0x00d792
                BYTE_TO_UTF8[0xe3] = 0x00d793
                BYTE_TO_UTF8[0xe4] = 0x00d794
                BYTE_TO_UTF8[0xe5] = 0x00d795
                BYTE_TO_UTF8[0xe6] = 0x00d796
                BYTE_TO_UTF8[0xe7] = 0x00d797
                BYTE_TO_UTF8[0xe8] = 0x00d798
                BYTE_TO_UTF8[0xe9] = 0x00d799
                BYTE_TO_UTF8[0xea] = 0x00d79a
                BYTE_TO_UTF8[0xeb] = 0x00d79b
                BYTE_TO_UTF8[0xec] = 0x00d79c
                BYTE_TO_UTF8[0xed] = 0x00d79d
                BYTE_TO_UTF8[0xee] = 0x00d79e
                BYTE_TO_UTF8[0xef] = 0x00d79f
                
                BYTE_TO_UTF8[0xf0] = 0x00d7a0
                BYTE_TO_UTF8[0xf1] = 0x00d7a1
                BYTE_TO_UTF8[0xf2] = 0x00d7a2
                BYTE_TO_UTF8[0xf3] = 0x00d7a3
                BYTE_TO_UTF8[0xf4] = 0x00d7a4
                BYTE_TO_UTF8[0xf5] = 0x00d7a5
                BYTE_TO_UTF8[0xf6] = 0x00d7a6
                BYTE_TO_UTF8[0xf7] = 0x00d7a7
                BYTE_TO_UTF8[0xf8] = 0x00d7a8
                BYTE_TO_UTF8[0xf9] = 0x00d7a9
                BYTE_TO_UTF8[0xfa] = 0x00d7aa
                
                CHARSET = BYTE_TO_UTF8.join
            end
        end
    end
end
