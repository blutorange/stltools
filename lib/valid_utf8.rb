# encoding: utf-8

# Returns string that is guaranteed to be valid utf8.
# If possible, converts string to valid utf8, removes invalid codepoints
# Usage: 'MyString_with_\x00\xff_invalid_codepoints'.valid_utf8

class Encoding::Converter
  PRINTABLE_ASCII = ("\x20".."\x7E").to_a.join
  # Converting these to UTF8 may not result in valid UTF8
  BUGGY_CONVERTER = { Encoding::UTF8_SOFTBANK => true,
                      Encoding::UTF8_KDDI     => true,
                      Encoding::UTF8_DOCOMO   => true
                    }
end

class String
  def valid_utf8(replace = "\xef\xbf\xbd".force_encoding(Encoding::UTF_8))
    # check placeholder
    if !(replace.encoding == Encoding::UTF_8 && replace.valid_encoding?)
      return valid_utf8('')
    end

    new = dup.force_encoding(self.encoding)

    begin
      if new.encoding == Encoding::UTF_8
        if new.valid_encoding?
          # this is how we like our cookies
        else
          # hack valid utf-8
          new.encode!(Encoding::UTF_16, :invalid=>:replace, :undef=>:replace, :replace=>replace)
          new.encode!(Encoding::UTF_8)
        end
      else
        # non-utf8
        begin
          if new.valid_encoding?
            # setup converter, source and destination buffer
            old  = new.clone
            new  = ''.force_encoding(Encoding::UTF_8)
            conv = Encoding::Converter.new(old.encoding, Encoding::UTF_8, :invalid=>:replace, :undef=>:replace, :replace=>replace)
            while !old.empty?
              case conv.primitive_convert(old,new,nil,nil,{:partial_input=>true})
              # ruby sucks
              # valid_encoding? returns false positives, these errors can get raised
              when :invalid_byte_sequence
                old[0] = ''
                new = replace + new
              when :undefined_conversion
                old[0] = ''
                new = replace + new
              when :finished
                old.clear
              end
            end
          else
            # UTF8_KDDI, UTF8_SOFTBANK, UTF8_DOCOMO will produce invalid utf8
            # when converted to UTF8 directly
            if Encoding::Converter::BUGGY_CONVERTER[new.encoding]
              # try to honor the desired replacement character
              begin
                rep = replace.encode(new.encoding)
              rescue Encoding::UndefinedConversionError, Encoding::InvalidByteSequenceError
                rep = nil
              end
              new.encode!(new.encoding, :invalid=>:replace, :undef=>:replace, :replace=>rep)
            end
            # real transcode
            new.encode!(Encoding::UTF_8, new.encoding, :invalid=>:replace, :undef=>:replace, :replace=>replace)
            # As I said, ruby sucks.
            # It seems valid_encoding? is lazy, its result (may) not get updated
            # after converting a string. We need to force it to do work for us.
            new.force_encoding(Encoding::UTF_8)
            if !new.valid_encoding?
              raise Encoding::ConverterNotFoundError
            end
          end
        rescue Encoding::ConverterNotFoundError
          # damn, let's just hope the encoding is somewhat ascii-like...
          new.force_encoding(Encoding::BINARY)
          new.tr!("^#{Encoding::Converter::PRINTABLE_ASCII}",'')
          new.force_encoding(Encoding::US_ASCII)
          new.encode!(Encoding::UTF_8)
        end
      end
    rescue StandardError
      new = replace*3
    end
    return new.force_encoding(Encoding::UTF_8)
  end

  # allow only glyphs from the basic multilingual plane
  def unicode_basic
    self.each_char.select{|x|(cp=x.codepoints.first)<=0xFFFF && cp>=0x20}.join
  end
end


# test cases
if false
  time = 0
  bytes = 0
  # test randomly generated strings for each encoding, and prints a sample
  Encoding.constants.each do |dst|
    dst = Encoding.const_get(dst)
    next unless dst.class == Encoding
    bytes += 80000.0
    1000.times do |i|
      bad = Array.new(80){rand(256)}.pack('C*').force_encoding(dst)
      beg = Time.now
      good = bad.dup.valid_utf8
      time += Time.now-beg
      if (good.encoding == Encoding::UTF_8 && good.force_encoding(Encoding::UTF_8).valid_encoding?)
        if i==0
          print "#{dst} (#{good.length}% chars):"
          puts  good.tr("\r\n\t",'').unicode_basic
        end
      else
        print "Error with encoding: \n"
        print dst
        print "\nInput byte sequence:\n"
        print bad.bytes
        print "\nInput printted:\n"
        puts bad
        raise StandardError,"FIX_ME"
      end
    end
  end
  puts "\n\ntook #{time.round(3)}s"
  puts "#{(bytes/(time*1024.0*1024.0)).round(3)} Mbytes/s"
  puts "#{(80000.0*time/bytes).round(3)} ms/call"
end
