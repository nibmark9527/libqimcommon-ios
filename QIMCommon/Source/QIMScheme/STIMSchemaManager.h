//
//  STIMSchemaManager.h
//  STIMCommon
//
//  Created by 李露 on 2018/9/11.
//  Copyright © 2018年 STIMKit. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface STIMSchemaManager : NSObject

+ (instancetype)sharedInstance;

- (BOOL)isLocalSchemaWithUrl:(NSString *)url;

- (void)postSchemaNotificationWithUrl:(NSURL *)url;

@end
