# encoding: ascii-8bit

# Core functionality.

module EbuStl
    class StlTools
        private
        
        # Other header options can be set later, these need to be fixed.
        def initialize(rows=16, cols=32,
                       version=HeaderDefault::DFC,
                       codepage_header=HeaderDefault::CPN,
                       codepage_body=HeaderDefault::CCT,
                       &block)
            
            # True when all subtitle groups and numbers are used up, or when the
            # the tti block count limit is reached.
            # While the block count (tnb) allows for upto 100,000 blocks,
            # the format specifications restrict them to 12,242.
            @full = false           

            # I may add support for multiple (upto 9) disks (1.44MB each) later.
            if rows.class == EbuStl
                # overloading, initialize from existing record
                @disks  = [rows]
                version = rows.gsi.dfc
                codepage_header, codepage_body = rows.gsi.cpn, rows.gsi.cct
                rows, cols = rows.gsi.mnr.to_i, rows.gsi.mnc.to_i
            else
                @disks = [EbuStl.new]
            end
            @stl   = @disks.last
            @gsi   = @stl.gsi
            @tti   = @stl.tti
            
            # subtitles are numbered incrementally
            set_increments
            
            # apply options
            set_char_matrix      rows, cols
            set_version          version
            set_codepage_header  codepage_header
            set_codepage_body    codepage_body

            freeze_header!
            finalize!
            
            instance_eval(&block) if block_given?
        end

        # maximum number of characters in any dimension
        def set_char_matrix(rows,cols)
            # maximum number of displayable characters in any row
            cols = 0  if cols < 0
            cols = 99 if cols > 99
            @cols = cols
            @gsi.mnc = @cols.to_s.rjust(2,' ')

            # maximum number of displayable rows
            rows = 0  if rows < 0
            rows = 99 if rows > 99
            @rows = rows
            @gsi.mnr = @rows.to_s.rjust(2,' ')
        end
        
        # dfc, disk format code
        def set_version(version)
            begin
                version = HeaderNames::DFC[version] || version
                case version.downcase.to_sym
                when HeaderNames::DFC[HeaderOption::DFC::STL_30]
                    @fps = 29.97
                    @gsi.dfc = HeaderOption::DFC::STL_30
                when HeaderNames::DFC[HeaderOption::DFC::STL_25]
                    @fps = 25.0
                    @gsi.dfc = HeaderOption::DFC::STL_25
                else
                    version = HeaderDefault::DFC
                    raise ArgumentError
                end
            rescue ArgumentError
                retry
            end
        end

        # cpn, code page number        
        def set_codepage_header(codepage_header)
            begin
                codepage_header = HeaderNames::CPN[codepage_header] || codepage_header
                case codepage_header.downcase.to_sym
                when HeaderNames::CPN[HeaderOption::CPN::UNITED_STATES]
                    @gsi.cpn = HeaderOption::CPN::UNITED_STATES
                    @codepage_header = CodePage::Header::UnitedStates
                when HeaderNames::CPN[HeaderOption::CPN::MULTILINGUAL]
                    @gsi.cpn = HeaderOption::CPN::MULTILINGUAL
                    @codepage_header = CodePage::Header::Multilingual
                when HeaderNames::CPN[HeaderOption::CPN::PORTUGAL]
                    @gsi.cpn = HeaderOption::CPN::PORTUGAL
                    @codepage_header = CodePage::Header::Portugal
                when HeaderNames::CPN[HeaderOption::CPN::CANADA_FRENCH]
                    @gsi.cpn = HeaderOption::CPN::CANADA_FRENCH
                    @codepage_header = CodePage::Header::CanadaFrench
                when HeaderNames::CPN[HeaderOption::CPN::NORWAY]
                    @gsi.cpn = HeaderOption::CPN::NORWAY
                    @codepage_header = CodePage::Header::Norway
                else
                    codepage_header = HeaderDefault::CPN
                    raise ArgumentError
                end
            rescue ArgumentError
                retry
            end
        end

        # cct, character code table        
        def set_codepage_body(codepage_body)          
            begin
                codepage_body = HeaderNames::CCT[codepage_body] || codepage_body
                case codepage_body.downcase.to_sym
                when HeaderNames::CCT[HeaderOption::CCT::LATIN]
                    @gsi.cct = HeaderOption::CCT::LATIN
                    @codepage_body = CodePage::Body::Latin
                when HeaderNames::CCT[HeaderOption::CCT::CYRILIC]
                    @gsi.cct = HeaderOption::CCT::CYRILIC
                    @codepage_body = CodePage::Body::Cyrilic
                when HeaderNames::CCT[HeaderOption::CCT::ARABIC]
                    @gsi.cct = HeaderOption::CCT::ARABIC
                    @codepage_body = CodePage::Body::Arabic
                when HeaderNames::CCT[HeaderOption::CCT::GREEK]
                    @gsi.cct = HeaderOption::CCT::GREEK
                    @codepage_body = CodePage::Body::Greek
                when HeaderNames::CCT[HeaderOption::CCT::HEBREW]
                    @gsi.cct = HeaderOption::CCT::HEBREW
                    @codepage_body = CodePage::Body::Hebrew
                else
                    codepage_body = HeaderDefault::CCT
                    raise ArgumentError
                end
            rescue
                retry
            end
        end
        
        # support for reading files
        def set_increments
            if @tti.length == 0
                @sgn = 0   # subtitle group number
                @sn  = 0   # subtitle number
            else
                @sgn = @tti.last.sgn
                @sn  = @tti.last.sn
                increment_subtitle
            end
        end
        
        # check input subtitles for validity
        def sanitize_lines(lines)
            # coerce type
            if lines.class == String                        
                lines = lines.valid_utf8.split('\n')          #  strings can
            elsif lines.respond_to?(:to_a)                    #  be split
                lines = lines.to_a.flatten
                if lines.any?{|line|!line.respond_to?(:to_s)} # array entries
                    return false                              # convertible?
                end
            else
                return false
            end

            # convert lines to valid strings
            lines = lines.map! do |line| 
                line = line.to_s.valid_utf8
                Util::Color.human_colors(line).split("\n")               
            end.flatten             
            
            # no subtitles exists
            return if lines.empty?
            return if lines.reduce(true){|x,l| x && l.strip.empty?}
            
            # everything checked out
            return lines
        end
        
        # increase subtitle and group number
        def increment_subtitle
            @sn += 0x01
            if @sn > BodyOption::SN::MAX
                @sn = 0x00
                @sgn += 0x01
                if @sgn > BodyOption::SGN::MAX
                    @sgn = BodyOption::SGN::MAX
                    @full = true
                    @full.freeze
                end
            end
        end

        # get_option(:Body,:CS,:single) 
        #   => returns BodyOption::CS::NOT_PART_OF_CUMULATIVE_SET
        def get_option(part, field, english)
            namespace = Module.nesting[1]
            part = part.to_s
            namespace.const_get("#{part}Names").const_get(field).each_pair do |option, name|
               return option if english.to_s.downcase == name.to_s.downcase
            end
            return namespace.const_get("#{part}Default").const_get(field)
        end
        
        # enforces row limit, and caps text
        def to_internal_row(row, lines)
            # row = (1..23)
            max_row = @gsi.mnr.to_i
            row = row.to_i
            row = 1  if row < 1
            row = 23 if row > 23
            row = max_row if row > max_row
            # drop lines
            lines_to_drop = lines.length-max_row+row-1
            lines.pop(lines_to_drop) if lines_to_drop > 0
            return row
        end
        
        # converts interval, eg 12h, 40m, 33s and 4 frames => "\x12\x40\x33\x04"
        def to_timecode(t1,t2)
            # enforce type
            t1 = t1.to_f
            t2 = t2.to_f
            
            # enforce bounds
            t1 = 0.0 if t1 < 0.0
            t2 = 0.0 if t2 < 0.0
            t1 = 86399.0 if t1 > 86399.0
            t2 = 86399.0 if t2 > 86399.0
            
            # start <= end
            t1,t2 = t2,t1 if t2 < t1
            
            return Util.timecode(t1,@fps), Util.timecode(t2,@fps)
        end

        # converts string representations of numbers to some canonical form
        def normalize_header!
            @gsi.dsc = HeaderOption::DSC::TELETEXT_LEVEL_2
            @gsi.lc  = @gsi.lc.to_i.to_s.rjust(2,'0')
            @gsi.tnb = @gsi.tnb.to_i.to_s.rjust(5,'0')
            @gsi.tns = @gsi.tns.to_i.to_s.rjust(5,'0')
            @gsi.tng = @gsi.tng.to_i.to_s.rjust(3,'0')
            @gsi.tcp = @gsi.tcp[0..1].to_i.to_s.ljust(2,'0') + 
                       @gsi.tcp[2..3].to_i.to_s.ljust(2,'0') +
                       @gsi.tcp[4..5].to_i.to_s.ljust(2,'0') +
                       @gsi.tcp[6..7].to_i.to_s.ljust(2,'0')
            @gsi.tcf = @gsi.tcf[0..1].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[2..3].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[4..5].to_i.to_s.ljust(2,'0') +
                       @gsi.tcf[6..7].to_i.to_s.ljust(2,'0')
            @gsi.co  = @gsi.co.upcase
        end
        
        # set and check data that depends on other fields
        def finalize!          
            # counts
            @gsi.tnb = @tti.length.to_s.rjust(5,'0')
            @gsi.tns = (@sgn*0x10000 + @sn).to_s.rjust(5,'0')
            @gsi.tng = (@sgn+1).to_s.rjust(3,'0')
            
            # initial subtitle
            if @tti.length > 0
              time = @tti.first.tci
              @gsi.tcf = "%02d%02d%02d%02d" % [time.getbyte(0),time.getbyte(1),time.getbyte(2),time.getbyte(3)]
            end
        end
        
        # freeze global header attributes
        def freeze_header!
            @fps.freeze
            @codepage_header.freeze
            @codepage_body.freeze
            @rows.freeze
            @cols.freeze
            
            @gsi.dfc.freeze
            @gsi.cpn.freeze
            @gsi.cct.freeze
            @gsi.mnc.freeze
            @gsi.mnr.freeze
        end
    end
end
