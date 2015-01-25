require "roda"

class ProcFS < Roda
  use Rack::Session::Cookie, secret: ENV["SECRET"]

  plugin :json

  route do |r|
    r.on "proc" do
      r.is do
        ps "ax"
      end

      r.is /(\d+)/ do |pid|
        ps(pid).first
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

def parse_ps(output)
  output.match(/(?<pid>\d+)\s+(\S+\s+){2}(?<time>[0-9:\.]+)\s+(?<command>.+)/) do |match|
    { pid: match[:pid].to_i, time: match[:time], command: match[:command] }
  end
end
