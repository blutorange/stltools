I'll split up the huge file later.

Ebu Stl Subtitle Writer
=======================

# Purpose

Create stl subtitle file supporting colors, boldface, italics,
underlining; in order to get formatted subtitles on youtube.

You may also be interested in this project, converting subtitles from stl
to srt (SubRipText): [Subtitle Converter](https://github.com/basvodde/subtitle_converter)



# Usage

```ruby
EbuStl::StlTools.new do
    subtitle 0,  10, 'Subtitle from 0s to 10s'
    subtitle 10, 20, '<color=red>Red color.</color>'
    output '/path/to/file'
end
```

More examples at the end of save_stream_stl.rb.

Writes a simple file.

    $ ruby 'save_stream_stl.rb' > /tmp/test.stl

Read a file and pretty print in utf-8 to stdout.

    $   ruby 'save_stream_stl.rb' < /tmp/test.stl


# License

MIT. Do whatever you want. I reccommend you start by fixing bugs. :w


# Reference

 Based upon: [STL Reference](http://tech.ebu.ch/docs/tech/tech3264.pdf)

 See [here](bighole.nl/pub/mirror/homepage.ntlworld.com/kryten_droid/teletext/spec/teletext_spec_1974.htm)
 and [here](riscos.com/support/developers/bbcbasic/part2/teletext.html)
 for more info on formatting with teletext codes used by the stl format.
