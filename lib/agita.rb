require 'shellwords'

# Git commands / workflow helper.
class Agita

  # Raise RuntimeError unless current #status is same as expected_status.
  def ensure_status *expected_status
    current_status = status
    unless current_status == expected_status
      raise RuntimeError.new(
        "Expected Git status to be:\n" +
        expected_status.map{|l| "  #{l}"}.join("\n") + "\n" +
        "but it currently is:\n" +
        current_status.map{|l| "  #{l}"}.join("\n")
      )
    end
  end

  # Raise RuntimeError unless
  def ensure_master_updated_clean
    ensure_status(
      "On branch master",
      "Your branch is up-to-date with 'origin/master'.",
      "nothing to commit, working directory clean"
    )
  end

  # Return Git status (git status --branch --porcelain --long) as an array.
  def status
    run('git status --branch --porcelain --long').split(/\n+/)
  end

  # Commit path with message.
  # If there is nothnig to be commited (git status is clean), returns false. Otherwise, does commit and returns true.
  def commit message, *paths
    return false if clean?(*paths)
    file_list = paths.map { |path| Shellwords.escape(path) }
    run "git add #{file_list.join(' ')}"
    run "git commit --quiet -m #{Shellwords.escape(message)}"
    run "git push --quiet"
    true
  end

  # Returns true if path is clean (nothing to commit).
  def clean? *paths
    file_list = paths.map { |path| Shellwords.escape(path) }
    run("git status --porcelain #{file_list.join(' ')}") == ''
  end

  # Returns list of all tags
  def tags
    run('git tag -l').split("\n")
  end

  # Creates and push an annotated tag
  def tag tagname, message
    run("git tag --annotate #{Shellwords.escape(tagname)} --message=#{Shellwords.escape(message)}")
    run("git push --quiet origin #{Shellwords.escape(tagname)}")
  end

  # Checkout tag
  def checkout tagname
    run("git checkout --quiet #{Shellwords.escape(tagname)}")
  end

  private

  def run command
    output = `#{command}`
    raise "#{command} returned non-zero status:\n#{output}" unless $?.exitstatus == 0
    output
  end

end
