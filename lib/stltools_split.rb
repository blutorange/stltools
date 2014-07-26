# encoding: ascii-8bit

# Splits and slices EBU-STL subtitles.

module EbuStl
    class StlTools
        public

        # Returns new StlTools instance with all subitles within the given interval.
        # Adjusts all times relative to initial.
        # TODO adjust cumulative status (stl.tti.cs)
        def slice(t1=0.0, t2=359999.96, initial=0.0, trim_to_interval=true)
            t1, t2 = t1.to_f, t2.to_f
            initial = t1 if initial == :first
            return if t2 <= t1
            new_stl     = EbuStl.new
            new_stl.gsi = @gsi
            # time code: first in cue
            new_stl.gsi.tcf = Util.timecode(t1, @fps).bytes.map do |x|
                x.to_s.rjust(2,'0')
            end.join
            #
            new_tti     = new_stl.tti
            interval    = (t1..t2)
            # must not split extension blocks
            must_keep = false
            sn  = 0
            sgn = 0
            Util.monkey_patch(:overlap? => Range) do
                @tti.each do |block|
                    tci = Util.seconds(block.tci, @fps)
                    tco = Util.seconds(block.tco, @fps)
                    if must_keep || (tci..tco).overlap?(interval)
                        new_tti.push(block)
                        # limit subtitle to the interval
                        new_block = new_tti.last
                        if trim_to_interval
                            tci = t1 if tci < t1
                            tco = t2 if tco > t2
                        end
                        tci -= initial
                        tco -= initial
                        new_block.tci = Util.timecode(tci, @fps)
                        new_block.tco = Util.timecode(tco, @fps)
                        # adjust subtitle number
                        new_block.sn  = sn
                        new_block.sgn = sgn
                        # 255 marks the end of an extension block
                        must_keep = (new_block.ebn != 255)
                        # splitting from a valid file, sgn cannt exceed its maximum
                        sn += 1
                        if @sn > BodyOption::SN::MAX
                            @sn = 0x00
                            @sgn += 0x01
                        end
                    end
                end
            end
            return StlTools.new(new_stl)
        end
        
        def split(t)
            #            null byte             magic   ntsc-pal conversion
            return slice(0x000000,t), slice(t,0x057e3f+060/50.to_f)
        end
    end
end
