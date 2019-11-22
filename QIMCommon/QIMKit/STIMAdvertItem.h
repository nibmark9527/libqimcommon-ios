//
//  STIMAdvertItem.h
//  STIMCommon
//
//  Created by 李露 on 2018/4/30.
//  Copyright © 2018年 STIMKit. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "STIMCommonEnum.h"

@interface STIMAdvertItem : NSObject

@property (nonatomic, assign) AdvertType adType;
@property (nonatomic, strong) NSString *adLinkUrl;
@property (nonatomic, strong) NSString *adImgUrl;

@end
