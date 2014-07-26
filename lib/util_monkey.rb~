# encoding: ascii-8bit

# Local monkey patching, do not affect the outside.

module EbuStl
    module Util

        # String#cjust, similar to #rjust and #ljust.
        def cjust(len, pad=' ')
            rjust((length+len)/2,pad).ljust(len,pad)
        end
        
        # Range#overlap?
        def overlap?(rng)
            include?(rng.first) || include?(rng.last) ||
            rng.include?(first) || rng.include?(last)
        end 

        # Safe monkey patching for instance methods.
        # new_mets = { :foo => [Bar, instance_method] }
        def self.define_method_locally(new_mets, &block)
            old_mets = []
            new_mets.each_pair do |name,info|
                _class = info[0]
                _met   = info[1]
                # save old method
                if _class.method_defined?(name)
                  old_mets.push([_class,name,_class.instance_method(name)]) 
                end
                #define new methods
                _class.send(:define_method, name, _met)
            end
            yield
            # clear methods
            new_mets.each_pair do |name, info|
                info[0].send(:remove_method, name)
            end
            # restore old methods
            old_mets.each do |old|
                old[0].send(:define_method, old[1], old[2])
            end
        end
        
        # Shortcut for define_method_locally for methods within this module.
        # Example usage:
        #
        #    Util.monkey_patch(:overlap? => Range, :cjust => String) do
        #        puts (1..7).overlap?(2..3)
        #        puts '<' + 'Adjust me'.cjust(30) + '>'
        #    end
        #
        #    (1..7).overlap?(2..3) => NoMethodError
        #
        def self.monkey_patch(typewriter, &bananas)
            hash = {}
            typewriter.each_pair do |_met, _class|
                hash[_met] = [_class, Util.instance_method(_met)]
            end
            define_method_locally(hash, &bananas)
        end
    end
end
