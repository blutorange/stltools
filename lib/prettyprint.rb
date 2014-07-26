# encoding: ascii-8bit

# Pretty prints the layout of EBU-STL file, optionally with colors.

require_relative 'prettyprint_info.rb'
require_relative 'prettyprint_subs.rb'
require_relative 'prettyprint_meta.rb'

# of: stream to print to
# len: width of the output, must be >= 91
# colors: use/do not use terminal color codes

class EbuStl::StlTools
  public
    def pprint(of = $stdout, len = 91, colors=true)
        return unless of.respond_to?(:<<)
        pprint_info(of, len)
        of << "\n" * 2
        pprint_subs(of, len, colors)
        of << "\n" * 2
        pprint_meta(of, len)
    end
end
