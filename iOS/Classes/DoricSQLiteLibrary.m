//
//  DoricSQLiteLibrary.m
//  DoricCore
//
//  Created by pengfei.zhou on 2020/9/18.
//

#import "DoricSQLiteLibrary.h"
#import "DoricSQLitePlugin.h"

@implementation DoricSQLiteLibrary
- (void)load:(DoricRegistry *)registry {
    NSString *path = [[NSBundle mainBundle] bundlePath];
    NSString *fullPath = [path stringByAppendingPathComponent:@"bundle_sqlite.js"];
    NSString *jsContent = [NSString stringWithContentsOfFile:fullPath encoding:NSUTF8StringEncoding error:nil];
    [registry registerJSBundle:jsContent withName:@"doric-sqlite"];
    [registry registerNativePlugin:DoricSQLitePlugin.class withName:@"sqlite"];
}
@end
