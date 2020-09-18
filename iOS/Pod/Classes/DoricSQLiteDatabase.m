//
//  DoricSQLiteDatabase.m
//  DoricSQLite
//
//  Created by pengfei.zhou on 2020/9/18.
//

#import "DoricSQLiteDatabase.h"
#import "sqlite3.h"
#import "DoricExtensions.h"

@interface DoricSQLiteDatabase ()
@property(nonatomic) sqlite3 *db;
@property(nonatomic, strong) dispatch_queue_t mapQueue;
@end

@implementation DoricSQLiteDatabase
- (instancetype)initWithPath:(NSString *)path {
    if (self = [super init]) {
        const char *name = path.UTF8String;
        sqlite3 *db;
        if (sqlite3_open_v2(name, &db, SQLITE_OPEN_READWRITE | SQLITE_OPEN_CREATE, NULL) != SQLITE_OK) {

        } else {
            self.db = db;
        }
        _mapQueue = dispatch_queue_create("doric.contextmap", DISPATCH_QUEUE_SERIAL);
    }
    return self;
}

- (void)run:(dispatch_block_t)block {
    dispatch_async(self.mapQueue, block);
};

- (NSDictionary *)innerExecuteWithStatement:(NSString *)sql parameters:(NSArray *)arguments {
    sqlite3_stmt *statement;
    BOOL keepGoing = YES;
    NSDictionary *error = nil;
    if (sqlite3_prepare_v2(self.db, sql.UTF8String, -1, &statement, NULL) != SQLITE_OK) {
        error = [DoricSQLiteDatabase captureSQLiteErrorFromDb:self.db];
        keepGoing = NO;
    } else if (arguments && arguments.count > 0) {
        [arguments forEachIndexed:^(id obj, NSUInteger idx) {
            if ([obj isEqual:[NSNull null]]) {
                sqlite3_bind_null(statement, (int) idx + 1);
            } else if ([obj isKindOfClass:[NSNumber class]]) {
                NSNumber *numberArg = (NSNumber *) obj;
                const char *numberType = [numberArg objCType];
                if (strcmp(numberType, @encode(int)) == 0) {
                    sqlite3_bind_int(statement, (int) idx + 1, (int) [numberArg integerValue]);
                } else if (strcmp(numberType, @encode(long long int)) == 0) {
                    sqlite3_bind_int64(statement, (int) idx + 1, [numberArg longLongValue]);
                } else if (strcmp(numberType, @encode(double)) == 0) {
                    sqlite3_bind_double(statement, (int) idx + 1, [numberArg doubleValue]);
                } else {
                    sqlite3_bind_text(statement, (int) idx + 1, [[obj description] UTF8String], -1, SQLITE_TRANSIENT);
                }
            } else {
                NSString *stringArg;

                if ([obj isKindOfClass:[NSString class]]) {
                    stringArg = (NSString *) obj;
                } else {
                    stringArg = [obj description]; // convert to text
                }
                NSData *data = [stringArg dataUsingEncoding:NSUTF8StringEncoding];
                sqlite3_bind_text(statement, (int) idx + 1, data.bytes, (int) data.length, SQLITE_TRANSIENT);
            }
        }];
    }
    int result, i, column_type, count;
    NSMutableDictionary *entry;
    NSObject *columnValue;
    NSString *columnName;
    NSMutableArray *resultRows = [NSMutableArray arrayWithCapacity:0];
    NSNumber *insertId;
    NSNumber *rowsAffected;

    int previousRowsAffected = sqlite3_total_changes(self.db);
    int nowRowsAffected, diffRowsAffected;
    while (keepGoing) {
        result = sqlite3_step(statement);
        switch (result) {
            case SQLITE_ROW:
                i = 0;
                entry = [NSMutableDictionary dictionaryWithCapacity:0];
                count = sqlite3_column_count(statement);
                while (i < count) {
                    columnName = [NSString stringWithFormat:@"%s", sqlite3_column_name(statement, i)];
                    column_type = sqlite3_column_type(statement, i);
                    switch (column_type) {
                        case SQLITE_INTEGER:
                            columnValue = @(sqlite3_column_int64(statement, i));
                            break;
                        case SQLITE_FLOAT:
                            columnValue = @(sqlite3_column_double(statement, i));
                            break;
                        case SQLITE_BLOB:
                            columnValue = [DoricSQLiteDatabase getBlobAsBase64String:sqlite3_column_blob(statement, i)
                                                                          withLength:(NSUInteger) sqlite3_column_bytes(statement, i)];
                            break;
                        case SQLITE_TEXT:
                            columnValue = [[NSString alloc] initWithBytes:sqlite3_column_text(statement, i)
                                                                   length:(NSUInteger) sqlite3_column_bytes(statement, i)
                                                                 encoding:NSUTF8StringEncoding];
                            break;
                        case SQLITE_NULL:
                        default:
                            columnValue = [NSNull null];
                            break;
                    }

                    if (columnValue) {
                        entry[columnName] = columnValue;
                    }
                    i++;
                }
                [resultRows addObject:entry];
                break;

            case SQLITE_DONE:
                nowRowsAffected = sqlite3_total_changes(self.db);
                diffRowsAffected = nowRowsAffected - previousRowsAffected;
                rowsAffected = @(diffRowsAffected);
                sqlite3_int64 nowInsertId = sqlite3_last_insert_rowid(self.db);
                if (nowRowsAffected > 0 && nowInsertId != 0) {
                    insertId = @(sqlite3_last_insert_rowid(self.db));
                }
                keepGoing = NO;
                break;
            default:
                error = [DoricSQLiteDatabase captureSQLiteErrorFromDb:self.db];
                keepGoing = NO;
        }
    }
    sqlite3_finalize(statement);
    NSMutableDictionary *dictionary = [NSMutableDictionary new];
    if (error) {
        dictionary[@"error"] = error;
    }
    if (resultRows) {
        dictionary[@"resultRows"] = resultRows;
    }
    if (insertId) {
        dictionary[@"insertId"] = insertId;
    }
    if (rowsAffected) {
        dictionary[@"rowsAffected"] = rowsAffected;
    }
    return dictionary;
}

- (void)executeWithStatement:(NSString *)sql parameters:(NSArray *)arguments {
    NSDictionary *result = [self innerExecuteWithStatement:sql parameters:arguments];
    NSDictionary *error = result[@"error"];
    if (error) {
        @throw [[NSException alloc] initWithName:@"DoricSQLite" reason:@"executeWithStatement" userInfo:error];
    }
}


- (NSNumber *)executeUpdateDeleteWithStatement:(NSString *)sql parameters:(NSArray *)arguments {
    NSDictionary *result = [self innerExecuteWithStatement:sql parameters:arguments];
    NSDictionary *error = result[@"error"];
    if (error) {
        @throw [[NSException alloc] initWithName:@"DoricSQLite" reason:@"executeUpdateDeleteWithStatement" userInfo:error];
    }
    return result[@"rowsAffected"];
}


- (NSNumber *)executeInsertWithStatement:(NSString *)sql parameters:(NSArray *)arguments {
    NSDictionary *result = [self innerExecuteWithStatement:sql parameters:arguments];
    NSDictionary *error = result[@"error"];
    if (error) {
        @throw [[NSException alloc] initWithName:@"DoricSQLite" reason:@"executeInsertWithStatement" userInfo:error];
    }
    return result[@"insertId"];
}

- (NSArray *)executeQueryWithStatement:(NSString *)sql parameters:(NSArray *)arguments {
    NSDictionary *result = [self innerExecuteWithStatement:sql parameters:arguments];
    NSDictionary *error = result[@"error"];
    if (error) {
        @throw [[NSException alloc] initWithName:@"DoricSQLite" reason:@"executeQueryWithStatement" userInfo:error];
    }
    return result[@"resultRows"];
}

- (void)dealloc {
    if (self.db) {
        sqlite3_close_v2(self.db);
    }
}


+ (NSDictionary *)captureSQLiteErrorFromDb:(struct sqlite3 *)db {
    int code = sqlite3_errcode(db);
    int extendedCode = sqlite3_extended_errcode(db);
    const char *message = sqlite3_errmsg(db);
    NSMutableDictionary *error = [NSMutableDictionary dictionaryWithCapacity:4];
    error[@"code"] = @(code);
    error[@"message"] = [NSString stringWithUTF8String:message];

    error[@"sqliteCode"] = @(code);
    error[@"sqliteExtendedCode"] = @(extendedCode);
    error[@"sqliteMessage"] = [NSString stringWithUTF8String:message];
    return error;
}

+ (NSString *)getBlobAsBase64String:(const char *)blob_chars
                         withLength:(NSUInteger)blob_length {
    NSData *data = [NSData dataWithBytes:blob_chars length:blob_length];
    NSString *result = [data base64EncodedStringWithOptions:0];
    return result;
}
@end
