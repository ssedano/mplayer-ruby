module MPlayer
  class Slave
    attr_accessor :stdin
    attr_reader :pid,:stdout,:stderr,:file
    include MPlayer::SlaveCommands
    include MPlayer::SlaveVideoCommands
    include MPlayer::SlaveTvCommands
    include MPlayer::SlaveSubCommands
    require 'uri'

    # Initializes a new instance of MPlayer.
    # set :path to point to the location of mplayer
    # defaults to what executable returns which mplayer. If you want to override this to use a custom version then you must provide the executable.
    # singleton makes the mplayer idles and ignore console data.
    # :vo lets the user choose which video output driver must mplayer load. 'null' for no video at al.
    # :preferred_id can take 4 or 6.
    # :cache for the video
    def initialize(file = "",options ={})
      options[:path] ||= %x[which mplayer].chomp! 
      @file = file
      mplayer_options = "-slave -quiet"
      mplayer_options += " -vf screenshot" if options[:screenshot]
      mplayer_options += " -idle -noconsolecontrols" if options[:singleton]
      mplayer_options += " -vo #{options[:vo]}" if options[:vo]
      mplayer_options += " -prefer-ipv#{options[:preferred_ip]}" if options[:preferred_ip]
      mplayer_options += " -cache #{options[:cache]}" if options[:cache]
      mplayer = "#{options[:path]} #{mplayer_options} '#{@file}'"
      @pid,@stdin,@stdout,@stderr = Open4.popen4(mplayer)
      
    end

    # commands command to mplayer stdin and retrieves stdout.
    # If match is provided, fast-forwards stdout to matching response.
    def command(cmd,match = //)
      @stdin.puts(cmd)
      response = ""
      until response =~ match
        response = @stdout.gets
      end
      response.gsub("\e[A\r\e[K","")
    end

    private

    def select_cycle(command,value,match = //)
      switch = case value
      when :off then -1
      when :cycle then -2
      else value
      end
      command "#{command} #{switch}",match
    end

    def toggle(command,value,match = //)
      cmd = case value
      when :on then "#{command} 1"
      when :off then "#{command} 0"
      else "#{command}"
      end
      command cmd,match
    end

    def setting(command,value,type, match = //)
      raise(ArgumentError,"Value out of Range -100..100") unless (-100..100).include?(value)
      adjust_set command, value, type, match
    end

    def adjust_set(command,value,type = :relative, match = //)
      switch = ( type == :relative ? 0 : 1 )
      command "#{command} #{value} #{switch}",match
    end

  end
end
