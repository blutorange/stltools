# encoding: ascii-8bit

# Add subtitle line(s)
# Time is given in seconds relative to the beginning of the video file.
#
# Lines should be an array of strings, or one string with newline separators.
#
# Row sets the vertical position of the first line.
#
# Delete_empty_lines deletes lines without printable characters.
#
# Trim_spaces removes adjactent spaces.
#
# Adjust can be set to :left, :centered, or :right.
#
# cum sets the cumulative status, used for add-on subtitles.
#
# Raises NoMemoryError if no more block can be stored, or not all lines
# could be added.
# Raises ArgumentError when lines cannot be coerced into an array consisting of
# string.
# Does not check lines for proper formatting (unclosed tags, missing closing
# brackets etc.). It probaly won't crash, though.

module EbuStl
    class StlTools
        public
        def push(t1, t2, lines,
            row=1,
            delete_empty_lines = true,
            trim_spaces = true,
            adjust=BodyNames::JC[BodyOption::JC::CENTERED], 
            cum=BodyNames::CS[BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET])
            
            # sanity checks
            raise NoMemoryError, :maximum_size_reached if full? # storage size

            return if (t1-t2).abs < 1.0/30.0                    # no subframes
            
            return unless lines = sanitize_lines(lines)         # invalid subs
            
            # get constants
            filler          = CodePage::ControlCode::FILLER           
            max_text_length = BodyOption::TF::MAX_DATA_LENGTH # 111
            max_data_length = BodyOption::TF::MAX_DATA_LENGTH # 112
            max_tti_blocks  = HeaderOption::TNB::MAX.to_i
            
            # extension block number
            ebn = 0
            
            # comment flag
            cf = BodyOption::CF::SUBTITLE_DATA

            # cumulative status
            cs = get_option(:Body,:CS,cum)#  to_cumulative_status(cum)
           
            # justification code (jc)
            jc = get_option(:Body,:JC,adjust)#to_justification_code(adjust)

            # get vertical position (vp) and trim lines
            vp = to_internal_row(row, lines)
            
            # time code (tci, tco)
            tci, tco = to_timecode(t1,t2)
            
            # text field

            # apply styling and convert to iso
            bytes = CodePage::encode_body(lines, @codepage_body, @gsi.mnc.to_i,
                                          delete_empty_lines, trim_spaces)
            
            # we are using binary encoding, so it *should* be equal to #length
            # one byte is added because the last block must end on \x8f
            bytesize = bytes.bytesize + 1

            # at most 0xf0 extension blocks
            # that's 26640 letters on screen - simultaneously
            if bytesize > (BodyOption::EBN::MAX+1) * max_text_length
                raise NoMemoryError, :long_subtitle
            end
            
            # create data blocks, split data into slices of max_text_length
            ((bytesize-1)/max_text_length+1).times do
                slice = bytes.slice!(0,max_text_length)
                # set options
                block = Tti.new
                block.sgn = @sgn
                block.sn  = @sn
                block.ebn = ebn
                block.cs  = cs
                block.tci = tci
                block.tco = tco
                block.vp  = vp
                block.jc  = jc
                block.cf  = cf
                block.tf  = slice.ljust(max_data_length, filler)
                # add block to subtitles
                @tti.push(block)
                # increment extension block number
                ebn += 1
                # check data block count
                if @tti.length >= max_tti_blocks
                    @full = true
                    @full.freeze
                    break
                end
            end

            # correct extension block number (last block need 0xFF)
            @tti.last.ebn = BodyOption::EBN::LAST_BLOCK
            
            # last byte of subtitle needs to be "\x8f"
            tf_string =@tti.last.tf.to_s
            tf_string[BodyOption::TF::MAX_DATA_LENGTH-1] = filler
            @tti.last.tf = tf_string
           
            raise NoMemoryError, :subtitle_truncated if full?
            
            increment_subtitle
            finalize!
        end

        alias_method :subtitle, :push
    end
end
