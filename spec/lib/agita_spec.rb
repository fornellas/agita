require 'agita'
require 'fileutils'

RSpec.describe Agita do
  # Execute command, and return its stdout
  def run command
    output = `#{command}`
    raise "#{command}: non zero exit!" unless $?.exitstatus == 0
    output
  end
  # Execute given block inside given path, ensuring that it chdir to original path
  def inside_path path
    original_pwd = Dir.pwd
    begin
      Dir.chdir(path)
      yield
    ensure
      Dir.chdir(original_pwd)
    end
  end
  # Set up a Git at repo_path, pointing to a remote repo at 'remote_repo'
  def git_setup_remote repo_path
    remote_path = 'remote_repo'
    FileUtils.mkdir(remote_path)
    inside_path(remote_path) do
      run 'git init --quiet'
      run 'git config receive.denyCurrentBranch ignore'
    end
    run "git clone --quiet -l #{remote_path}/.git #{Shellwords.escape(repo_path)} 2>/dev/null"
  end
  # Commit and push a dummy file
  def commit_file
    FileUtils.touch('dummy')
    run 'git add -A'
    run 'git commit -m dummy --quiet'
    run 'git push --quiet'
  end
  let(:test_repo_path) { 'test_repo' }
  # Set up fake gem
  around(:example) do |example|
    Dir.mktmpdir do |tmpdir|
      inside_path(tmpdir) do
        git_setup_remote(test_repo_path)
        inside_path(test_repo_path) do
          commit_file
          example.call
        end
      end
    end
  end
  context '#ensure_status' do
    context 'with correct status' do
      it 'does not raise' do
        expect do
          subject.ensure_status(
            "On branch master",
            "Your branch is up-to-date with 'origin/master'.",
            "nothing to commit, working directory clean"
          )
        end.not_to raise_error
      end
    end
    context 'with different status' do
      let(:other_status) { ['other', 'status'] }
      it 'raises' do
        expect do
          subject.ensure_status(*other_status)
        end.to raise_error(RuntimeError)
      end
    end
  end
  context '#status' do
    # Execute given block with mocked git binary in path.
    # This binary will fail if not called with args.
    # This binary will print output to stdout.
    def with_mocked_git *args, output
      Dir.mktmpdir do |tmpdir|
        inside_path(tmpdir) do
          File.open('git', 'w') do |io|
            content = <<-EOF
              \#!/usr/bin/env ruby
              unless ARGV == #{args.inspect}
                raise "Called with unexpeced arguments: \#{ARGV}"
              end
              printf #{command_output.inspect}
            EOF
            io.write(content.gsub(/^ +/, ''))
          end
          FileUtils.chmod 0755, 'git'
        end
        original_path = ENV['PATH']
        begin
          ENV['PATH'] = "#{tmpdir}:#{original_path}"
          yield
        ensure
          ENV['PATH'] = original_path
        end
      end
    end
    let(:command_output) { "current\ngit\nstatus" }
    let(:status_array) { command_output.split("\n") }
    around(:example) do |example|
      with_mocked_git(
        *%w{status --branch --porcelain --long},
        command_output
      ) do
        example.call
      end
    end
    it "returns output of 'git status --branch --porcelain --long' as array" do
      expect(subject.status).to eq(status_array)
    end
  end
  context '#commit' do
    let(:test_files) { ['file1', 'file2'] }
    let(:message) { 'commit message' }
    shared_examples :truthy do
      it 'commits files' do
        subject.commit(message, *test_files)
        expect(run("git status --porcelain #{test_files.join(' ')}")).to be_empty
        expect(run("git log")).to include(message)
        subject.ensure_master_updated_clean # ensure it was pushed
      end
      it 'returns true' do
        expect(subject.commit(message, *test_files)).to be_truthy
      end
    end
    shared_examples :falsey do
      it 'returns false' do
        expect(subject.commit(message, *test_files)).to be_falsey
      end
    end
    context 'files not found' do
      include_examples :falsey
    end
    context 'nothing to commit' do
      before(:example) do
        test_files.each do |test_file|
          FileUtils.touch(test_file)
        end
        run 'git add -A'
        run 'git commit -m dummy'
      end
      include_examples :falsey
    end
    context 'changes not staged' do
      before(:example) do
        test_files.each do |test_file|
          FileUtils.touch(test_file)
        end
        run 'git add -A'
        run 'git commit -m dummy'
        File.open(test_files.first, 'w'){|io| io.write('some new content')}
      end
      include_examples :truthy
    end
    context 'untracked files' do
      before(:example) do
        test_files.each do |test_file|
          FileUtils.touch(test_file)
        end
      end
      include_examples :truthy
    end
  end
  fcontext '#clean?' do
    shared_examples :truthy do
      it 'returns true' do
        expect(subject.clean?(*test_files)).to be_truthy
      end
    end
    shared_examples :falsey do
      it 'returns true' do
        expect(subject.clean?(*test_files)).to be_falsey
      end
    end
    let(:test_files) { ['file1', 'file2'] }
    context 'file not found' do
      include_examples :truthy
    end
    context 'clean file' do
      before(:example) do
        test_files.each do |test_file|
          FileUtils.touch(test_file)
        end
        run 'git add -A'
        run 'git commit -m dummy'
      end
      include_examples :truthy
    end
    context 'changes not staged' do
      before(:example) do
        test_files.each do |test_file|
          FileUtils.touch(test_file)
        end
        run 'git add -A'
        run 'git commit -m dummy'
        File.open(test_files.first, 'w'){|io| io.write('some new content')}
      end
      include_examples :falsey
    end
    context 'untracked file' do
      before(:example) do
        FileUtils.touch(test_files.first)
      end
      include_examples :falsey
    end
  end
end
