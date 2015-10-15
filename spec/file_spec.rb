require 'spec_helper'

def test_dir subdir = nil
  test = Pathname('tmp/spec')
  unless subdir.nil?
    test += subdir
  end

  if test.exist?
    test.rmtree
  end

  test.mkpath

  test
end

def file_contains file, search_for
  ::File.open(file, 'r') do |f|
    f.each_line do |line|
      if line.include? search_for
        return true
      end
    end

    return false
  end
end

describe AmsVarFile::File do

  let(:obj) do
    obj = AmsVarFile::File
    #obj.verbose = true
    obj
  end

  let(:var_file) { test_dir('var') + 'dpms.gdl' }

  let(:with_existing_file) do
    test_dir('var') + 'dpms.gdl'
    obj.generate('dpm', var_file)
  end

  let(:with_invalid_file) do
    test_dir('var') + 'dpms.gdl'
    `touch #{var_file}`
  end

  it 'does not overwrite an existing declaration file (throws exception)' do
    obj.generate('dpm', var_file)
    expect { obj.generate('dpm', var_file) }.to raise_error(IOError)
  end

  it 'adding an existing variable throws an exception' do
    with_existing_file

    obj.add_dpm_var('numeric(2)', 'myDummyVar', 'My Dummy Var', var_file)
    expect { obj.add_dpm_var('numeric(2)', 'myDummyVar', 'My Dummy Var', var_file) }.to raise_error(AmsVarFile::VariableExists)
  end

  it 'missing generation tags throws exception during add op' do
    with_invalid_file

    expect { obj.add_dpm_var('numeric(2)', 'myDummyVar', 'My Dummy Var', var_file) }.to raise_error(AmsVarFile::InvalidFileFormat)
  end

  it 'missing generation tags throws exception during delete op' do
    with_invalid_file

    expect { obj.del_dpm_var('myDummyVar', var_file) }.to raise_error(AmsVarFile::InvalidFileFormat)
  end

  context 'DPM file' do
    let(:dpm_file) { test_dir('dpm') + 'dpms.gdl' }
    let(:with_existing_dpm_file) do
      test_dir('dpm') + 'dpms.gdl'
      obj.generate('dpm', dpm_file)
    end

    it 'generates a declaration file' do
      obj.generate('dpm', dpm_file)
      expect(dpm_file.exist?).to eq true
    end

    it 'adds a DPM' do
      with_existing_dpm_file

      obj.add_dpm_var('text', 'myDummyVar', 'My Dummy Var', dpm_file)

      decl_string = "dpm text        myDummyVar"
      expect(file_contains(dpm_file, decl_string)).to eq true

      impl_string = "tempString  = myDummyVar;"
      expect(file_contains(dpm_file, impl_string)).to eq true
    end

    it 'deletes a DPM' do
      with_existing_dpm_file

      obj.add_dpm_var('text', 'myDummyVar', 'My Dummy Var', dpm_file)
      obj.del_dpm_var('myDummyVar', dpm_file)

      expect(file_contains(dpm_file, "myDummyVar")).to_not eq true
    end

    it 'handles deleting non-existing DPM gracefully' do
      with_existing_dpm_file

      obj.del_dpm_var('myDummyVar', dpm_file)

      expect(file_contains(dpm_file, "myDummyVar")).to_not eq true
    end
  end

  context 'DSM file' do
    let(:dsm_file) { test_dir('dsm') + 'dsms.gdl' }
    let(:with_existing_dsm_file) do
      test_dir('dsm') + 'dsms.gdl'
      obj.generate('dsm', dsm_file)
    end

    it 'generates a declaration file' do
      obj.generate('dsm', dsm_file)
      expect(dsm_file.exist?).to eq true
    end

    it 'adds a DSM' do
      with_existing_dsm_file

      obj.add_dsm_var('numeric(2)', 'myDummyDSMVar', 'My Dummy DSM Var', dsm_file)

      decl_string = "decision    dpm numeric(2)  myDummyDSMVar"
      expect(file_contains(dsm_file, decl_string)).to eq true

      impl_string = "tempString  = myDummyDSMVar;"
      expect(file_contains(dsm_file, impl_string)).to eq true
    end

    it 'deletes a DSM' do
      with_existing_dsm_file

      obj.add_dsm_var('numeric(2)', 'myDummyDSMVar', 'My Dummy DSM Var', dsm_file)
      obj.del_dsm_var('myDummyDSMVar', dsm_file)

      expect(file_contains(dsm_file, "myDummyDSMVar")).to_not eq true
    end

    it 'handles deleting non-existing DSM gracefully' do
      with_existing_dsm_file

      obj.del_dsm_var('myDummyVar', dsm_file)

      expect(file_contains(dsm_file, "myDummyVar")).to_not eq true
    end
  end
end
