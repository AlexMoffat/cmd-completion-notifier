//
//  AppDelegate.m
//  CmdCompletionNotifier
//
//  Created by Alex Moffat on 10/2/12.
//  Copyright (c) 2012 Alex Moffat. All rights reserved.
//  Licensed under the BSD license. See LICENSE.md for license information.
//

// NOTE - Uses the "Application is background only" flag in the info.plist so that it runs in the background.

// TODO - What happens when you have multiple instances executing at the same time?
// TODO - Shall we have a window to display the notification info if the user clicks on a notification?

#import "AppDelegate.h"

@interface AppDelegate()
@property (nonatomic) NSDateFormatter *dateFormatter;
@end

@implementation AppDelegate

@synthesize dateFormatter = _dateFormatter;

// Keys used in the userInfo dictionary added to the notification.
// (NSString *)
NSString *const CommandWorkingDirectory = @"CWD";
// (NSString *)
NSString *const Command = @"CMD";
// (NSDate *)
NSString *const CommandStartTime = @"CST";
// (NSDate *)
NSString *const CommandEndTime = @"CET";
// (NSNumber *)
NSString *const CommandCompletionStatus = @"CCS";

- (NSDateFormatter *)dateFormatter
{
    if (!_dateFormatter) {
        _dateFormatter = [[NSDateFormatter alloc] init];
        [_dateFormatter setDateStyle:NSDateFormatterMediumStyle];
        [_dateFormatter setTimeStyle:NSDateFormatterMediumStyle];
    }
    return _dateFormatter;
}

- (void)printUsage
{
    const char *appName = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleExecutable"] UTF8String];
    const char *appVersion = [[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleShortVersionString"] UTF8String];
    printf("%s (%s) is a command-line tool to send an OS X User Notification when a command completes\n" \
           "\n" \
           "Usage: %s command to execute\n" \
           "\n" \
           "   Where \"command to execute\" is the series of shell commands you want to run.\n" \
           "   For example \'%s mvn clean install\'\n " \
           "   Chaining commands and notifying when they all complete is not currently supported.\n",
           appName, appVersion, appName, appName);
}

// Create the string representing the command to execute from the arguments passed to the program.
- (NSString *)commandFromArguments:(NSArray *)args
{
    NSUInteger numberOfArgs = [args count];
    NSMutableArray *commandArguments = [NSMutableArray arrayWithCapacity: numberOfArgs];
    // This is used to skip the -NSDocumentRevisionsDebugMode YES arguments added when running
    // under XCode
    BOOL skipNextArgument = NO;
    // Skip args[0], it's the program name
    for (NSUInteger i = 1; i < numberOfArgs; ++i) {
        NSString *currentArgument = [args objectAtIndex:i];
        if ([@"-NSDocumentRevisionsDebugMode" isEqualToString:currentArgument]) {
            skipNextArgument = YES;
        } else if (skipNextArgument) {
            skipNextArgument = NO;
        } else {
            [commandArguments addObject:currentArgument];
        }
    }
    
    return [commandArguments componentsJoinedByString:@" "];
}

// Returned dictionary contains data to configure notification.
- (NSMutableDictionary *)executeCommand:(NSString *)command
{
    
    NSMutableDictionary *dictionary = [NSMutableDictionary dictionary];
    dictionary[CommandWorkingDirectory] = [[NSFileManager defaultManager] currentDirectoryPath];
    dictionary[Command] = command;
    
    NSFileHandle *stdout = [NSFileHandle fileHandleWithStandardOutput];
    NSFileHandle *stderr = [NSFileHandle fileHandleWithStandardError];
    
    NSTask *task = [NSTask new];
    task.launchPath = @"/bin/bash";
    task.arguments = @[@"-c", command];
    task.standardOutput = stdout;
    task.standardError = stderr;    
    
    dictionary[CommandStartTime] = [NSDate date];
    [task launch];
    
    [task waitUntilExit];    
    dictionary[CommandEndTime] = [NSDate date];
    
    dictionary[CommandCompletionStatus] = [NSNumber numberWithUnsignedInteger: [task terminationStatus]];
    
    return dictionary;
}

// Remove all existing notifications that were created by running the same command in the same directory.
- (void)removeExistingNotifications:(NSMutableDictionary *)userInfo
{
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    for (NSUserNotification *userNotification in center.deliveredNotifications) {
        if ([userInfo[Command] isEqualTo:userNotification.userInfo[Command]] && [userInfo[CommandWorkingDirectory] isEqualTo:userNotification.userInfo[CommandWorkingDirectory]]) {
            [center removeDeliveredNotification:userNotification];
        }
    }
}

// Deliver a notification. Values to construct the notification come from the userInfo object.
- (void)deliverNotificationForCommandCompletion:(NSMutableDictionary *)userInfo
{
    int commandStatus = [((NSNumber *)userInfo[CommandCompletionStatus]) intValue];
    NSDate *startTime = userInfo[CommandStartTime];
    NSDate *endTime = userInfo[CommandEndTime];
    NSUInteger elapsed = (NSUInteger)round([endTime timeIntervalSinceDate:startTime]);
    NSString *title = userInfo[Command];
    NSString *informativeText = [NSString stringWithFormat:@"'%@' elapsed %02lu:%02lu:%02lu finished at %@ in directory '%@'", title, elapsed/3600, (elapsed/60)%60, elapsed%60, [self.dateFormatter stringFromDate:userInfo[CommandEndTime]], userInfo[CommandWorkingDirectory]];
    
    NSUserNotification *userNotification = [NSUserNotification new];
    userNotification.title = title;
    userNotification.subtitle = (commandStatus == 0?@"Success":@"Failure");
    userNotification.informativeText = informativeText;
    userNotification.hasActionButton = NO;
    userNotification.userInfo = userInfo;
    
    NSUserNotificationCenter *center = [NSUserNotificationCenter defaultUserNotificationCenter];
    center.delegate = self;
    [center scheduleNotification:userNotification];
}

- (void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
    NSUserNotification *userNotification = aNotification.userInfo[NSApplicationLaunchUserNotificationKey];
    if (userNotification) {
        // We were launched because a notification was clicked on. There's nothing
        // for us to do in this case but log a message.
        NSLog(@"Application launched with notification %@", userNotification.informativeText);
        exit(0);
    } else {
        NSArray *args = [[NSProcessInfo processInfo] arguments];
        
        // Construct the command from the arguments.
        NSString *command = [[self commandFromArguments:args] stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
        
        if ([@"" isEqualToString:command]) {
            // No command so print some usage information.
            [self printUsage];
            exit(1);
        } else {
            // Execute the command.
            NSMutableDictionary *result = [self executeCommand:command];
            
            // Remove existing notifications for the same command.
            [self removeExistingNotifications:result];
            
            // Send appropriate notification.
            [self deliverNotificationForCommandCompletion:result];
            
            // Exit with the status of the command we executed.
            exit([((NSNumber *)result[CommandCompletionStatus]) intValue]);
        }
    }
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didActivateNotification:(NSUserNotification *)notification
{
    // Nothing for us to do here. It is unlikely that this application is going to be running when a user
    // clicks on a notification. However, in case it is we will log a message like we don in aplicationDidFinishLaunching
    NSLog(@"Notification activated %@", notification.informativeText);
}

- (void)userNotificationCenter:(NSUserNotificationCenter *)center didDeliverNotification:(NSUserNotification *)notification
{
    // We don't have anything to do when a notification is delivered.
}

- (BOOL)userNotificationCenter:(NSUserNotificationCenter *)center shouldPresentNotification:(NSUserNotification *)notification
{
    return YES;
}

@end
