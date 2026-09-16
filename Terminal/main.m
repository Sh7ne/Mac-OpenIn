#if !defined(__arm64__)
#error "Open in Terminal requires Apple Silicon (arm64). Intel builds are not supported."
#endif

#import <Cocoa/Cocoa.h>
#import "../Finder.h"

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

int main(int argc, const char *argv[]) {
    @autoreleasepool {
        NSString *path = FinderDirectory();
        NSTask *task = [[NSTask alloc] init];
        task.executableURL = [NSURL fileURLWithPath:@"/usr/bin/open"];
        // Terminal accepts directory URLs. Pass the path as one argument;
        // never interpolate a Finder filename into a shell command.
        task.arguments = @[@"-b", @"com.apple.Terminal", @"--", path];

        NSError *error = nil;
        if ([task launchAndReturnError:&error]) {
            [task waitUntilExit];
            if (task.terminationStatus == 0) {
                return 0;
            }
        }

        [NSApplication sharedApplication];
        NSAlert *alert = [[NSAlert alloc] init];
        alert.messageText = @"Could not open Terminal";
        alert.informativeText = error.localizedDescription ?: @"Terminal could not open the selected folder.";
        [alert runModal];
        return 1;
    }
}
