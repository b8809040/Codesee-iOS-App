//
//  CodeseeAuth.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/1/4.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeseeAuth : NSObject
-(id) init;
-(NSString *) authenticate: (NSString *) message;
@end

NS_ASSUME_NONNULL_END
