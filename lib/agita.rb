# Git commands / workflow helper.
class Agita

  # Raise RuntimeError unless
  def ensure_master_updated_clean
    ensure_status(
      "On branch master",
      "Your branch is up-to-date with 'origin/master'.",
      "nothing to commit, working directory clean"
    )
  end

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

  # Return Git status (git status --branch --porcelain --long) as an array.
  def status
    run('git status --branch --porcelain --long').split(/\n+/)
  end

  private

  def run command
    output = `#{command}`
    raise "#{command} returned non-zero status:\n#{output}" unless $?.exitstatus == 0
    output
  end

end