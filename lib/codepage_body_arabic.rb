# encoding: ascii-8bit

# Mappings between UTF-8 and ISO 8859/6-1987.

module EbuStl
    module CodePage
        module Body
            module Arabic
                BYTE_TO_UTF8 = UTF8.clone
                
                BYTE_TO_UTF8[0xa0] = 0x00c2a0
                BYTE_TO_UTF8[0xa4] = 0x00c2a4
                BYTE_TO_UTF8[0xac] = 0x00d88c
                BYTE_TO_UTF8[0xad] = 0x00c2ad
                
                BYTE_TO_UTF8[0xbb] = 0x00d89b
                BYTE_TO_UTF8[0xbf] = 0x00d89f

                BYTE_TO_UTF8[0xc1] = 0x00d8a1
                BYTE_TO_UTF8[0xc2] = 0x00d8a2
                BYTE_TO_UTF8[0xc3] = 0x00d8a3
                BYTE_TO_UTF8[0xc4] = 0x00d8a4
                BYTE_TO_UTF8[0xc5] = 0x00d8a5
                BYTE_TO_UTF8[0xc6] = 0x00d8a6
                BYTE_TO_UTF8[0xc7] = 0x00d8a7
                BYTE_TO_UTF8[0xc8] = 0x00d8a8
                BYTE_TO_UTF8[0xc9] = 0x00d8a9
                BYTE_TO_UTF8[0xca] = 0x00d8aa
                BYTE_TO_UTF8[0xcb] = 0x00d8ab
                BYTE_TO_UTF8[0xcc] = 0x00d8ac
                BYTE_TO_UTF8[0xcd] = 0x00d8ad
                BYTE_TO_UTF8[0xce] = 0x00d8ae
                BYTE_TO_UTF8[0xcf] = 0x00d8af
                
                BYTE_TO_UTF8[0xd0] = 0x00d8b0
                BYTE_TO_UTF8[0xd1] = 0x00d8b1
                BYTE_TO_UTF8[0xd2] = 0x00d8b2
                BYTE_TO_UTF8[0xd3] = 0x00d8b3
                BYTE_TO_UTF8[0xd4] = 0x00d8b4
                BYTE_TO_UTF8[0xd5] = 0x00d8b5
                BYTE_TO_UTF8[0xd6] = 0x00d8b6
                BYTE_TO_UTF8[0xd7] = 0x00d8b7
                BYTE_TO_UTF8[0xd8] = 0x00d8b8
                BYTE_TO_UTF8[0xd9] = 0x00d8b9
                BYTE_TO_UTF8[0xda] = 0x00d8ba
                
                BYTE_TO_UTF8[0xe0] = 0x00d980
                BYTE_TO_UTF8[0xe1] = 0x00d981
                BYTE_TO_UTF8[0xe2] = 0x00d982
                BYTE_TO_UTF8[0xe3] = 0x00d983
                BYTE_TO_UTF8[0xe4] = 0x00d984
                BYTE_TO_UTF8[0xe5] = 0x00d985
                BYTE_TO_UTF8[0xe6] = 0x00d986
                BYTE_TO_UTF8[0xe7] = 0x00d987
                BYTE_TO_UTF8[0xe8] = 0x00d988
                BYTE_TO_UTF8[0xe9] = 0x00d989
                BYTE_TO_UTF8[0xea] = 0x00d98a
                BYTE_TO_UTF8[0xeb] = 0x00d98b
                BYTE_TO_UTF8[0xec] = 0x00d98c
                BYTE_TO_UTF8[0xed] = 0x00d98d
                BYTE_TO_UTF8[0xee] = 0x00d98e
                BYTE_TO_UTF8[0xef] = 0x00d98f
                
                BYTE_TO_UTF8[0xf0] = 0x00d990
                BYTE_TO_UTF8[0xf1] = 0x00d991
                BYTE_TO_UTF8[0xf2] = 0x00d992
                
                CHARSET = BYTE_TO_UTF8.join
            end
        end
    end
end
