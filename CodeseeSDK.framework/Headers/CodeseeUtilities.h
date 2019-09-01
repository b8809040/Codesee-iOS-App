//
//  CodeseeUtilities.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/1/6.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeseeUtilities : NSObject
+ (NSString *) getDocPath: (NSString *) subPath;
+ (UIImage *) getThumbnail:(NSString *) path;
+ (UIImage *) getUIImage:(NSString *) path;
@end

NS_ASSUME_NONNULL_END
