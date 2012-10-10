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

## License

Licensed under the BSD 2-Clause License. See LICENSE.md for details.

The application icons are licensed under the terms of the GNU Lesser General Public License
and are available for download from [the iconarchive here](http://www.iconarchive.com/show/oxygen-icons-by-oxygen-icons.org/Apps-preferences-desktop-notification-icon.html).



