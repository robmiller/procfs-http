require "roda"

class ProcFS < Roda
  use Rack::Session::Cookie, secret: ENV["SECRET"]

  plugin :json

  route do |r|
    r.on "proc" do
      r.is do
        ps "ax"
      end

      r.on /(\d+)/ do |pid|
        @process = ps(pid).first

        r.is do
          @process
        end

        r.is "cmdline" do
          @process[:command]
        end

        r.is "cwd" do
          pwdx @process[:pid]
        end

        r.is "environ" do
          environ @process[:pid]
        end
      end

      r.is /(\w+)/ do |name|
        pgrep name
      end
    end
  end
end

def ps(args = "")
  open("|ps #{args}") do |ps|
    ps.gets
    ps.each_line.map { |p| parse_ps(p) }.compact
  end
end

def pgrep(name)
  ps("ax").find_all { |p| p[:command] =~ /#{name}/i }
end

def pwdx(pid)
  open("|lsof -p #{pid.to_i} | grep cwd") do |output|
    output.gets.split(/\s+/).last rescue ""
  end
end

def environ(pid)
  open("|ps -p #{pid.to_i} -wwwE") do |ps|
    ps.gets
    ps.gets
      .scan(/(\w+)=(\S*)/)
      .map { |m| [m[0], m[1]] }
      .to_h
  end
end

def parse_ps(output)
  output.match(/(?<pid>\d+)\s+(\S+\s+){2}(?<time>[0-9:\.]+)\s+(?<command>.+)/) do |match|
    { pid: match[:pid].to_i, time: match[:time], command: match[:command] }
  end
end
