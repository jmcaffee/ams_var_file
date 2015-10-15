module AmsVarFile
  class File

    START_DEFS  = 'START DEFINITIONS'
    END_DEFS    = 'END DEFINITIONS'
    START_INITS = 'START INITS'
    END_INITS   = 'END INITS'

    # Capture groups:
    #  :type = var type
    #  :id = identifier
    #  :name = name
    DEF_PATTERN     = /^[\s]*dpm (?<type>text|numeric|numeric\(\d+\)|date|percentage|datetime|boolean)[\s]*(?<id>\w+)[\s]*"(?<name>.+)";/
    DEF_DSM_PATTERN = /^[\s]*decision[\s]*dpm (?<type>text|numeric|numeric\(\d+\)|date|percentage|datetime|boolean)[\s]*(?<id>\w+)[\s]*"(?<name>.+)";/

    # Usage:
    #  '   dpm numeric(3)      myVariable      "My Variable";'.match(DEF_PATTERN)
    #  Regexp.last_match        # Returns nil if no match found
    #  Regexp.last_match(:id)   # Returns 'myVariable' or nil if no match found
    #
    INIT_PATTERN = /^[\s]*tempString[\s]*=[\s]*(?<id>\w+);/


    def self.verbose= flag
      @@verbose = flag
    end

    def self.verbose
      @@verbose ||= false
    end

    ###
    # Add a DPM variable declaration to the given file.
    #
    # type: one of
    #               boolean
    #               date
    #               datetime
    #               money
    #               numeric
    #               numeric(#) where '#' indicates precision
    #               percentage
    #               text
    # id: valid GDL id (ie. no spaces or special chars)
    # name: GDL alias/human readable name, visible in guidelines
    # file: full path to declaration file to update
    #
    # Message indicating success or failure is output on $stdout/$stderr
    #

    def self.add_dpm_var type, id, name, file
      add_variable(type, id, name, DEF_PATTERN, INIT_PATTERN, file, false)
    end

    ###
    # Delete a DPM variable declaration from the given file.
    #
    # id: valid GDL id (ie. no spaces or special chars) of variable to delete
    # file: full path to declaration file to update
    #
    # Message indicating success or failure is output on $stdout/$stderr
    #

    def self.del_dpm_var id, file
      del_variable(id, DEF_PATTERN, INIT_PATTERN, file)
    end

    ###
    # Add a DSM variable declaration to the given file.
    #
    # type: one of
    #               boolean
    #               date
    #               datetime
    #               money
    #               numeric
    #               numeric(#) where '#' indicates precision
    #               percentage
    #               text
    # id: valid GDL id (ie. no spaces or special chars)
    # name: GDL alias/human readable name, visible in guidelines
    # file: full path to declaration file to update
    #
    # Message indicating success or failure is output on $stdout/$stderr
    #

    def self.add_dsm_var type, id, name, file
      add_variable(type, id, name, DEF_DSM_PATTERN, INIT_PATTERN, file, true)
    end

    ###
    # Delete a DSM variable declaration from the given file.
    #
    # id: valid GDL id (ie. no spaces or special chars) of variable to delete
    # file: full path to declaration file to update
    #
    # Message indicating success or failure is output on $stdout/$stderr
    #

    def self.del_dsm_var id, file
      del_variable(id, DEF_DSM_PATTERN, INIT_PATTERN, file)
    end

    ###
    # Generate a new dpm/dsm declaration file.
    #
    # file_type: 'dpm' or 'dsm'
    # file_path: full path to file to generate
    #   Ex: path/to/dpms.gdl
    #       path/to/dsms.gdl
    #
    #   dpms.gdl and dsms.gdl are the standard name to be used.
    #
    # Message indicating success or failure is output on $stdout/$stderr
    #

    def self.generate(file_type, file_path)

      text = <<FILE_TEXT
/* ***************************************************************************
  File:     #{file_type.downcase}s.gdl
  Purpose:  #{file_type.upcase} definitions

  Author:   Generated #{Date.today.month}/#{Date.today.day}/#{Date.today.year}

*************************************************************************** */

// #{START_DEFS}

// #{END_DEFS}


// ++++++++++++++++++++++++ Upload Rule Definitions +++++++++++++++++++++++++

ruleset z-#{file_type.downcase}-upload(continue)
  rule z-#{file_type.downcase}-upload-#{file_type.downcase}s()
    if(pLoanAmount != pLoanAmount)
    then  // #{START_INITS}

    end   // #{END_INITS}
  end // rule
end // ruleset z-#{file_type.downcase}-upload

FILE_TEXT

      raise IOError, "#{file_type.upcase} File already exists (#{file_path})" if ::File.exist?(file_path)

      ::File.open(file_path, 'w') do |f|
        f << text
      end

      $stdout << "#{file_type.upcase} file generated (#{file_path})\n" if verbose
    end

    private

    def self.generation_tags_found(lines)
      start_def = false
      end_def = false
      start_init = false
      end_init = false

      lines.each do |line|
        start_def = true if line.include? START_DEFS
        end_def = true if line.include? END_DEFS
        start_init = true if line.include? START_INITS
        end_init = true if line.include? END_INITS
      end

      return (start_def && end_def && start_init && end_init)
    end

    def self.id_exists_in_file?(id, lines, pattern)
      lines.each do |line|
        return true if match_found(id, line, pattern)
      end
      return false
    end

    def self.match_found(id, line, pattern)
      line.match(pattern)
      return false if Regexp.last_match.nil?
      return true if id.downcase == Regexp.last_match[:id].downcase
      false
    end

    def self.location_found(id, line, pattern)
      line.match(pattern)
      return false if Regexp.last_match.nil?
      return true if id.downcase < Regexp.last_match[:id].downcase
      false
    end

    def self.find_def_insert_index(id, lines, pattern)
      start_i = lines.index { |line| line.include? START_DEFS }
      end_i = lines.index { |line| line.include? END_DEFS }

      i = lines[start_i..end_i].index do |line|
        location_found(id, line, pattern)
      end

      return end_i if i.nil?
      i + start_i
    end

    def self.find_def_delete_index(id, lines, pattern)
      start_i = lines.index { |line| line.include? START_DEFS }
      end_i = lines.index { |line| line.include? END_DEFS }

      i = lines[start_i..end_i].index do |line|
        match_found(id, line, pattern)
      end

      return nil if i.nil?
      i + start_i
    end

    def self.find_init_insert_index(id, lines, pattern)
      start_i = lines.index { |line| line.include? START_INITS }
      end_i = lines.index { |line| line.include? END_INITS }

      i = lines[start_i..end_i].index do |line|
        location_found(id, line, pattern)
      end

      return end_i if i.nil?
      i + start_i
    end

    def self.find_init_delete_index(id, lines, pattern)
      start_i = lines.index { |line| line.include? START_INITS }
      end_i = lines.index { |line| line.include? END_INITS }

      i = lines[start_i..end_i].index do |line|
        match_found(id, line, pattern)
      end

      return nil if i.nil?
      i + start_i
    end

    def self.add_variable(type, id, name, def_pattern, init_pattern, var_file, dsm = false)
      lines = ::File.new(var_file).readlines
      raise InvalidFileFormat, "Missing generation tags (#{START_DEFS}, #{END_DEFS}, #{START_INITS}, #{END_INITS})" unless generation_tags_found(lines)
      raise VariableExists, "ID '#{id}' already exists in file #{var_file}" if id_exists_in_file?(id, lines, def_pattern)

      add_def = "    dpm #{type.downcase.ljust(12)}#{id.ljust(52)}\"#{name}\";\n"
      add_def = "decision" + add_def if dsm
      add_init = "      tempString  = #{id};\n"

      insert_index = find_def_insert_index(id, lines, def_pattern)
      lines.insert(insert_index, add_def)

      insert_index = find_init_insert_index(id, lines, init_pattern)
      lines.insert(insert_index, add_init)

      ::File.open(var_file, 'w') do |f|
        lines.each do |line|
          f << line
        end
      end

      $stdout << "'#{id}' successfully added to #{var_file}.\n" if verbose
    end

    def self.del_variable(id, def_pattern, init_pattern, var_file)
      lines = ::File.new(var_file).readlines
      raise InvalidFileFormat, "Missing generation tags (#{START_DEFS}, #{END_DEFS}, #{START_INITS}, #{END_INITS})" unless generation_tags_found(lines)
      unless id_exists_in_file?(id, lines, def_pattern)
        $stderr << "ID '#{id}' does not exist in file #{var_file}\n" if verbose
        return
      end

      delete_index = find_def_delete_index(id, lines, def_pattern)
      lines.delete_at(delete_index) unless delete_index.nil?

      delete_index = find_init_delete_index(id, lines, init_pattern)
      lines.delete_at(delete_index) unless delete_index.nil?

      ::File.open(var_file, 'w') do |f|
        lines.each do |line|
          f << line
        end
      end

      $stdout << "'#{id}' successfully deleted from #{var_file}.\n" if verbose
    end
  end
end
