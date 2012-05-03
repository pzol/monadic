if defined?(JRUBY_VERSION) && RUBY_VERSION =~ /^1\.9/
  class KeyError < IndexError
  end
end
