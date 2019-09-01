//
//  CodeseeMetadata.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/1/4.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeseeMetadata : NSObject <NSSecureCoding>
-(NSString *) getData: (NSString *) key;
-(void) setData: (NSString *) key Value: (NSString *) value;
-(void) addImage: (NSString *) filename;
-(void) removeImage: (NSString *) filename;
-(NSArray *) getImages;
@end

NS_ASSUME_NONNULL_END
