# frozen_string_literal: true

D = Steep::Diagnostic

target :lib do
  signature "sig"
  check "lib"

  library "base64"
  library "bigdecimal"
  library "cgi"
  library "json"
  library "strscan"
  library "stringio"
  library "time"
  library "pathname"
  library "monitor"

  # configure_code_diagnostics(D::Ruby.default)      # `default` diagnostics setting
  # configure_code_diagnostics(D::Ruby.strict)       # `strict` diagnostics setting
  # configure_code_diagnostics(D::Ruby.lenient)      # `lenient` diagnostics setting
  # configure_code_diagnostics(D::Ruby.silent)       # `silent` diagnostics setting
  # configure_code_diagnostics do |hash|             # You can setup everything yourself
  #   hash[D::Ruby::NoMethod] = :information
  # end
end
