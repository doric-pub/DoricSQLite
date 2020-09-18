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
    [registry registerNativePlugin:DoricSQLitePlugin.class withName:@"sqlite"];
}
@end
