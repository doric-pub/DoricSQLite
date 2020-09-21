//
//  DoricSQLitePlugin.m
//  Pods-DoricSQLite
//
//  Created by pengfei.zhou on 2020/9/18.
//

#import "DoricSQLitePlugin.h"
#import "DoricSQLiteDatabase.h"

@interface DoricSQLitePlugin ()
@property(nonatomic, copy) NSDictionary *databaseDic;
@property(nonatomic) NSUInteger dbIdCounter;
@end

@implementation DoricSQLitePlugin

- (NSDictionary *)databaseDic {
    if (_databaseDic == nil) {
        _databaseDic = @{};
    }
    return _databaseDic;
}

- (void)open:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    NSString *fileName = args[@"fileName"];
    NSString *path;
    if ([fileName hasPrefix:@"file://"]) {
        path = [fileName substringFromIndex:@"file://".length];
    } else if ([fileName hasPrefix:@"/"]) {
        path = fileName;
    } else {
        NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
        path = [NSString stringWithFormat:@"%@/%@.db", docDir, fileName];
    }
    self.dbIdCounter++;
    NSMutableDictionary *dictionary = self.databaseDic.mutableCopy;
    NSString *dbId = [NSString stringWithFormat:@"%@", @(self.dbIdCounter)];
    dictionary[dbId] = [[DoricSQLiteDatabase alloc] initWithPath:path];
    self.databaseDic = dictionary;
    [promise resolve:dbId];
}

- (void)close:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    NSMutableDictionary *dictionary = self.databaseDic.mutableCopy;
    [dictionary removeObjectForKey:args[@"dbId"]];
    self.databaseDic = dictionary;
    [promise resolve:nil];
}


- (void)execute:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    DoricSQLiteDatabase *database = self.databaseDic[args[@"dbId"]];
    if (database) {
        [database run:^{
            @try {
                [database executeWithStatement:args[@"statement"] parameters:args[@"parameters"]];
                [promise resolve:nil];
            } @catch (NSException *exception) {
                [promise reject:exception.userInfo];
            }

        }];
    } else {
        [promise reject:@"Cannot find database"];
    }
}

- (void)executeUpdateDelete:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    DoricSQLiteDatabase *database = self.databaseDic[args[@"dbId"]];
    if (database) {
        [database run:^{
            @try {
                NSNumber *result = [database executeUpdateDeleteWithStatement:args[@"statement"] parameters:args[@"parameters"]];
                [promise resolve:result];
            } @catch (NSException *exception) {
                [promise reject:exception.userInfo];
            }
        }];
    } else {
        [promise reject:@"Cannot find database"];
    }
}

- (void)executeInsert:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    DoricSQLiteDatabase *database = self.databaseDic[args[@"dbId"]];
    if (database) {
        [database run:^{
            @try {
                NSNumber *result = [database executeInsertWithStatement:args[@"statement"] parameters:args[@"parameters"]];
                [promise resolve:result];
            } @catch (NSException *exception) {
                [promise reject:exception.userInfo];
            }
        }];
    } else {
        [promise reject:@"Cannot find database"];
    }
}

- (void)executeQuery:(NSDictionary *)args withPromise:(DoricPromise *)promise {
    DoricSQLiteDatabase *database = self.databaseDic[args[@"dbId"]];
    if (database) {
        [database run:^{
            @try {
                NSArray *result = [database executeQueryWithStatement:args[@"statement"] parameters:args[@"parameters"]];
                [promise resolve:result];
            } @catch (NSException *exception) {
                [promise reject:exception.userInfo];
            }
        }];
    } else {
        [promise reject:@"Cannot find database"];
    }
}
@end
