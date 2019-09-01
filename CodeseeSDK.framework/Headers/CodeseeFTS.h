//
//  CodeseeFTS.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/3/29.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeseeFTS : NSObject
- (BOOL) open: (NSString *) dbFile;
- (BOOL) addNote:(NSString*) qrcode note:(NSString *)note;
- (BOOL) updateNote:(NSString*) qrcode note:(NSString *)note;
- (BOOL) removeNote: (NSString *) qrcode;
- (NSArray *) search: (NSString *) searchText;
- (BOOL) close;
@end

NS_ASSUME_NONNULL_END
