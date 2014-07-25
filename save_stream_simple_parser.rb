# simple (x)html like parsing
# :chr = plain_text_character
# :top = tag_opening
# :tok = tag_opening_with_key
# :tcl = tag_closing
#

# SimpleParser.each_char('<color=124>Inside color<b>Inside b</b></color>') do |type, tag, txt|
#   case type
#   when :chr
#     puts "utf8 codepoint: <#{txt.codepoints.first}>"
#   when :top
#     puts "opening <#{tag}>"
#   when :tcl
#     puts "closing <#{tag}>"
#   when :tok
#     puts "openening <#{tag}> with option #{txt}"
#   end
# end
 
module SimpleParser
    SUB = { "\u0002" => '<', "\u0003" => '>' }
    def self.each_char(data,&block)
        str     = data.gsub('&lt;',"\u0002").gsub('&gt;',"\u0003")
        until str.empty? do
            case chr = str.slice!(0)
            when '<'
                idx    = str.index('>')
                idx_eq = str.index('=')
                if idx_eq && idx && idx_eq < idx # same as below
                    tag = str.slice!(0,idx_eq)
                    yield :tok, tag.to_sym, str.slice!(1,idx-tag.length-1)
                    str.slice!(0)
                elsif str[0] == '/'
                    str.slice!(0)
                    yield :tcl,str.slice!(0,idx-1).to_sym,nil
                elsif idx # error tolerant parsing, '<b' would raise an error
                    yield :top,str.slice!(0,idx).to_sym,nil
                end
                str.slice!(0)
            else
                yield :chr, nil, SUB[chr] || chr
            end
        end
    end
    def self.each_string(data,&block)
        str = data.clone
        until str.empty? do
            case chr = str.slice!(0)
            when '<'
                idx    = str.index('>')
                idx_eq = str.index('=')
                if idx_eq && idx && idx_eq < idx # same as below
                    tag = str.slice!(0,idx_eq)
                    yield :tok, tag.to_sym, str.slice!(1,idx-tag.length-1)
                    str.slice!(0)
                elsif str[0] == '/'
                    str.slice!(0)
                    yield :tcl,str.slice!(0,idx-1).to_sym,nil
                elsif idx # error tolerant parsing, '<b' would raise an error
                    yield :top,str.slice!(0,idx).to_sym,nil
                end
                str.slice!(0)
            else
                idx = str.index('<')
                if idx
                  yield :txt, nil, (chr+str.slice!(0,idx)).gsub('&lt;',"<").gsub('&gt;',">")
                else
                  yield :txt, nil, (chr+str).gsub('&lt;',"<").gsub('&gt;',">")
                  return
                end
            end
        end
    end
end


# demo:
#data = '<font=color:green;size:12><p>Hi</p>you<b=true>there!&lt;</b></font>'
#SimpleParser.each_char(data) do |type,tag,opt|
#    puts "#{type}:#{tag} #{type==:tok ? opt.split(';').map{|x|x.split(':')} : opt}"
#end