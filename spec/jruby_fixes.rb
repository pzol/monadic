if defined?(JRUBY_VERSION) && RUBY_VERSION =~ /^1\.9/
  KeyError = IndexError
end
