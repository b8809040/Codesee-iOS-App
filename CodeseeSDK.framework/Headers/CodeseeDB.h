//
//  CodeseeDB.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/1/4.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

typedef enum _CodeseeDBAction {
    CodeseeDBCreate = 0,
    CodeseeDBUpdate,
    CodeseeDBDelete,
    CodeseeDBCreateFolder,
    CodeseeDBDeleteFolder
} CodeseeDBAction;

@interface CodeseeDB : NSObject
- (BOOL) open: (NSString *) dbFile;
- (void) log: (NSString *) file Action: (CodeseeDBAction) action;
- (void) copyLog: (NSString *) file dateTime: (NSString*) dateTime Action: (CodeseeDBAction) action;
- (NSArray *) query: (NSString *) query;
- (BOOL) close;
@end

NS_ASSUME_NONNULL_END
