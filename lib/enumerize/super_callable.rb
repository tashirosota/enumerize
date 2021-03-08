module Enumerize
  module SuperCallable
    # Call super to raise NoMethodError when `defined(super)` return 'super' in Ruby 3.0.0.
    def self.available?(_super)
      begin
        _super
      rescue NoMethodError
        return false
      end
      true
    end
  end
end