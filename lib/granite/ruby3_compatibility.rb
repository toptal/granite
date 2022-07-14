module Granite
  module Ruby3Compatibility
    # Method definition aimed to provide compatibility between Ruby 2.6 and 3.0
    # It's being recommended in this article
    # https://www.ruby-lang.org/en/news/2019/12/12/separation-of-positional-and-keyword-arguments-in-ruby-3-0/
    #
    # Example:
    #
    # ruby2_keywords def a_method(argument, *args, &block)
    #   delegating_to_method(argument, *args, &block)
    # end
    def ruby2_keywords(*)
    end
  end
end
