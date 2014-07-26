# encoding: ascii-8bit

# Mappings between UTF-8 and code page 850.

module EbuStl
    module CodePage
        module Header
            module Multilingual
                BYTE_TO_UTF8 = UTF8.clone
                CP_GRAPHICS_B2U.each_with_index{ |i,j| BYTE_TO_UTF8[j]=i }
                
                BYTE_TO_UTF8[0x16] = nil
                BYTE_TO_UTF8[0x80] = 0x00c387
                BYTE_TO_UTF8[0x81] = 0x00c3bc
                BYTE_TO_UTF8[0x82] = 0x00c3a9
                BYTE_TO_UTF8[0x83] = 0x00c3a2
                BYTE_TO_UTF8[0x84] = 0x00c3a4
                BYTE_TO_UTF8[0x85] = 0x00c3a0
                BYTE_TO_UTF8[0x86] = 0x00c3a5
                BYTE_TO_UTF8[0x87] = 0x00c3a7
                BYTE_TO_UTF8[0x88] = 0x00c3aa
                BYTE_TO_UTF8[0x89] = 0x00c3ab
                BYTE_TO_UTF8[0x8a] = 0x00c3a8
                BYTE_TO_UTF8[0x8b] = 0x00c3af
                BYTE_TO_UTF8[0x8c] = 0x00c3ae
                BYTE_TO_UTF8[0x8d] = 0x00c3ac
                BYTE_TO_UTF8[0x8e] = 0x00c384
                BYTE_TO_UTF8[0x8f] = 0x00c385
                BYTE_TO_UTF8[0x90] = 0x00c389
                BYTE_TO_UTF8[0x91] = 0x00c3a6
                BYTE_TO_UTF8[0x92] = 0x00c386
                BYTE_TO_UTF8[0x93] = 0x00c3b4
                BYTE_TO_UTF8[0x94] = 0x00c3b6
                BYTE_TO_UTF8[0x95] = 0x00c3b2
                BYTE_TO_UTF8[0x96] = 0x00c3bb
                BYTE_TO_UTF8[0x97] = 0x00c3b9
                BYTE_TO_UTF8[0x98] = 0x00c3bf
                BYTE_TO_UTF8[0x99] = 0x00c396
                BYTE_TO_UTF8[0x9a] = 0x00c39c
                BYTE_TO_UTF8[0x9b] = 0x00c3b8
                BYTE_TO_UTF8[0x9c] = 0x00c2a3
                BYTE_TO_UTF8[0x9d] = 0x00c398
                BYTE_TO_UTF8[0x9e] = 0x00c397
                BYTE_TO_UTF8[0x9f] = 0x00c692
                BYTE_TO_UTF8[0xa0] = 0x00c3a1
                BYTE_TO_UTF8[0xa1] = 0x00c3ad
                BYTE_TO_UTF8[0xa2] = 0x00c3b3
                BYTE_TO_UTF8[0xa3] = 0x00c3ba
                BYTE_TO_UTF8[0xa4] = 0x00c3b1
                BYTE_TO_UTF8[0xa5] = 0x00c391
                BYTE_TO_UTF8[0xa6] = 0x00c2aa
                BYTE_TO_UTF8[0xa7] = 0x00c2ba
                BYTE_TO_UTF8[0xa8] = 0x00c2bf
                BYTE_TO_UTF8[0xa9] = 0x00c2ae
                BYTE_TO_UTF8[0xaa] = 0x00c2ac
                BYTE_TO_UTF8[0xab] = 0x00c2bd
                BYTE_TO_UTF8[0xac] = 0x00c2bc
                BYTE_TO_UTF8[0xad] = 0x00c2a1
                BYTE_TO_UTF8[0xae] = 0x00c2ab
                BYTE_TO_UTF8[0xaf] = 0x00c2bb
                BYTE_TO_UTF8[0xb0] = 0xe29691
                BYTE_TO_UTF8[0xb1] = 0xe29692
                BYTE_TO_UTF8[0xb2] = 0xe29693
                BYTE_TO_UTF8[0xb3] = 0xe29482
                BYTE_TO_UTF8[0xb4] = 0xe294a4
                BYTE_TO_UTF8[0xb5] = 0x00c381
                BYTE_TO_UTF8[0xb6] = 0x00c382
                BYTE_TO_UTF8[0xb7] = 0x00c380
                BYTE_TO_UTF8[0xb8] = 0x00c2a9
                BYTE_TO_UTF8[0xb9] = 0xe295a3
                BYTE_TO_UTF8[0xba] = 0xe29591
                BYTE_TO_UTF8[0xbb] = 0xe29597
                BYTE_TO_UTF8[0xbc] = 0xe2959d
                BYTE_TO_UTF8[0xbd] = 0x00c2a2
                BYTE_TO_UTF8[0xbe] = 0x00c2a5
                BYTE_TO_UTF8[0xbf] = 0xe29490
                BYTE_TO_UTF8[0xc0] = 0xe29494
                BYTE_TO_UTF8[0xc1] = 0xe294b4
                BYTE_TO_UTF8[0xc2] = 0xe294ac
                BYTE_TO_UTF8[0xc3] = 0xe2949c
                BYTE_TO_UTF8[0xc4] = 0xe29480
                BYTE_TO_UTF8[0xc5] = 0xe294bc
                BYTE_TO_UTF8[0xc6] = 0x00c3a3
                BYTE_TO_UTF8[0xc7] = 0x00c383
                BYTE_TO_UTF8[0xc8] = 0xe2959a
                BYTE_TO_UTF8[0xc9] = 0xe29594
                BYTE_TO_UTF8[0xca] = 0xe295a9
                BYTE_TO_UTF8[0xcb] = 0xe295a6
                BYTE_TO_UTF8[0xcc] = 0xe295a0
                BYTE_TO_UTF8[0xcd] = 0xe29590
                BYTE_TO_UTF8[0xce] = 0xe295ac
                BYTE_TO_UTF8[0xcf] = 0x00c2a4
                BYTE_TO_UTF8[0xd0] = 0x00c3b0
                BYTE_TO_UTF8[0xd1] = 0x00c390
                BYTE_TO_UTF8[0xd2] = 0x00c38a
                BYTE_TO_UTF8[0xd3] = 0x00c38b
                BYTE_TO_UTF8[0xd4] = 0x00c388
                BYTE_TO_UTF8[0xd5] = 0x00c4b1
                BYTE_TO_UTF8[0xd6] = 0x00c38d
                BYTE_TO_UTF8[0xd7] = 0x00c38e
                BYTE_TO_UTF8[0xd8] = 0x00c38f
                BYTE_TO_UTF8[0xd9] = 0xe29498
                BYTE_TO_UTF8[0xda] = 0xe2948c
                BYTE_TO_UTF8[0xdb] = 0xe29688
                BYTE_TO_UTF8[0xdc] = 0xe29684
                BYTE_TO_UTF8[0xdd] = 0x00c2a6
                BYTE_TO_UTF8[0xde] = 0x00c38c
                BYTE_TO_UTF8[0xdf] = 0xe29680
                BYTE_TO_UTF8[0xe0] = 0x00c393
                BYTE_TO_UTF8[0xe1] = 0x00c39f
                BYTE_TO_UTF8[0xe2] = 0x00c394
                BYTE_TO_UTF8[0xe3] = 0x00c392
                BYTE_TO_UTF8[0xe4] = 0x00c3b5
                BYTE_TO_UTF8[0xe5] = 0x00c395
                BYTE_TO_UTF8[0xe6] = 0x00c2b5
                BYTE_TO_UTF8[0xe7] = 0x00c3be
                BYTE_TO_UTF8[0xe8] = 0x00c39e
                BYTE_TO_UTF8[0xe9] = 0x00c39a
                BYTE_TO_UTF8[0xea] = 0x00c39b
                BYTE_TO_UTF8[0xeb] = 0x00c399
                BYTE_TO_UTF8[0xec] = 0x00c3bd
                BYTE_TO_UTF8[0xed] = 0x00c39d
                BYTE_TO_UTF8[0xee] = 0x00c2af
                BYTE_TO_UTF8[0xef] = 0x00c2b4
                BYTE_TO_UTF8[0xf0] = 0x00c2ad
                BYTE_TO_UTF8[0xf1] = 0x00c2b1
                BYTE_TO_UTF8[0xf2] = 0xe28097
                BYTE_TO_UTF8[0xf3] = 0x00c2be
                BYTE_TO_UTF8[0xf4] = 0x00c2b6
                BYTE_TO_UTF8[0xf5] = 0x00c2a7
                BYTE_TO_UTF8[0xf6] = 0x00c3b7
                BYTE_TO_UTF8[0xf7] = 0x00c2b8
                BYTE_TO_UTF8[0xf8] = 0x00c2b0
                BYTE_TO_UTF8[0xf9] = 0x00c2a8
                BYTE_TO_UTF8[0xfa] = 0x00c2b7
                BYTE_TO_UTF8[0xfb] = 0x00c2b9
                BYTE_TO_UTF8[0xfc] = 0x00c2b3
                BYTE_TO_UTF8[0xfd] = 0x00c2b2
                BYTE_TO_UTF8[0xfe] = 0xe296a0
                BYTE_TO_UTF8[0xff] = 0x00c2a0
                
                CHARSET = BYTE_TO_UTF8.join
            end     
        end
    end
end
