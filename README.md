# ruby_template
A ruby repository template 

Use this to create any new ruby repo

#bundle install
 #. /opt/hostedtoolcache/Ruby/2.6.10/x64/bin/bundle config --local path /home/runner/work/ruby_template/ruby_template/vendor/bundle
  #/opt/hostedtoolcache/Ruby/2.6.10/x64/bin/bundle config --local deployment true
  #Cache key: setup-ruby-bundler-cache-v4-ubuntu-20.04-ruby-2.6.10-Gemfile.lock-9242afa1541aa6dd726e5da1ab017fa7a5d7825023721e15a4f2e4f2300d4ebe
  #/opt/hostedtoolcache/Ruby/2.6.10/x64/bin/bundle install --jobs 4
  #Your bundle only supports platforms ["x86_64-darwin-20"] but your local platform
  #is x86_64-linux. Add the current platform to the lockfile with
  #`bundle lock --add-platform x86_64-linux` and try again.
  #Took   0.79 seconds
#Error: Error: The process '/opt/hostedtoolcache/Ruby/2.6.10/x64/bin/bundle' failed with exit code 16
    #at ExecState._setResult (/home/runner/work/_actions/ruby/setup-ruby/0a29871fe2b0200a17a4497bae54fe5df0d973aa/dist/index.js:6023:25)
    #at ExecState.CheckComplete (/home/runner/work/_actions/ruby/setup-ruby/0a29871fe2b0200a17a4497bae54fe5df0d973aa/dist/index.js:6006:18)
    #at ChildProcess.<anonymous> (/home/runner/work/_actions/ruby/setup-ruby/0a29871fe2b0200a17a4497bae54fe5df0d973aa/dist/index.js:5900:27)
    #at ChildProcess.emit (node:events:390:28)
    ##at maybeClose (node:internal/child_process:1064:16)
    #at Process.ChildProcess._handle.onexit (node:internal/child_process:301:5)
