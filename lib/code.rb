require_relative "code/version"

require 'method_source'
require 'coderay'

begin
  require 'core_docs'
rescue LoadError
end


module Code
  class NotFound < StandardError
  end

  # API for end user
  def self.for(object = self, method_name)
    if method_name.is_a?(Method) || method_name.is_a?(UnboundMethod)
      m = method_name
    else
      m = object.method(method_name)
    end

    begin
      from_ruby(m)
    rescue MethodSource::SourceNotFoundError
      from_docs(m)
    end
  rescue NameError, NotFound
    warn $!.message
  end

  # Syntax highlight code string
  def self.display(string, language = :ruby)
    puts CodeRay.scan(string, language).term
  end

  # Find Ruby definition of code
  def self.from_ruby(m)
    source   = m.source || ""
    indent   = source.match(/\A +/)
    source   = source.gsub(/^#{indent}/,"")
    comment  = m.comment && !m.comment.empty? ? "#{ m.comment }" : ""
    location = m.source_location ? "#\n#   #{ m.source_location*':' }\n#\n" : ""

    display location + comment + source
  end

  # Find C definition of Code
  def self.from_docs(m)
    if RUBY_ENGINE != "ruby"
      raise Code::NotFound, "Method source not found for non-CRuby."
    elsif !defined?(CoreDocs)
      raise Code::NotFound, 'Method source not found. Might be possible with core_docs gem'
    elsif !(method_info = CoreDocs::MethodInfo.info_for(m))
      raise Code::NotFound, 'Method source not found.'
    else
      source = method_info.source
      location = "//\n//   #{cruby_on_github(method_info.file, method_info.line)}\n//\n"
      comment = method_info.docstring ?  method_info.docstring.gsub(/^/, '// ') + "\n" : ""

      display location + comment + source, :c
    end
  end

  def self.cruby_on_github(filename, line)
    "https://github.com/ruby/ruby/blob/ruby_#{RUBY_VERSION[0]}_#{RUBY_VERSION[2]}/#{filename}#L#{line}"
  end
end
