//
//  GoogleCloud.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/18.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "GoogleCloud.h"

@interface GoogleCloud()
{
    dispatch_queue_t queue;
    BOOL done;
    BOOL result;
    NSMutableArray *resultArray;
}
@end

@implementation GoogleCloud
-(BOOL) login: (NSString *) myAccount
{
    BOOL retVal = NO;
    
    do {
        if(myAccount == nil) {
            break;
        }
        
        self.account = [[myAccount copy] componentsSeparatedByString:@"@"][0];
        
        retVal = YES;
    } while(false);
    
    return retVal;
}

-(nullable NSArray<NSDictionary *> *) search:(NSString *) name isFolder: (BOOL) isFolder ownerAccount: (nullable NSString*) ownerAccount
{
    [self->resultArray removeAllObjects];
    self->done = NO;
    
    NSMutableString *queryStr = [[NSMutableString alloc] init];
    [queryStr appendFormat: @"name = '%@' and trashed = false", name];
    if(isFolder) {
        [queryStr appendString: @" and mimeType='application/vnd.google-apps.folder'"];
    }
    if(ownerAccount != nil) {
        [queryStr appendFormat: @" and '%@@gmail.com' in owners", ownerAccount];
    }
    NSLog(@"query string:%@", queryStr);
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    query.q = [queryStr copy];
    query.spaces = @"drive";
    query.fields = @"nextPageToken, files(id, name, owners)";
    [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                         GTLRDrive_FileList *files,
                                                         NSError *error) {
        if (error == nil) {
            if(files.files.count > 0) {
                for(GTLRDrive_File *file in files) {
                    NSDictionary *item = @{@"fileId":file.identifier, @"ownerId":[file.owners[0].emailAddress componentsSeparatedByString:@"@"][0], @"filename": file.name};
                    [self->resultArray addObject: item];
                    NSLog(@"File ID %@", file.identifier);
                    NSLog(@"File owners %@", [file.owners[0].emailAddress componentsSeparatedByString:@"@"][0]);
                    NSLog(@"File name %@", file.name);
                }
            }
        } else {
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];
    
    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
    
    self->done = NO;
    
    if([self->resultArray count] > 0) {
        NSArray *tmpArray = [self->resultArray copy];
        [self->resultArray removeAllObjects];
        return tmpArray;
    } else {
        return nil;
    }
}

-(nullable NSArray<NSDictionary *> *) list:(NSString *) folderName ownerAccount: (nullable NSString*) ownerAccount
{
    [self->resultArray removeAllObjects];
    self->done = NO;
    
    NSArray *searchResult = [self search: folderName isFolder: YES ownerAccount: ownerAccount];
    
    NSMutableString *queryStr = [[NSMutableString alloc] init];
    [queryStr appendFormat: @"'%@' in parents and trashed = false", searchResult[0][@"fileId"]];
    if(ownerAccount != nil) {
        [queryStr appendFormat: @" and '%@@gmail.com' in owners", ownerAccount];
    }
    NSLog(@"query string:%@", queryStr);
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    query.q = [queryStr copy];
    query.spaces = @"drive";
    query.fields = @"nextPageToken, files(id, name, owners)";
    [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                         GTLRDrive_FileList *files,
                                                         NSError *error) {
        if (error == nil) {
            if(files.files.count > 0) {
                for(GTLRDrive_File *file in files) {
                    NSDictionary *item = @{@"fileId":file.identifier, @"ownerId":[file.owners[0].emailAddress componentsSeparatedByString:@"@"][0], @"filename": file.name};
                    [self->resultArray addObject: item];
                    NSLog(@"File ID %@", file.identifier);
                    NSLog(@"File owners %@", [file.owners[0].emailAddress componentsSeparatedByString:@"@"][0]);
                    NSLog(@"File name %@", file.name);
                }
            }
        } else {
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];
    
    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
    
    self->done = NO;
    
    if([self->resultArray count] > 0) {
        NSArray *tmpArray = [self->resultArray copy];
        [self->resultArray removeAllObjects];
        return tmpArray;
    } else {
        return nil;
    }
}

-(BOOL) createFolder:(NSString *) folderName parentFolder:(nullable NSString *)parentFolderName
{
    self->result = NO;
    self->done = NO;
    
    do {
        if(folderName == nil) {
            break;
        }

        NSArray *searchResult = [self search: folderName isFolder: YES ownerAccount: self.account];
        if(searchResult != nil) {
            break;
        }

        GTLRDrive_File *folderObj = [GTLRDrive_File object];
        folderObj.name = folderName;
        folderObj.mimeType = @"application/vnd.google-apps.folder";
        
        if(parentFolderName != nil) {
            NSArray *searchResult = [self search: parentFolderName isFolder: YES ownerAccount: self.account];
            if(searchResult == nil) {
                break;
            }
            folderObj.parents = [NSArray arrayWithObject: searchResult[0][@"fileId"]];
        }
        
        GTLRDriveQuery_FilesCreate *query = [GTLRDriveQuery_FilesCreate queryWithObject:folderObj
                                                                       uploadParameters:nil];
        query.fields = @"id";
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             GTLRDrive_File *file,
                                                             NSError *error) {
            if (error == nil) {
                NSLog(@"File ID %@", file.identifier);
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];
        
        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
        
    } while(false);
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) deleteFolder:(NSString *) folderName parentFolder:(nullable NSString *)parentFolderName
{
    self->result = NO;
    self->done = NO;

    do {
        if(folderName == nil) {
            break;
        }

        NSArray *searchResult = [self search: folderName isFolder: YES ownerAccount: self.account];
        if(searchResult == nil) {
            break;
        }

        GTLRDriveQuery_FilesDelete *query = [GTLRDriveQuery_FilesDelete queryWithFileId: searchResult[0][@"fileId"]];
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             GTLRDrive_File *file,
                                                             NSError *error) {
            if (error == nil) {
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];

        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};

    } while(false);

    BOOL result = self->result;
    self->done = NO;
    self->result = NO;

    return result;
}

-(BOOL) uploadFile:(NSString *) fileName parentFolder:(nullable NSString *)parentFolderName alias: (NSString *) alias
{
    self->result = NO;
    self->done = NO;
    
    do {
        if(fileName == nil) {
            break;
        }
        
        NSData *fileData = [[NSFileManager defaultManager] contentsAtPath: fileName];
        
        GTLRDrive_File *fileObj = [GTLRDrive_File object];
        fileObj.name = [alias copy];
        
        if(parentFolderName != nil) {
            NSArray *searchResult = [self search: parentFolderName isFolder: YES ownerAccount: self.account];
            if(searchResult == nil) {
                break;
            }
            fileObj.parents = [NSArray arrayWithObject: searchResult[0][@"fileId"]];
        }
        
        GTLRUploadParameters *uploadParameters = [GTLRUploadParameters uploadParametersWithData:fileData MIMEType:@"text/plain"];
        uploadParameters.shouldUploadWithSingleRequest = TRUE;
        
        GTLRDriveQuery_FilesCreate *query = [GTLRDriveQuery_FilesCreate queryWithObject:fileObj
                                                                       uploadParameters:uploadParameters];
        query.fields = @"id";
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             GTLRDrive_File *file,
                                                             NSError *error) {
            if (error == nil) {
                NSLog(@"File ID %@", file.identifier);
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];
        
        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
        
    } while(false);
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) updateFile:(nonnull NSDictionary *) fileDescriptor localFile: (nonnull NSString *) localFile
{
    self->result = NO;
    self->done = NO;
    
    do {
        NSData *fileData = [[NSFileManager defaultManager] contentsAtPath: localFile];
        
        GTLRDrive_File *fileObj = [GTLRDrive_File object];
        fileObj.trashed = @NO;
        
        GTLRUploadParameters *uploadParameters = [GTLRUploadParameters uploadParametersWithData:fileData MIMEType:@"text/plain"];
        uploadParameters.shouldUploadWithSingleRequest = TRUE;
        
        GTLRDriveQuery *query = [GTLRDriveQuery_FilesUpdate queryWithObject: fileObj
                                                                     fileId: fileDescriptor[@"fileId"]
                                                           uploadParameters: uploadParameters];
        
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             GTLRDataObject *file,
                                                             NSError *error) {
            if (error == nil) {
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];
        
        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
        
    } while(false);
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) downloadFile:(nonnull NSDictionary *) fileDescriptor localFile: (nonnull NSString *) localFile
{
    self->result = NO;
    self->done = NO;
    
    do {
        GTLRQuery *query = [GTLRDriveQuery_FilesGet queryForMediaWithFileId: fileDescriptor[@"fileId"]];
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             GTLRDataObject *file,
                                                             NSError *error) {
            if (error == nil) {
                NSLog(@"Downloaded %lu bytes", file.data.length);
                [file.data writeToFile: localFile atomically:YES];
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];
        
        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
        
    } while(false);
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) downloadFiles:(nonnull NSString *) folderName localFolder: (nonnull NSString *) localFolder ownerAccount: (nullable NSString*) ownerAccount
{
    do {
        NSArray *files = [self list: folderName ownerAccount: ownerAccount];
        for(NSDictionary *file in files) {
            NSDictionary *param = @{@"fileId": file[@"fileId"], @"filename": file[@"filename"]};
            [self downloadFile: param localFile: [localFolder stringByAppendingFormat: @"/%@", file[@"filename"]]];
        }
    } while(false);
    
    return result;
}

-(BOOL) deleteFile:(nonnull NSDictionary *) fileDescriptor
{
    self->result = NO;
    self->done = NO;
    
    do {
        GTLRDriveQuery_FilesDelete *query = [GTLRDriveQuery_FilesDelete queryWithFileId:fileDescriptor[@"fileId"]];
        [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                             id nilObject,
                                                             NSError *error) {
            if (error == nil) {
                NSLog(@"deleted");
                self->result = YES;
            } else {
                NSLog(@"An error occurred: %@", error);
            }
            self->done = YES;
        }];
        
        while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
        
    } while(false);
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) share: (nonnull NSString*) otherAccount folderName: (nonnull NSString *) folderName
{
    self->result = NO;
    self->done = NO;
    
    NSArray *searchResult = [self search: folderName isFolder: YES ownerAccount: self.account];
    NSLog(@"searchResult:%@", searchResult);
    
    GTLRBatchQuery *batchQuery = [GTLRBatchQuery batchQuery];
    
    GTLRDrive_Permission *userPermission = [GTLRDrive_Permission object];
    userPermission.type = @"user";
    userPermission.role = @"writer";
    userPermission.emailAddress = otherAccount;
    GTLRDriveQuery_PermissionsCreate *createUserPermission =
    [GTLRDriveQuery_PermissionsCreate queryWithObject:userPermission
                                               fileId:searchResult[0][@"fileId"]];
    createUserPermission.fields = @"id";
    createUserPermission.completionBlock = ^(GTLRServiceTicket *ticket,
                                             GTLRDrive_Permission *permission,
                                             NSError *error) {
        if (error == nil) {
            NSLog(@"Permisson ID: %@", permission.identifier);
        } else {
            NSLog(@"An error occurred: %@", error);
        }
    };
    
    [batchQuery addQuery:createUserPermission];
    
    [self.service executeQuery:batchQuery completionHandler:^(GTLRServiceTicket *ticket,
                                                              GTLRBatchResult *batchResult,
                                                              NSError *error) {
        if (error == nil) {
            NSLog(@"No error");
            self->result = YES;
        }{
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];
    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};
    
    BOOL result = self->result;
    self->done = NO;
    self->result = NO;
    
    return result;
}

-(BOOL) unshare: (nonnull NSString*) otherAccount folderName: (nonnull NSString *) folderName
{
    [self->resultArray removeAllObjects];

    self->result = NO;
    self->done = NO;

    NSArray *searchResult = [self search: @"MyCodesee" isFolder: YES ownerAccount: self.account];
    NSLog(@"searchResult:%@", searchResult);

    GTLRDriveQuery_PermissionsList *query =
    [GTLRDriveQuery_PermissionsList queryWithFileId:searchResult[0][@"fileId"]];
    query.fields = @"nextPageToken, permissions(id,emailAddress,displayName)";
    [self.service executeQuery: query completionHandler:^(GTLRServiceTicket *callbackTicket,
                                                          GTLRDrive_PermissionList *obj,
                                                          NSError *error) {
        if (error == nil) {
            GTLRDrive_PermissionList *permissionList = obj;
            GTLRDrive_Permission *permission;
            for(permission in permissionList) {
                if([[permission.emailAddress uppercaseString]  hasPrefix: [otherAccount uppercaseString]] == YES) break;
            }
            [self->resultArray addObject: permission.identifier];

        } else {
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];

    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};

    NSString *fileId = searchResult[0][@"fileId"];
    NSString *permissionId = self->resultArray[0];
    //NSLog(@"permission id:%@", permissionId);

    GTLRBatchQuery *batchQuery = [GTLRBatchQuery batchQuery];

    GTLRDriveQuery_PermissionsDelete *deleteUserPermission = [GTLRDriveQuery_PermissionsDelete queryWithFileId: fileId permissionId: permissionId];

    [batchQuery addQuery:deleteUserPermission];

    [self.service executeQuery:batchQuery completionHandler:^(GTLRServiceTicket *ticket,
                                                              GTLRBatchResult *batchResult,
                                                              NSError *error) {
        if (error == nil) {
            NSLog(@"No error");
            self->result = YES;
        }{
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];

    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};

    BOOL result = self->result;
    self->done = NO;
    self->result = NO;

    return result;
}

-(nullable NSArray *) getMySharing
{
    [self->resultArray removeAllObjects];
    self->done = NO;

    NSArray *searchResult = [self search: @"MyCodesee" isFolder: YES ownerAccount: self.account];
    NSLog(@"searchResult:%@", searchResult);

    GTLRDriveQuery_PermissionsList *query =
    [GTLRDriveQuery_PermissionsList queryWithFileId:searchResult[0][@"fileId"]];
    query.fields = @"nextPageToken, permissions(emailAddress,displayName)";
    [self.service executeQuery: query completionHandler:^(GTLRServiceTicket *callbackTicket,
                                                                    GTLRDrive_PermissionList *obj,
                                                                    NSError *error) {
        if (error == nil) {
            GTLRDrive_PermissionList *permissionList = obj;
            for(GTLRDrive_Permission *permission in permissionList) {
                if([[permission.emailAddress uppercaseString]  hasPrefix: [self.account uppercaseString]] == YES) continue;

                NSDictionary *user = @{@"email":permission.emailAddress, @"name":(permission.displayName == nil) ? @"" : permission.displayName};
                [self->resultArray addObject: user];
                NSLog(@"permission display name:%@", permission.displayName);
                NSLog(@"permission email:%@", permission.emailAddress);
            }
        } else {
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];

    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};

    self->done = NO;

    if([self->resultArray count] > 0) {
        NSArray *tmpArray = [self->resultArray copy];
        [self->resultArray removeAllObjects];
        return tmpArray;
    } else {
        return nil;
    }
}

-(nullable NSArray *) getSharedWithMe
{
    [self->resultArray removeAllObjects];
    self->done = NO;

    NSMutableString *queryStr = [[NSMutableString alloc] init];
    [queryStr appendString: @"name = 'MyCodesee' and trashed = false"];
    [queryStr appendString: @" and mimeType='application/vnd.google-apps.folder'"];
    [queryStr appendString: @" and sharedWithMe=true"];
    NSLog(@"query string:%@", queryStr);
    GTLRDriveQuery_FilesList *query = [GTLRDriveQuery_FilesList query];
    query.q = [queryStr copy];
    query.spaces = @"drive";
    query.fields = @"nextPageToken, files(id, name, owners)";
    [self.service executeQuery:query completionHandler:^(GTLRServiceTicket *ticket,
                                                         GTLRDrive_FileList *files,
                                                         NSError *error) {
        if (error == nil) {
            if(files.files.count > 0) {
                for(GTLRDrive_File *file in files) {
                    NSDictionary *item = @{@"email":file.owners[0].emailAddress, @"name": file.owners[0].displayName};
                    [self->resultArray addObject: item];
                    NSLog(@"owne.email:%@", item[@"email"]);
                    NSLog(@"owne.name:%@", item[@"name"]);
                }
            }
        } else {
            NSLog(@"An error occurred: %@", error);
        }
        self->done = YES;
    }];

    while(self->done != YES){[NSThread sleepForTimeInterval:0.01];};

    self->done = NO;

    if([self->resultArray count] > 0) {
        NSArray *tmpArray = [self->resultArray copy];
        [self->resultArray removeAllObjects];
        return tmpArray;
    } else {
        return nil;
    }
}

-(id) init
{
    if (self = [super init]) {
        self.service = [[GTLRDriveService alloc] init];
        // a queue for receive google drive event in child thread
        self->queue = dispatch_queue_create("google_drive_queue", nil);
        self.service.callbackQueue = self->queue;
        self->resultArray = [[NSMutableArray alloc] init];
    }
    
    return self;
}
@end
