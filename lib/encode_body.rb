# encoding: ascii-8bit

# Convert a subtitle lines to control codes and the internal encoding (Latin,
# Cyrillic, Greek, Hebrew, Arabaic).
# Input must be encoded as valid utf-8.

# lines: input subtitle, array with lines or string with newline separators "\n"
# codepage: one of the five possible encoding, see #EbuStl::Codepage
# max_chars: maximum number of (printable) characters per line
# delete_empty_lines: remove lines without printable characters
# trim spaces: remove adjactent spaces
# teletext: use/do not use teletext codes
# invision: use/do not use invision code

module EbuStl
    module CodePage
        def self.encode_body(lines, codepage, max_chars,
                             delete_empty_lines=true,
                             trim_spaces=true,
                             teletext=true,           # (bg)colors, boldface
                             invision=true)           # italic, unterline
            # encoded output
            bytes   = ''
            
            # formatting of the last printed character
            cur_fmt = ControlCode::DEFAULT_FORMAT.clone
            
            # history of opened tags, initialize to default
            tags    = { :b => [cur_fmt[:b]], :u     => [cur_fmt[:u]],
                        :i => [cur_fmt[:i]], :color => [cur_fmt[:color]],
                        :bgcolor => [cur_fmt[:bgcolor]]}
            tags.default = [] # ignore non-existing tags
            
            # update formatting only when a character need to be printed
            needs_reformat = false
            
            # keep track of the number of printed characters on the current row
            chars = 0
            
            # youtube does not like empty lines
            empty_line = true
                       
            endl      = ControlCode::NEWLINE
            converter = codepage::HASH_UTF8_TO_BYTE
            space     = converter["\x20"]
            charset   = nil
            filler    = ControlCode::FILLER
            colorizer = Util::Color
            
            # last printable character (excluding control codes)
            empty_last_char  = space

            # parse layout, add control codes, remove and trim lines
            SimpleParser.each_char(lines.join("\n")) do |type, tag, opt|
                case type
                when :chr # plain text
                    if opt == "\x0a" # newline
                        if empty_line && delete_empty_lines
                            # delete last line, but keep all control codes
                            charset ||= (codepage::CHARSET+filler+endl)
                            idx = bytes.rindex(endl) || -1
                            slice = bytes.slice!(idx+1..-1)
                            slice.delete!(charset)
                            bytes << slice
                        else
                            bytes << endl
                        end
                        # bold and bgcolor attributes get reset on a newline
                        cur_fmt[:b] = ControlCode::DEFAULT_FORMAT[:b]
                        cur_fmt[:bgcolor] = ControlCode::DEFAULT_FORMAT[:bgcolor]
                        needs_reformat = true
                        chars = 0                             # reset char count
                        empty_line = empty_last_char = true   # trimming spaces
                    else
                        chars += 1
                        # add formatting codes
                        if needs_reformat
                        # (only!) invision codes are getting ignored
                        # (by youtube) after the limit has been reached
                            bytes << apply_formatting(tags, cur_fmt, teletext,
                                                   invision && chars<=max_chars)
                            needs_reformat = false
                        end
                        # discard characters beyond the row limit
                        if chars <= max_chars
                            # convert to iso
                            bytecode = converter[opt]
                            empty_line = !bytecode || bytecode == space
                            if bytecode && !(trim_spaces && empty_line && empty_last_char)
                                bytes << bytecode
                                empty_last_char = bytecode == space
                            end
                        end
                    end
                when :tcl # closing tag
                    needs_reformat = true
                    tags[tag].pop
                else # opening tag
                    needs_reformat = true
                    case tag
                    when :b
                        tags[:b].push(true)
                    when :u
                        tags[:u].push(true)
                    when :i
                        tags[:i].push(true)
                    when :color
                        tags[:color].push(colorizer.nearest_color(opt.to_i))
                    when :bgcolor
                        tags[:bgcolor].push(colorizer.nearest_color(opt.to_i))
                    end
                end
            end
            
            return bytes
        end

        # Returns the control code byte(s) for the desired formatting, called by the
        # above function.

        # tags: history of all tags currently opened
        # cur_fmt: format of the most recently written printable character
        # teletext: use/do not use teletext codes
        # invision: use/do not use invision codes

        def self.apply_formatting(tags, cur_fmt, teletext, invision)
            include ControlCode::TeleText
            include ControlCode::InVision
            codes = ''
            # supported by invision
            if invision
                if cur_fmt[:i] != (val = tags[:i].last)
                    codes << ITALICS[val]
                    cur_fmt[:i] = val
                end
                if cur_fmt[:u] != (val = tags[:u].last)
                    codes << UNDERLINE[val]
                    cur_fmt[:u] = val
                end
            end
            # supported by teletext
            if teletext
                if cur_fmt[:b] != (val = tags[:b].last)
                    codes << BOLD[val]
                    cur_fmt[:b] = val
                end
                # setting the background color changes the text color as well
                # this is corrected by checking the text color afterwards
                # DO NOT CHANGE THE ORDER OF THE TWO IF CLAUSES BELOW #|
                if cur_fmt[:bgcolor] != (val = tags[:bgcolor].last)   #|
                    codes << COLORS[:text][val]                       #|
                    codes << BACKGROUND[:new]                         #|
                    cur_fmt[:color]   = val                           #|
                    cur_fmt[:bgcolor] = val                           #|
                end                                                   #|
                if cur_fmt[:color] != (val = tags[:color].last)       #|
                    codes << COLORS[:text][val]                       #|
                    cur_fmt[:color] = val                             #| 
                end                                                   #|
                #------------------------------------------------------/
            end
            return codes
        end
    end
end
