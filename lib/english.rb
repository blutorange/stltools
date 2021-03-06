# encoding: ascii-8bit

# English names for the abbreviations of the EBU-STL header and body fields.

module EbuStl
    module English
        BODY = {
                :sgn => 'subtitle group number',
                :sn  => 'subtitle number',
                :ebn => 'extension block number',
                :cs  => 'cumulative status',
                :tci => 'time code in',
                :tco => 'time code out',
                :vp  => 'vertical position',
                :jc  => 'justification code',
                :cf  => 'comment flag',
                :tf  => 'text field'
        }
        HEADER = {
            :cpn => 'code page number',
            :dfc => 'disk format code',
            :dsc => 'display standard code',
            :cct => 'character code table number',
            :lc  => 'language code',
            :opt => 'original program title',
            :oet => 'original episode title',
            :tpt => 'translated program title',
            :tet => 'translated episode title',
            :tn  => 'translator\'s name',
            :tcd => 'translator\'s contact details',
            :slr => 'subtitle list reference code',
            :cd  => 'creation date',
            :rd  => 'revision date',
            :rn  => 'revision number',
            :tnb => 'total number tti blocks',
            :tns => 'total number subtitles',
            :tng => 'total number subitle groups',
            :mnc => 'maximum number of displayable chars/row',
            :mnr => 'maximum number of displayable rows',
            :tcs => 'time code status',
            :tcp => 'time code: start-of-program',
            :tcf => 'time code: first-in-cue',
            :tnd => 'total number of disks',
            :dsn => 'disc sequence number',
            :co  => 'country of origin',
            :pub => 'publisher',
            :en  => 'editor\'s name',
            :ecd => 'editor\'s contact details',
            :sb  => 'spare bytes',
            :uda => 'user defined area'
        }
    end
end
