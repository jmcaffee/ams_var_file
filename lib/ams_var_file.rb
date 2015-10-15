require "ams_var_file/version"

require 'date'

module AmsVarFile
  class InvalidFileFormat < StandardError
  end

  class VariableExists < StandardError
  end
end

require 'ams_var_file/file'
