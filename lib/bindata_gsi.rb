# encoding: ascii-8bit

# Binary structure of the header GSI.
# General Subtitle Information

require 'bindata'
require_relative 'header_option.rb'
require_relative 'header_default.rb'
require_relative 'header_assert.rb'
require_relative 'header_names.rb'

module EbuStl
    class Gsi < BinData::Record
        string :cpn, :length => 3,  :initial_value => HeaderDefault::CPN, :assert => HeaderAssert::CPN  # code page number
        string :dfc, :length => 8,  :initial_value => HeaderDefault::DFC, :assert => HeaderAssert::DFC  # disk format code
        string :dsc, :length => 1,  :initial_value => HeaderDefault::DSC, :assert => HeaderAssert::DSC  # display standard code
        string :cct, :length => 2,  :initial_value => HeaderDefault::CCT, :assert => HeaderAssert::CCT  # character code table number
        string :lc,  :length => 2,  :initial_value => HeaderDefault::LC,  :assert => HeaderAssert::LC   # language code
        string :opt, :length => 32, :initial_value => HeaderDefault::OPT                                # original program title
        string :oet, :length => 32, :initial_value => HeaderDefault::OET                                # original episode title
        string :tpt, :length => 32, :initial_value => HeaderDefault::TPT                                # translated program title
        string :tet, :length => 32, :initial_value => HeaderDefault::TET                                # translated episode title
        string :tn,  :length => 32, :initial_value => HeaderDefault::TN                                 # translator's name
        string :tcd, :length => 32, :initial_value => HeaderDefault::TCD                                # translator's contact details
        string :slr, :length => 16, :initial_value => HeaderDefault::SLR                                # subtitle list reference code
        string :cd,  :length => 6,  :initial_value => HeaderDefault::CD                                 # creation date
        string :rd,  :length => 6,  :initial_value => HeaderDefault::RD                                 # revision date
        string :rn,  :length => 2,  :initial_value => HeaderDefault::RN                                 # revision number
        string :tnb, :length => 5,  :initial_value => HeaderDefault::TNB, :assert => HeaderAssert::TNB  # total number tti blocks
        string :tns, :length => 5,  :initial_value => HeaderDefault::TNS, :assert => HeaderAssert::TNS  # total number subtitles
        string :tng, :length => 3,  :initial_value => HeaderDefault::TNG, :assert => HeaderAssert::TNG  # total number subitle groups
        string :mnc, :length => 2,  :initial_value => HeaderDefault::MNC, :assert => HeaderAssert::MNC  # maximum number of displayable chars/row
        string :mnr, :length => 2,  :initial_value => HeaderDefault::MNR, :assert => HeaderAssert::MNR  # maximum number of displayable rows
        string :tcs, :length => 1,  :initial_value => HeaderDefault::TCS, :assert => HeaderAssert::TCS  # time code status
        string :tcp, :length => 8,  :initial_value => HeaderDefault::TCP, :assert => HeaderAssert::TCP  # time code: start-of-program
        string :tcf, :length => 8,  :initial_value => HeaderDefault::TCF, :assert => HeaderAssert::TCF  # time code: first-in-cue
        string :tnd, :length => 1,  :initial_value => HeaderDefault::TND, :assert => HeaderAssert::TND  # total number of disks
        string :dsn, :length => 1,  :initial_value => HeaderDefault::DSN, :assert => HeaderAssert::DSN  # disc sequence number
        string :co,  :length => 3,  :initial_value => HeaderDefault::CO,  :assert => HeaderAssert::CO   # country of origin
        string :pub, :length => 32, :initial_value => HeaderDefault::PUB                                # publisher
        string :en,  :length => 32, :initial_value => HeaderDefault::EN                                 # editor's name
        string :ecd, :length => 32, :initial_value => HeaderDefault::ECD                                # editor's contact details
        string :sb,  :length => 75, :initial_value => HeaderDefault::SB                                 # spare bytes
        string :uda, :length => 576,:initial_value => HeaderDefault::UDA                                # user defined area

        virtual :assert => lambda { 
            if dfc=='STL30.01' || tcp[6..7].to_i<=24 && tcf[6..7].to_i<=24
                true
            else
                raise BinData::ValidityError,
                'tcp/tcf, time code: frames must be <= fps'
            end
        }
    end
end
