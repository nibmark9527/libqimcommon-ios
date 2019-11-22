//
//  STIMManager+Collection.m
//  qunarChatIphone
//
//  Created by 李露 on 2018/3/30.
//

#import "STIMManager+Collection.h"

@implementation STIMManager (Collection)

- (NSString *)getCollectionUserHeaderUrlWithXmppId:(NSString *)userId {
    NSDictionary *userInfoDic = [self getCollectionUserInfoByUserId:userId];
    NSString *headerUrl = [userInfoDic objectForKey:@"HeaderSrc"];
    if (![headerUrl stimDB_hasPrefixHttpHeader] && headerUrl.length > 0) {
        headerUrl = [NSString stringWithFormat:@"%@/%@", [[STIMNavConfigManager sharedInstance] innerFileHttpHost], headerUrl];
    }
    return headerUrl;
}

- (NSString *)getCollectionGroupHeaderUrlWithCollectionGroupId:(NSString *)groupId {
    NSDictionary *groupInfoDic = [self getCollectionGroupCardByGroupId:groupId];
    NSString *headerUrl = [groupInfoDic objectForKey:@"HeaderSrc"];
    if (![headerUrl stimDB_hasPrefixHttpHeader] && headerUrl.length > 0) {
        headerUrl = [NSString stringWithFormat:@"%@/%@", [[STIMNavConfigManager sharedInstance] innerFileHttpHost], headerUrl];
    }
    return headerUrl;
}

- (NSDictionary *)getCollectionUserInfoByUserId:(NSString *)myId {
    __block NSDictionary *result = nil;
    
    dispatch_block_t block = ^{
        if (!self.collectionUserVCardDict) {
            self.collectionUserVCardDict = [NSMutableDictionary dictionaryWithCapacity:3];
        }
        NSDictionary *tempDic = [self.collectionUserVCardDict objectForKey:myId];
        if (!tempDic) {
            tempDic = [[IMDataManager stIMDB_SharedInstance] stIMDB_selectCollectionUserByJID:myId];
            if (tempDic) {
                [self.collectionUserVCardDict setSTIMSafeObject:tempDic forKey:myId];
            } else {
                [self updateCollectionUserCardByUserId:myId];
            }
        }
        result = tempDic;
    };
    
    if (dispatch_get_specific(self.cacheTag))
        block();
    else
        dispatch_sync(self.cacheQueue, block);
    return result;
}

/**
 获取代收用户的名片信息
 */
- (void)updateCollectionUserCardByUserIds:(NSArray *)userIds {
    
    if (!userIds) {
        return;
    }
    dispatch_async(self.update_chat_card, ^{
        NSMutableArray *params = [NSMutableArray array];
        //    [{"u":"xuejie.bi", "d":"qunar.com", "v":1}, {"u":"xuejie.bi", "d":"ejabhost1", "v":0}]
        for (NSString *userXmppId in userIds) {
            NSString *userId = [[userXmppId componentsSeparatedByString:@"@"] firstObject];
            NSString *userDomain = [[userXmppId componentsSeparatedByString:@"@"] lastObject];
            [params addObject:@{@"u": userId ? userId : @"", @"d":userDomain ? userDomain : @"", @"v":@(0)}];
        }
        NSData *requestData = [[STIMJSONSerializer sharedInstance] serializeObject:params error:nil];
        NSString *destUrl = [NSString stringWithFormat:@"%@/qtapi/common/collection/getvcard.qunar",[[STIMNavConfigManager sharedInstance] javaurl]];
        NSURL *requestUrl = [[NSURL alloc] initWithString:destUrl];
        
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        NSString *requestHeaders = [NSString stringWithFormat:@"q_ckey=%@", [[STIMManager sharedInstance] thirdpartKeywithValue]];
        [cookieProperties setObject:requestHeaders forKey:@"Cookie"];
        
        STIMHTTPRequest *request = [[STIMHTTPRequest alloc] initWithURL:requestUrl];
        [request setHTTPBody:requestData];
        [request setHTTPRequestHeaders:cookieProperties];
        [request setHTTPMethod:STIMHTTPMethodPOST];
        [STIMHTTPClient sendRequest:request complete:^(STIMHTTPResponse *response) {
            if (response.code == 200) {
                NSData *responseData = response.data;
                NSDictionary *result = [[STIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
                BOOL ret = [[result objectForKey:@"ret"] boolValue];
                if (ret) {
                    NSArray *list = [result objectForKey:@"data"];
                    if (list.count > 0) {
                        [[IMDataManager stIMDB_SharedInstance] stIMDB_bulkInsertCollectionUserCards:list];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:kCollectionUserVCardUpdate object:userIds];
                        });
                    }
                }
            }
        } failure:^(NSError *error) {
            
        }];
    });
}


- (void)updateCollectionUserCardByUserId:(NSString *)userId {
    
    if (!userId) {
        return;
    }
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_BACKGROUND, 0), ^{
        
        [self updateCollectionUserCardByUserIds:@[userId]];
    });
}

//存储代收消息
- (void)saveCollectionMessage:(NSDictionary *)collectionMsgDic {
    [[IMDataManager stIMDB_SharedInstance] stIMDB_bulkInsertCollectionMsgWithMsgDics:@[collectionMsgDic]];
}

- (STIMMessageModel *)getCollectionMessageModelWithByDBMsgDic:(NSDictionary *)dbMsgDic {
    /*
     [IMDataManager safeSaveForDic:msgDic setObject:msgId forKey:@"MsgId"];
     [IMDataManager safeSaveForDic:msgDic setObject:originfrom forKey:@"OriginFrom"];
     [IMDataManager safeSaveForDic:msgDic setObject:originto forKey:@"OriginTo"];
     [IMDataManager safeSaveForDic:msgDic setObject:originChatType forKey:@"OriginChatType"];
     [IMDataManager safeSaveForDic:msgDic setObject:xmppId forKey:@"XmppId"];
     [IMDataManager safeSaveForDic:msgDic setObject:platform forKey:@"Platform"];
     [IMDataManager safeSaveForDic:msgDic setObject:from forKey:@"From"];
     [IMDataManager safeSaveForDic:msgDic setObject:to forKey:@"To"];
     [IMDataManager safeSaveForDic:msgDic setObject:content forKey:@"Content"];
     [IMDataManager safeSaveForDic:msgDic setObject:extendInfo forKey:@"ExtendInfo"];
     [IMDataManager safeSaveForDic:msgDic setObject:msgType forKey:@"MsgType"];
     [IMDataManager safeSaveForDic:msgDic setObject:state forKey:@"MsgState"];
     [IMDataManager safeSaveForDic:msgDic setObject:direction forKey:@"MsgDirection"];
     [IMDataManager safeSaveForDic:msgDic setObject:contentResolve forKey:@"ContentResolve"];
     [IMDataManager safeSaveForDic:msgDic setObject:readState forKey:@"ReadState"];
     [IMDataManager safeSaveForDic:msgDic setObject:msgDateTime forKey:@"MsgDateTime"];
     [IMDataManager safeSaveForDic:msgDic setObject:messageRaw forKey:@"MessageRaw"];
     [IMDataManager safeSaveForDic:msgDic setObject:realJid forKey:@"RealJid"];
     */
    NSString *msgId = [dbMsgDic objectForKey:@"MsgId"];
    NSString *originFrom = [dbMsgDic objectForKey:@"OriginFrom"];
    NSString *originTo = [dbMsgDic objectForKey:@"OriginTo"];
    NSString *originChatType = [dbMsgDic objectForKey:@"OriginChatType"];
    NSString *xmppId = [dbMsgDic objectForKey:@"XmppId"];
    IMPlatform platform = [[dbMsgDic objectForKey:@"Platform"] integerValue];
    NSString *from = [dbMsgDic objectForKey:@"From"];
    NSString *to = [dbMsgDic objectForKey:@"To"];
    NSString *content = [dbMsgDic objectForKey:@"Content"];
    NSString *extendInfo = [dbMsgDic objectForKey:@"ExtendInfo"];
    STIMMessageType msgType = [[dbMsgDic objectForKey:@"MsgType"] integerValue];
    STIMMessageSendState sendState = [[dbMsgDic objectForKey:@"MsgState"] integerValue];
    STIMMessageDirection msgDirection = [[dbMsgDic objectForKey:@"MsgDirection"] integerValue];
    NSString *contentResolve = [dbMsgDic objectForKey:@"ContentResolve"];
    STIMMessageRemoteReadState readState = [[dbMsgDic objectForKey:@"ReadState"] integerValue];
    long long msgDateTime = [[dbMsgDic objectForKey:@"MsgDateTime"] longLongValue];
    id msgRaw = [dbMsgDic objectForKey:@"MsgRaw"];
    NSString *realJid = [dbMsgDic objectForKey:@"RealJid"];
    
    STIMMessageModel *msgModel = [STIMMessageModel new];
    msgModel.messageId = msgId;
    msgModel.xmppId = xmppId;
    msgModel.platform = platform;
    msgModel.from = from;
    msgModel.to = to;
    msgModel.message = content;
    msgModel.extendInformation = extendInfo;
    msgModel.messageType = msgType;
    msgModel.chatType = originChatType;
    msgModel.messageSendState = sendState;
    msgModel.messageDirection = msgDirection;
    msgModel.messageReadState = readState;
    msgModel.messageDate = msgDateTime;
    msgModel.msgRaw = msgRaw;
    msgModel.realJid = realJid;
    return msgModel;
}

- (STIMMessageModel *)getCollectionMsgListForMsgId:(NSString *)msgId {
    NSDictionary *infoDic = [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgListForMsgId:msgId];
    if (infoDic) {
        return [self getCollectionMessageModelWithByDBMsgDic:infoDic];
    }
    return nil;
}

- (NSArray *)getCollectionMsgListForUserId:(NSString *)userId originUserId:(NSString *)originUserId {
    NSArray *array = [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgListWithUserId:userId originUserId:originUserId];
    NSMutableArray *list = [NSMutableArray array];
    if (array.count > 0) {
        for (NSDictionary *infoDic in array) {
            STIMMessageModel *msg = [self getCollectionMessageModelWithByDBMsgDic:infoDic];
            [list addObject:msg];
        }
    }
    return list;
}

- (NSDictionary *)getLastCollectionMsgByMsgId:(NSString *)lastMsgId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getLastCollectionMsgWithLastMsgId:lastMsgId];
}

/**
 获取某绑定账号下的代收列表
 
 @param bindId 绑定账号
 */
- (NSArray *)getCollectionSessionListWithBindId:(NSString *)bindId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionSessionListWithBindId:bindId];
}

/**
 获取某绑定账号下的代收消息
 
 @param bindId 绑定账号
 */
- (NSArray *)getCollectionMsgListWithBindId:(NSString *)bindId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgListWithBindId:bindId];
}

/**
 获取已代收账号列表
 
 @return 已代收账号列表
 */
- (NSArray *)getMyCollectionAccountList {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionAccountList];
}

/**
 获取我的绑定账号列表
 */
- (void)getRemoteCollectionAccountList {
    NSString *javaUrl = [[STIMNavConfigManager sharedInstance] javaurl];
    if (javaUrl.length > 0) {
        NSString *getCollectionAccountUrl = [NSString stringWithFormat:@"%@/qtapi/common/collection/get.qunar", javaUrl];
        STIMHTTPRequest *request = [[STIMHTTPRequest alloc] initWithURL:[NSURL URLWithString:getCollectionAccountUrl]];
        [request setUseCookiePersistence:NO];
        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        NSString *requestHeaders = [NSString stringWithFormat:@"q_ckey=%@", [[STIMManager sharedInstance] thirdpartKeywithValue]];
        [cookieProperties setObject:requestHeaders forKey:@"Cookie"];
        [request setHTTPRequestHeaders:cookieProperties];
        
        [STIMHTTPClient sendRequest:request complete:^(STIMHTTPResponse *response) {
            if (response.code == 200) {
                NSDictionary *result = [[STIMJSONSerializer sharedInstance] deserializeObject:response.data error:nil];
                BOOL ret = [[result objectForKey:@"ret"] boolValue];
                if (ret) {
                    NSArray *data = [result objectForKey:@"data"];
                    if (data.count > 0) {
                        [[IMDataManager stIMDB_SharedInstance] stIMDB_bulkinsertCollectionAccountList:data];
                        [[IMDataManager stIMDB_SharedInstance] stIMDB_bulkInsertCollectionUserCards:data];
                        dispatch_async(dispatch_get_main_queue(), ^{
                            [[NSNotificationCenter defaultCenter] postNotificationName:@"updateCollectionMsgList" object:nil userInfo:nil];
                        });
                    }
                }
            }
        } failure:^(NSError *error) {
            
        }];
    }
}

/**
 根据Jid清空代收未读消息
 
 @param jid Jid
 */
- (void)clearNotReadCollectionMsgByJid:(NSString *)jid {
    [[IMDataManager stIMDB_SharedInstance] stIMDB_updateCollectionMsgNotReadStateByJid:jid WithReadtate:STIMMessageRemoteReadStateDidReaded];
//    [[IMDataManager stIMDB_SharedInstance] stIMDB_updateCollectionMsgNotReadStateByJid:jid WithMsgState:MessageState_didRead];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *xmppId = [NSString stringWithFormat:@"collection_rbt@%@", [self getDomain]];
        [self.notReadMsgDic removeObjectForKey:xmppId];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMsgNotReadCountChange object:@{@"XmppId":xmppId}];
    });
}

/**
 根据绑定账号 & 用户Id清空代收 未读消息
 
 @param bindId 绑定账号Id
 @param userId 用户Id
 */
- (void)clearNotReadCollectionMsgByBindId:(NSString *)bindId WithUserId:(NSString *)userId {
    [[IMDataManager stIMDB_SharedInstance] stIMDB_updateCollectionMsgNotReadStateForBindId:bindId originUserId:userId WithReadState:STIMMessageRemoteReadStateDidReaded];
    dispatch_async(dispatch_get_main_queue(), ^{
        NSString *xmppId = [NSString stringWithFormat:@"collection_rbt@%@", [self getDomain]];
        [self.notReadMsgDic removeObjectForKey:xmppId];
        [[NSNotificationCenter defaultCenter] postNotificationName:kMsgNotReadCountChange object:@{@"XmppId":xmppId}];
    });
}

/**
 获取代收总未读消息数
 */
- (NSInteger)getNotReadCollectionMsgCount {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgNotReadCountByDidReadState:STIMMessageRemoteReadStateDidReaded];
}

/**
 获取某绑定账号下的代收未读消息数
 
 @param bindId 绑定账号Id
 */
- (NSInteger)getNotReadCollectionMsgCountByBindId:(NSString *)bindId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgNotReadCountByDidReadState:STIMMessageRemoteReadStateDidReaded ForBindId:bindId];
}

/**
 获取某绑定账号下 单一账号来的代收 未读消息
 
 @param bindId 绑定账号Id
 @param userId 用户Id
 */
- (NSInteger)getNotReadCollectionMsgCountByBindId:(NSString *)bindId WithUserId:(NSString *)userId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionMsgNotReadCountgetCollectionMsgNotReadCountByDidReadState:STIMMessageRemoteReadStateDidReaded ForBindId:bindId originUserId:userId];
}

#pragma mark - 代收Group

- (NSDictionary *)getCollectionGroupCardByGroupId:(NSString *)groupId {
    return [[IMDataManager stIMDB_SharedInstance] stIMDB_getCollectionGroupCardByGroupId:groupId];
}

- (void)updateCollectionGroupCardByGroupId:(NSString *)groupId {
    
    if (!groupId) {
        return;
    }
    dispatch_async(self.update_chat_card, ^{

        [self updateCollectionGroupCard:@[groupId]];
    });
}

// 获取代收聊天室vcard信息
- (void)updateCollectionGroupCard:(NSArray *)groupIds {
    if (groupIds.count <= 0) {
        return;
    }
    dispatch_async(self.update_chat_card, ^{

        NSMutableArray *params = [NSMutableArray array];
        for (NSString *groupId in groupIds) {
            [params addObject:@{@"m": groupId ? groupId : @"", @"v":@(0)}];
        }
        NSData *requestData = [[STIMJSONSerializer sharedInstance] serializeObject:params error:nil];
        NSString *destUrl = [NSString stringWithFormat:@"%@/qtapi/common/collection/getmucvcard.qunar",[[STIMNavConfigManager sharedInstance] javaurl]];
        NSURL *requestUrl = [[NSURL alloc] initWithString:destUrl];

        NSMutableDictionary *cookieProperties = [NSMutableDictionary dictionary];
        NSString *requestHeaders = [NSString stringWithFormat:@"q_ckey=%@", [[STIMManager sharedInstance] thirdpartKeywithValue]];
        [cookieProperties setObject:requestHeaders forKey:@"Cookie"];
        
        STIMHTTPRequest *request = [[STIMHTTPRequest alloc] initWithURL:requestUrl];
        [request setHTTPMethod:STIMHTTPMethodPOST];
        [request setHTTPBody:[NSMutableData dataWithData:requestData]];
        [request setHTTPRequestHeaders:cookieProperties];
        
        [STIMHTTPClient sendRequest:request complete:^(STIMHTTPResponse *response) {
            if (response.code) {
                dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{
                    NSData *responseData = response.data;
                    NSDictionary *result = [[STIMJSONSerializer sharedInstance] deserializeObject:responseData error:nil];
                    BOOL ret = [[result objectForKey:@"ret"] boolValue];
                    if (ret) {
                        NSArray *list = [result objectForKey:@"data"];
                        if (list.count > 0) {
                            [[IMDataManager stIMDB_SharedInstance] stIMDB_bulkInsertCollectionGroupCards:list];
                            dispatch_async(dispatch_get_main_queue(), ^{
                                [[NSNotificationCenter defaultCenter] postNotificationName:kCollectionGroupNickNameChanged object:groupIds];
                            });
                        }
                    }
                });
            }
        } failure:^(NSError *error) {
            
        }];
    });
}

@end
