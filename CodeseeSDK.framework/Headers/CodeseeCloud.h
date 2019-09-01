//
//  CodeseeCloud.h
//  CodeseeSDK
//
//  Created by Leo Tang on 2019/1/6.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface CodeseeCloud : NSObject
@property (nonatomic,strong) NSString *account;
-(BOOL) login: (NSString *) myAccount;
-(nullable NSArray<NSDictionary *> *) search:(NSString *) name isFolder: (BOOL) isFolder ownerAccount: (nullable NSString*) ownerAccount;
-(nullable NSArray<NSDictionary *> *) list:(NSString *) folderName ownerAccount: (nullable NSString*) ownerAccount;
-(BOOL) createFolder: (NSString *) folderName parentFolder: (nullable NSString *) parentFolderName;
-(BOOL) deleteFolder: (NSString *) folderName parentFolder: (nullable NSString *) parentFolderName;
-(BOOL) uploadFile:(NSString *) fileName parentFolder:(nullable NSString *) parentFolderName alias: (NSString *) alias;
-(BOOL) updateFile:(nonnull NSDictionary *) fileDescriptor localFile: (nonnull NSString *) localFile;
-(BOOL) downloadFile:(nonnull NSDictionary *) fileDescriptor localFile: (nonnull NSString *) localFile;
-(BOOL) downloadFiles:(nonnull NSString *) folderName localFolder: (nonnull NSString *) localFolder ownerAccount: (nullable NSString*) ownerAccount;
-(BOOL) deleteFile:(nonnull NSDictionary *) fileDescriptor;
-(BOOL) sync;
-(BOOL) stopSync;
-(BOOL) share: (nonnull NSString*) otherAccount folderName: (nonnull NSString *) folderName;
-(BOOL) unshare: (nonnull NSString*) otherAccount folderName: (nonnull NSString *) folderName;
-(nullable NSArray *) getMySharing;
-(nullable NSArray *) getSharedWithMe;
@end

NS_ASSUME_NONNULL_END
