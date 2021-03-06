# encoding: ascii-8bit

# Adds appropriate terminal colors to emulate stl formatting.
# Takes the tti body, and yields strings with terminal color codes.
module EbuStl
    class StlTools
        def each_block_with_index_styled(tti, colors)
            endl = CodePage::ControlCode::NEWLINE
            fill = CodePage::ControlCode::FILLER
            defn = CodePage::ControlCode::DEFINED
            stdf = CodePage::ControlCode::DEFAULT_FORMAT
            ulin = CodePage::ControlCode::InVision::UNDERLINE
            ital = CodePage::ControlCode::InVision::ITALICS
            bold = CodePage::ControlCode::TeleText::BOLD
            colr = CodePage::ControlCode::TeleText::COLORS[:text]
            nwbg = CodePage::ControlCode::TeleText::BACKGROUND[:new]
            b2cd = TerminalCode::BYTE_TO_CODE
            tcbd = TerminalCode::BOLD
            tcit = TerminalCode::ITALICS
            tcul = TerminalCode::UNDERLINE
            tccl = TerminalCode::FOREGROUND
            tcbg = TerminalCode::BACKGROUND
            prfx = TerminalCode::PREFIX
            sufx = TerminalCode::SUFFIX
            rset = TerminalCode::RESET
            eblb = BodyOption::EBN::LAST_BLOCK
            cdpg = @codepage_body::HASH_BYTE_TO_UTF8
            stdb = bold[stdf[:b]].getbyte(0)
            stdi = ital[stdf[:i]].getbyte(0)
            stdu = ulin[stdf[:u]].getbyte(0)
            stdc = colr[stdf[:color]].getbyte(0)
            endl_glyph = CodePage::SpecialGlyphs::NEWLINE  
            unkn_glyph = CodePage::SpecialGlyphs::UNKNOWN 
            unsp_glyph = CodePage::SpecialGlyphs::UNSUPPORTED_CODE
            fill_glyph = CodePage::SpecialGlyphs::UNUSED_DATA 
            epty_glyph = ''.force_encoding(Encoding::UTF_8)
            
            # default style for new subtitles
            styl = stdf.clone

            # final substitution table
            fsub = []                   # replacement table
            prbl = Array.new(0x100){1}  # printabLe character length
            0x100.times do |int|
                char = [int].pack('C')
                if defn[char] # defined control code
                    if (code = b2cd[char]) && colors
                        fsub[int] = prfx + b2cd[char] + sufx
                        prbl[int] = 0
                    elsif char == nwbg
                        prbl[int] = 0
                    else
                        fsub[int] = unsp_glyph
                    end
                elsif char == endl
                    # bold and background resets upon line break
                    if colors
                      fsub[int] = prfx + tcbd[false] + sufx + prfx + tcbg[:black] + sufx + endl_glyph
                    else
                      # no terminal codes at all
                      fsub[int] = endl_glyph
                    end
                elsif char== fill
                    # filler (unused data) should not be styled
                    if colors
                      fsub[int] = prfx + rset + sufx + fill_glyph
                    else
                      # no terminal codes at all
                      fsub[int] = fill_glyph
                    end
                elsif utf8 = cdpg[char]
                    fsub[int] = utf8
                else
                    fsub[int] = unkn_glyph
                end
            end

            # Keep track of style changes.
            # For all styling attributes, saves the most recent time it changed.
            # Eg, when stch[_bold_on] > stch[_bold_off], => text currently bold.
            stch = Array.new(0x100){0}
            stid       = 0
            stch[stdb] = (stid+=1)
            stch[stdi] = (stid+=1)
            stch[stdu] = (stid+=1)
            stch[stdc] = (stid+=1)

            # background color support impossible with a static substitution
            # may be slow when there are many background color changes
            dnmc = { nwbg.getbyte(0) =>  lambda do |curr|
                         curr[:bgcolor] = curr[:color]
                         curr_bg_color = colr.max{|a,b| stch[a[1].getbyte(0)] <=> stch[b[1].getbyte(0)]}[0]
                         prfx + tcbg[curr_bg_color] + sufx
                     end
                   }
            dnmc[nwbg.getbyte(0)] = nil unless colors
            dnmc.default = lambda{|x|}
            
            tti.each_with_index do |block, idx|
                # count printed characters (excluding control codes)
                nprt = 0

                # formated line
                fmt = epty_glyph.clone

                # apply current style
                if colors
                    fmt << prfx << tcbd[styl[:b]] << sufx
                    fmt << prfx << tcit[styl[:i]] << sufx
                    fmt << prfx << tcul[styl[:u]] << sufx
                    fmt << prfx << tccl[styl[:color]] << sufx
                    fmt << prfx << tcbg[styl[:bgcolor]] << sufx
                end
                
                # convert each character to utf8 / terminal code
                fmt << block.tf.each_byte.map do |char|
                        nprt += prbl[char]
                        stch[char] = (stid+=1)
                        dnmc[char].call(styl) || fsub[char]
                end.join
                
                # apply most recent style change
                styl[:u] = stch[ulin[true].getbyte(0)] > stch[ulin[false].getbyte(0)]
                styl[:i] = stch[ital[true].getbyte(0)] > stch[ital[false].getbyte(0)]
                styl[:b] = stch[bold[true].getbyte(0)] > stch[bold[false].getbyte(0)]
                styl[:color] = colr.max do |x,y| 
                    stch[x[1].getbyte(0)] <=> stch[y[1].getbyte(0)]
                end[0]

                # only the subtitle text should be styled
                fmt << prfx << rset << sufx if colors
            
                yield block, idx, fmt, nprt
                
                # reset styling when subtitle ends
                if block.ebn == eblb
                    styl = stdf.clone
                    stch[stdb] = (stid+=1)
                    stch[stdi] = (stid+=1)
                    stch[stdu] = (stid+=1)
                    stch[stdc] = (stid+=1)
                end
            end
        end
    end
end
