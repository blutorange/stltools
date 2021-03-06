# encoding: ascii-8bit

# Mappings between UTF-8 and ISO 8859/7-1987.

module EbuStl
    module CodePage
        module Body
            module Greek
                BYTE_TO_UTF8 = UTF8.clone

                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa1] = 0xe28098
                BYTE_TO_UTF8[0xa2] = 0xe28099
                BYTE_TO_UTF8[0xa3] = 0x00c2a3
                BYTE_TO_UTF8[0xa6] = 0x00c2a6
                BYTE_TO_UTF8[0xa7] = 0x00c2a7
                BYTE_TO_UTF8[0xa8] = 0x00c2a8
                BYTE_TO_UTF8[0xa9] = 0x00c2a9
                BYTE_TO_UTF8[0xab] = 0x00c2ab
                BYTE_TO_UTF8[0xac] = 0x00c2ac
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                BYTE_TO_UTF8[0xaf] = 0xe28095
                
                BYTE_TO_UTF8[0xb0] = 0x00c2b0
                BYTE_TO_UTF8[0xb1] = 0x00c2b1
                BYTE_TO_UTF8[0xb2] = 0x00c2b2
                BYTE_TO_UTF8[0xb3] = 0x00c2b3
                BYTE_TO_UTF8[0xb4] = 0x00ce84
                BYTE_TO_UTF8[0xb5] = 0x00ce85
                BYTE_TO_UTF8[0xb6] = 0x00ce86
                BYTE_TO_UTF8[0xb7] = 0x00c2b7
                BYTE_TO_UTF8[0xb8] = 0x00ce88
                BYTE_TO_UTF8[0xb9] = 0x00ce89
                BYTE_TO_UTF8[0xba] = 0x00ce8a
                BYTE_TO_UTF8[0xbb] = 0x00c2bb
                BYTE_TO_UTF8[0xbc] = 0x00ce8c
                BYTE_TO_UTF8[0xbd] = 0x00c2bd
                BYTE_TO_UTF8[0xbe] = 0x00ce8e
                BYTE_TO_UTF8[0xbf] = 0x00ce8f
                
                BYTE_TO_UTF8[0xc0] = 0x00ce90
                BYTE_TO_UTF8[0xc1] = 0x00ce91
                BYTE_TO_UTF8[0xc2] = 0x00ce92
                BYTE_TO_UTF8[0xc3] = 0x00ce93
                BYTE_TO_UTF8[0xc4] = 0x00ce94
                BYTE_TO_UTF8[0xc5] = 0x00ce95
                BYTE_TO_UTF8[0xc6] = 0x00ce96
                BYTE_TO_UTF8[0xc7] = 0x00ce97
                BYTE_TO_UTF8[0xc8] = 0x00ce98
                BYTE_TO_UTF8[0xc9] = 0x00ce99
                BYTE_TO_UTF8[0xca] = 0x00ce9a
                BYTE_TO_UTF8[0xcb] = 0x00ce9b
                BYTE_TO_UTF8[0xcc] = 0x00ce9c
                BYTE_TO_UTF8[0xcd] = 0x00ce9d
                BYTE_TO_UTF8[0xce] = 0x00ce9e
                BYTE_TO_UTF8[0xcf] = 0x00ce9f
                
                BYTE_TO_UTF8[0xd0] = 0x00cea0
                BYTE_TO_UTF8[0xd1] = 0x00cea1
                BYTE_TO_UTF8[0xd3] = 0x00cea3
                BYTE_TO_UTF8[0xd4] = 0x00cea4
                BYTE_TO_UTF8[0xd5] = 0x00cea5
                BYTE_TO_UTF8[0xd6] = 0x00cea6
                BYTE_TO_UTF8[0xd7] = 0x00cea7
                BYTE_TO_UTF8[0xd8] = 0x00cea8
                BYTE_TO_UTF8[0xd9] = 0x00cea9
                BYTE_TO_UTF8[0xda] = 0x00ceaa
                BYTE_TO_UTF8[0xdb] = 0x00ceab
                BYTE_TO_UTF8[0xdc] = 0x00ceac
                BYTE_TO_UTF8[0xdd] = 0x00cead
                BYTE_TO_UTF8[0xde] = 0x00ceae
                BYTE_TO_UTF8[0xdf] = 0x00ceaf
                
                BYTE_TO_UTF8[0xe0] = 0x00ceb0
                BYTE_TO_UTF8[0xe1] = 0x00ceb1
                BYTE_TO_UTF8[0xe2] = 0x00ceb2
                BYTE_TO_UTF8[0xe3] = 0x00ceb3
                BYTE_TO_UTF8[0xe4] = 0x00ceb4
                BYTE_TO_UTF8[0xe5] = 0x00ceb5
                BYTE_TO_UTF8[0xe6] = 0x00ceb6
                BYTE_TO_UTF8[0xe7] = 0x00ceb7
                BYTE_TO_UTF8[0xe8] = 0x00ceb8
                BYTE_TO_UTF8[0xe9] = 0x00ceb9
                BYTE_TO_UTF8[0xea] = 0x00ceba
                BYTE_TO_UTF8[0xeb] = 0x00cebb
                BYTE_TO_UTF8[0xec] = 0x00cebc
                BYTE_TO_UTF8[0xed] = 0x00cebd
                BYTE_TO_UTF8[0xee] = 0x00cebe
                BYTE_TO_UTF8[0xef] = 0x00cebf
                
                BYTE_TO_UTF8[0xf0] = 0x00cf80
                BYTE_TO_UTF8[0xf1] = 0x00cf81
                BYTE_TO_UTF8[0xf2] = 0x00cf82
                BYTE_TO_UTF8[0xf3] = 0x00cf83
                BYTE_TO_UTF8[0xf4] = 0x00cf84
                BYTE_TO_UTF8[0xf5] = 0x00cf85
                BYTE_TO_UTF8[0xf6] = 0x00cf86
                BYTE_TO_UTF8[0xf7] = 0x00cf87
                BYTE_TO_UTF8[0xf8] = 0x00cf88
                BYTE_TO_UTF8[0xf9] = 0x00cf89
                BYTE_TO_UTF8[0xfa] = 0x00cf8a
                BYTE_TO_UTF8[0xfb] = 0x00cf8b
                BYTE_TO_UTF8[0xfc] = 0x00cf8c
                BYTE_TO_UTF8[0xfd] = 0x00cf8d
                BYTE_TO_UTF8[0xfe] = 0x00cf8e
                
                CHARSET = BYTE_TO_UTF8.join
            end
        end
    end
end
