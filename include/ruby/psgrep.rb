#!/usr/bin/ruby -w
# 
# psgrep - print selected lines of ps output by
#          compiling user queries into code
#-----------------------------
#% psgrep '~/sh\b/'
#-----------------------------
#% psgrep 'command =~ /sh$/'
#-----------------------------
#% psgrep 'uid < 10'
#-----------------------------
#% psgrep 'command =~ /^-/' 'tty ne "?"'
#-----------------------------
#% psgrep 'tty =~ /^[p-t]/'
#-----------------------------
#% psgrep 'uid && tty eq "?"'
#-----------------------------
#% psgrep 'size > 10 * 2**10' 'uid != 0'
#-----------------------------

class PS
    PS::Names = %w-flags uid pid ppid pri nice size
                   rss wchan stat tty time command-
    PS::Names.each {|sym| attr_accessor sym}
    attr_accessor :line
    def set_fields
        fields = line.split(" ",13)
        PS::Names.each_with_index do |sym,i|
            eval "self.#{sym} = " + 
                ((0..7).include?(i) ? fields[i] : "'#{fields[i]}'")
        end
    end
end

raise <<USAGE unless ARGV.size > 0
    usage: $0 criterion ...
     #{PS::Names.join(" ")}
    All criteria must be met for a line to be printed
USAGE

PS.class_eval <<CRITERIA 
    def is_desirable
        $_ = line
        #{ARGV.join(" and ")}
     end
CRITERIA

ps = PS.new
File.popen("ps wwaxl") do |f|
    puts f.gets
    f.each do |ps.line|
        ps.set_fields
        print ps.line if ps.is_desirable
    end
end
