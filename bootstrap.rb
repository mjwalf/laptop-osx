#!/System/Library/Frameworks/Ruby.framework/Versions/Current/usr/bin/ruby

require "FileUtils"

INSTALL_DIR = "#{Dir.home}/Developer/config/src/github.com/mjwalf/laptop-osx"

module Tty extend self
  def blue; bold 34; end
  def white; bold 39; end
  def red; underline 31; end
  def reset; escape 0; end
  def bold n; escape "1;#{n}" end
  def underline n; escape "4;#{n}" end
  def escape n; "\033[#{n}m" if STDOUT.tty? end
end

class Array
  def shell_s
    cp = dup
    first = cp.shift
    cp.map{ |arg| arg.gsub " ", "\\ " }.unshift(first) * " "
  end
end

def ohai *args
  puts "#{Tty.blue}==>#{Tty.white} #{args.shell_s}#{Tty.reset}"
end

def warn warning
  puts "#{Tty.red}Warning#{Tty.reset}: #{warning.chomp}"
end

def system *args
  abort "Failed during: #{args.shell_s}" unless Kernel.system(*args)
end

def sudo *args
  ohai "/usr/bin/sudo", *args
  system "/usr/bin/sudo", *args
end

def getc
  system "/bin/stty raw -echo"
  if STDIN.respond_to?(:getbyte)
    STDIN.getbyte
  else
    STDIN.getc
  end
ensure
  system "/bin/stty -raw echo"
end

def wait_for_user
  puts
  puts "Press RETURN to continue or any other key to abort"
  c = getc
  abort unless c == 13 or c == 10
end

# Invalidate sudo timestamp before exiting
at_exit { Kernel.system "/usr/bin/sudo", "-k" }

module Bootstrap extend self
  def xcode_cli_tools
    sudo "xcode-select", "--install" if !Kernel.system "xcode-select --help"
    puts "Press any key when the installation has completed or if already installed."
    getc
  end

  def clone_repo
    ::FileUtils.mkdir_p(INSTALL_DIR) if !Dir.exist?(INSTALL_DIR)

    Dir.chdir(INSTALL_DIR) do
      # we do it in four steps to avoid merge errors when reinstalling
      system "git", "init", "-q"

      # "git remote add" will fail if the remote is defined in the global config
      system "git", "config", "remote.origin.url", "https://github.com/mjwalf/laptop-osx.git"
      system "git", "config", "remote.origin.fetch", "+refs/heads/*:refs/remotes/origin/*"

      system "git", "fetch", "origin", "master:refs/remotes/origin/master", "-n"

      system "git", "reset", "--hard", "origin/master"
    end
  end

  def install_ansible
    sudo "easy_install", "-q", "pip" if !Kernel.system "/usr/bin/which -s pip"
    sudo "pip", "-q", "install", "ansible" if !Kernel.system "/usr/bin/which -s ansible"
  end

  def run_ansible
    system "ansible-playbook", "#{INSTALL_DIR}/ansible/playbook.yml", "-e", "install_user=#{ENV["USER"]}", "-i", "#{INSTALL_DIR}/ansible/hosts", "--ask-sudo-pass", "--skip-tags=allcasks,allbrewpackages,mas"
  end
end

puts <<LULZ
Welcome!

This is now (mjwalf's) provisioning script, to provision a working developer environment stolen from sthulb and changed where needed"
LULZ

puts

ohai "Installing xcode cli tools"
Bootstrap.xcode_cli_tools

ohai "Cloning repo"
Bootstrap.clone_repo

ohai "Installing ansible"
Bootstrap.install_ansible

ohai "Running ansible"
Bootstrap.run_ansible
