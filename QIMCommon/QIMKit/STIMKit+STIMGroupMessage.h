//
//  STIMKit+STIMGroupMessage.h
//  qunarChatIphone
//
//  Created by 李露 on 2018/4/12.
//

#import "STIMKit.h"

@interface STIMKit (STIMGroupMessage)

- (void)updateLastGroupMsgTime;

- (void)checkGroupChatMsg;

- (void)updateOfflineGroupMessages;

- (NSArray *)getMucMsgListWithGroupId:(NSString *)groupId WithDirection:(int)direction WithLimit:(int)limit WithVersion:(long long)version include:(BOOL)include;

- (void)updateMucReadMark;

@end
