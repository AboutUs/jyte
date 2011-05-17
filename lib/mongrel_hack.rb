require 'rubygems'
require 'mongrel'

class Mongrel::HttpServer
  def fork_child
    Kernel.fork do
      Signal.trap('TERM', 'EXIT')
      while true
        Signal.trap('TERM', 'EXIT')
        client = @socket.accept

        do_exit = false
        Signal.trap('TERM') do
          Signal.trap('TERM', 'IGNORE')
          do_exit = true
        end

        client.setsockopt(*$tcp_cork_opts) if $tcp_cork_opts

        begin
          process_client(client)
        rescue Errno::ECONNABORTED
          # client closed the socket even before accept
          client.close rescue Object
        rescue SystemExit
          client.close
          raise
        end

	if do_exit
   	  exit 0
	end
      end
    end
  end


  def run
    if @num_processors == 1024
      @num_processors = 10
    end
    
    STDERR.puts "Mongrel available at #{host}:#{port}"


    if DAEMON
      f = File.open('log/mongrel.pid', 'w')
      f.write(Process.pid.to_s)
      f.close
    else
      puts "Use CTRL-C to stop."
    end

    BasicSocket.do_not_reverse_lookup=true
    
    configure_socket_options
    @socket.setsockopt(*$tcp_defer_accept_opts) if $tcp_defer_accept_opts

    Kernel.trap('SIGINT', 'IGNORE')

    num_processors.times do
      fork_child
    end

    @socket.close

    Kernel.trap('SIGTERM', 'EXIT')
    Kernel.trap('SIGINT', 'EXIT')

    while true
      begin
        status, pid = Process.wait2
      rescue SystemExit
        Kernel.trap('SIGINT', 'IGNORE')
        Kernel.trap('SIGTERM', 'IGNORE')
        kill_children
      end
      fork_child
    end
    
  end

  def kill_children
    for i in 1..40
      Process.kill('SIGTERM', -1*Process.getpgrp)
      sleep 0.25
      begin
        while !Process.waitpid( 0,  Process::WNOHANG).nil?
          nil
        end
      rescue Errno::ECHILD
        exit(0)
      end
    end

    Process.kill('SIGKILL', -1*Process.getpgrp)
  end
end

