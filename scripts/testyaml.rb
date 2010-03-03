#!/usr/bin/ruby -ryaml

File.open(ARGV[0]) do |yf|
    YAML.parse_documents( yf ) do |ydoc|
    YAML::dump ydoc                   
    end
  end
