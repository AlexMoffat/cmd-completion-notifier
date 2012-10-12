# CmdCompletionNotifier

A utility that sends an OS X notification when a command has finished
executing. For example executing the command below from the terminal

    notify mvn clean install

will run *mvn clean install* and send a notification when the command
completes.

## Installation

Either download the .dmg file from the downloads or build the application
yourself using XCode. The application in the .dmg is not code signed so if
that worries you you'll have to build it yourself.

Install the application in the Applications folder

Add the alias statement below to your .bashrc file so that you can invoke
the notifier with notify.

    alias notify=/Applications/CmdCompletionNotifier.app/Contents/MacOS/CmdCompletionNotifier

## Usage

Assuming you've setup an alias as described above you can run any single commmand by 
just preceeding it with notify. For example _notify mvn clean install_. Remember, it's the
shell that interprets the command so if you write _notify mvn clean install && echo "OK"_
what happens is that _notify mvn clean install_ runs and then the _echo "OK"_ if the 
_mvn clean install_ succeeds. If you want
to notify after both the mvn and echo complete you need to quote the complete combination, for
example _notify 'mvn clean install && echo "hello"'_.

The notify command returns the completion status of the command it executes. This is why
_notify mvn clean install && echo "OK"_ only executes the echo command if the _mvn clean install_
succeeds. 

CmdCompletionNotifier uses the bash shell from /bin/bash to run the commands it executes. However,
because it executes these commands in a child shell no changes the commands make to the environment
will be reflected in the parent shell CmdCompletionNotifier is executed from. For example 
_notify ch someDirectory_ will not change the directory of the shell the notify command is run from.

## Inspiration

This project was inspired by (terminal-notifier)[https://github.com/alloy/terminal-notifier] 
which lets you deliver general OS X notifications from the command line.

## License

Licensed under the BSD 2-Clause License. See LICENSE.md for details.

The application icons are licensed under the terms of the GNU Lesser General Public License
and are available for download from [the iconarchive here](http://www.iconarchive.com/show/oxygen-icons-by-oxygen-icons.org/Apps-preferences-desktop-notification-icon.html).



