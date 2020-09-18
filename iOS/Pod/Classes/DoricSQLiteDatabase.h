//
//  DoricSQLiteDatabase.h
//  DoricSQLite
//
//  Created by pengfei.zhou on 2020/9/18.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface DoricSQLiteDatabase : NSObject
- (instancetype)initWithPath:(NSString *)path;

- (void)run:(dispatch_block_t)block;

- (void)executeWithStatement:(NSString *)sql parameters:(NSArray *)arguments;

- (NSNumber *)executeUpdateDeleteWithStatement:(NSString *)sql parameters:(NSArray *)arguments;

- (NSNumber *)executeInsertWithStatement:(NSString *)sql parameters:(NSArray *)arguments;

- (NSArray *)executeQueryWithStatement:(NSString *)sql parameters:(NSArray *)arguments;
@end

NS_ASSUME_NONNULL_END
