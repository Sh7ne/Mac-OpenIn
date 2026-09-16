// Minimal ScriptingBridge declarations used to read Finder's current folder.
// Derived from the original Finder.h; see README credits.
#import <ScriptingBridge/ScriptingBridge.h>

@interface FinderItem : SBObject
@property (copy, readonly) NSString *URL;
@end

@interface FinderFinderWindow : SBObject
@property (copy) SBObject *target;
@end

@interface FinderApplication : SBApplication
@property (copy) SBObject *selection;
- (SBElementArray<FinderFinderWindow *> *)FinderWindows;
@end
