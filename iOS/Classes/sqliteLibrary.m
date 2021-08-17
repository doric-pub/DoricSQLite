#import "sqliteLibrary.h"
#import "DoricDemoPlugin.h"

@implementation sqliteLibrary
- (void)load:(DoricRegistry *)registry {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *fullPath = [path stringByAppendingPathComponent:@"bundle_sqlite.js"];
    NSString *jsContent = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    [registry registerJSBundle:jsContent withName:@"sqlite"];
    [registry registerNativePlugin:DoricDemoPlugin.class withName:@"demoPlugin"];
}
@end