// Based on Open in Code by Sertac Ozercan, copyright 2016. See LICENSE.

#if !defined(__arm64__)
#error "These applications require Apple Silicon (arm64). Intel builds are not supported."
#endif

#import <Cocoa/Cocoa.h>
#import "Finder.h"

static NSString *FinderDirectory(void) {
    @try {
        FinderApplication *finder = [SBApplication applicationWithBundleIdentifier:@"com.apple.finder"];
        FinderItem *item = [(NSArray *)[[finder selection] get] firstObject];
        if (item == nil) {
            item = [[[[finder FinderWindows] firstObject] target] get];
        }

        NSString *urlString = item.URL;
        NSURL *url = urlString.length > 0 ? [NSURL URLWithString:urlString] : nil;
        if (url.isFileURL) {
            NSNumber *isAlias = nil;
            [url getResourceValue:&isAlias forKey:NSURLIsAliasFileKey error:NULL];
            if (isAlias.boolValue) {
                NSURL *resolved = [NSURL URLByResolvingAliasFileAtURL:url
                                                            options:NSURLBookmarkResolutionWithoutUI
                                                              error:NULL];
                if (resolved != nil) {
                    url = resolved;
                }
            }

            NSString *path = url.path;
            BOOL isDirectory = NO;
            if ([[NSFileManager defaultManager] fileExistsAtPath:path isDirectory:&isDirectory]) {
                return isDirectory ? path : path.stringByDeletingLastPathComponent;
            }
        }
    } @catch (NSException *exception) {
        NSLog(@"Could not read the Finder folder: %@", exception.reason);
    }

    return NSSearchPathForDirectoriesInDomains(NSDesktopDirectory, NSUserDomainMask, YES).firstObject ?: NSHomeDirectory();
}

int main(void) {
    @autoreleasepool {
        NSString *path = FinderDirectory();
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/open"];
        // Pass the directory as one argument, never as shell source.
#if OPEN_IN_TERMINAL
        task.arguments = @[@"-b", @"com.apple.Terminal", @"--", path];
#else
        task.arguments = @[@"-n", @"-b", @"com.microsoft.VSCode", @"--args", path];
#endif

        NSError *error = nil;
        if ([task launchAndReturnError:&error]) {
            [task waitUntilExit];
            if (task.terminationStatus == 0) {
                return 0;
            }
        }

        [NSApplication sharedApplication];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = [NSString stringWithFormat:@"%@ failed",
                             [NSBundle.mainBundle objectForInfoDictionaryKey:@"CFBundleName"]];
        alert.informativeText = error.localizedDescription ?: @"The destination application could not open the selected folder.";
        [alert runModal];
        return 1;
    }
}
