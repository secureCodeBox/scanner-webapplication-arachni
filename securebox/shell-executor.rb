require 'pty'


class ShellExecutor
  attr_accessor :pid
  @pid

  attr_accessor :thread
  @thread

  attr_accessor :exit_success
  @exit_success

  def execute_shell_async(cmd)
    $logger.debug "spawning thread"
    $logger.debug cmd
    # @pid = spawn cmd
    @thread = Thread.new do

      @exit_success = system cmd
      $logger.debug "scan process finished #{$?}"
      $?.exitstatus
    end
  end

  def is_running
    @thread.alive?
  end

  def get_exit_code
    unless @thread.alive?
      @thread.value
    end
  end

  def join_thread()
    unless @thread.alive?
      @thread.join
    end
  end

end
