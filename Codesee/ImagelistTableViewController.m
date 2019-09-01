//
//  ImagelistTableViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/20.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "ImagelistTableViewController.h"
#import "NkContainerCellView.h"
#import "NKContainerCellTableViewCell.h"
#import <CodeseeSDK/CodeseeSDK.h>
#import "JTAlertView.h"

@interface ImagelistTableViewController ()
{
    NSArray *arrayChronologicalOrder;
    NSMutableArray *sampleData;
    NSString *databaseFile;
    NSArray *ftsSearchResult;
}
@property (strong, nonatomic) IBOutlet UITableView *tableView;
@end

@implementation ImagelistTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self->databaseFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.local.db3"]];

    // Add observer that will allow the nested collection cell to trigger the view controller select row at index path
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didSelectItemFromCollectionView:) name:@"didSelectItemFromCollectionView" object:nil];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // Filling sample data
    /*
     self.sampleData = @[ @{ @"description": @"2016-06-14",
     @"Blocks": @[ @{ @"title": @"Block A1",@"image":@"0.png" },
     @{ @"title": @"Block A2",@"image":@"1.png" },
     @{ @"title": @"Block A3",@"image":@"3.png" },
     @{ @"title": @"Block A4",@"image":@"4.png" },
     @{ @"title": @"Block A5",@"image":@"5.png" },
     @{ @"title": @"Block A6",@"image":@"6.png" },
     @{ @"title": @"Block A7",@"image":@"7.png" },
     @{ @"title": @"Block A8",@"image":@"8.png" },
     @{ @"title": @"Block A9",@"image":@"9.png" },
     @{ @"title": @"Block A10",@"image":@"10.png" }
     ]
     },
     ...
     ];
     */
    // Find the union of all QR code under every user folders
    NSArray *userFolders = [self listFolderAtPath: [CodeseeUtilities getDocPath: @""]];
    NSMutableSet *qrcodeSet = [NSMutableSet new];
    for(NSString *folderName in userFolders) {
        NSArray *tmpArray = [self searchFiles:[CodeseeUtilities getDocPath: folderName] ofTypes:@"meta"];
        NSSet *tmpSet = [NSSet setWithArray: tmpArray];
        [qrcodeSet unionSet: tmpSet];
    }
    if(self->ftsSearchResult != nil) {
        NSSet *ftsSearchResultSet = [NSSet setWithArray: self->ftsSearchResult];
        [qrcodeSet intersectSet: ftsSearchResultSet];
    }
    NSArray *qrcodes = [qrcodeSet allObjects];
    self->sampleData = [[NSMutableArray alloc] init];
    long i=0;
    for(NSString *qrcode in qrcodes) {
        for(NSString *folderName in userFolders) {
            // Get QR code metadata
            NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
            NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: folderName] , qrcode];
            NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
            CodeseeMetadata *qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
            if(error != nil) {
                NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
                continue;
            }
            // Get images mapped to the QR code
            NSArray *imageArray = [qrcodeMetadata getImages];
            // Filling sample data
            // description column
            NSString *description;
            description = [qrcodeMetadata getData: @"description"];
            if(description == nil || [description length] == 0) {
                description = [[NSString alloc] initWithFormat: @"Date:%@--%@", [qrcodeMetadata getData: @"qrcode_date"], folderName];
            }
            // note column
            NSString *note = [qrcodeMetadata getData: @"note"] == nil ? @"" : [qrcodeMetadata getData: @"note"];
            // Blocks column
            NSMutableArray *blocksArray = [[NSMutableArray alloc] initWithCapacity: [imageArray count]];
            int j=0,k=0;
            int qrcodeImageIndex = 0;
            for(NSString *image in imageArray) {
                if([image hasPrefix: [qrcodeMetadata getData: @"qrcode"]] == NO) {
                    NSString *title = @"";
                    NSString *imageFile = [qrcodeFolder stringByAppendingPathComponent: image];
                    NSDictionary *block = @{@"title":title, @"image": imageFile, @"qrcode": qrcode, @"folderName": folderName};
                    [blocksArray insertObject: block atIndex: j];
                    j++;
                } else {
                    qrcodeImageIndex = k;
                }
                k++;
            }
            // Put QR code image as first image
            {
                NSString *title = @""; //[[qrcode stringByDeletingPathExtension] substringFromIndex: 1];
                NSString *imageFile = [qrcodeFolder stringByAppendingPathComponent: imageArray[qrcodeImageIndex]];
                NSDictionary *block = @{@"title":title, @"image": imageFile};
                [blocksArray insertObject: block atIndex: 0];
            }
            // Complete sample
            NSDictionary *sample = @{@"note":note, @"description":description, @"Blocks": blocksArray, @"qrcode": qrcode, @"folderName": folderName};
            [self->sampleData insertObject: sample atIndex:i];
            i++;
        }// end of for(NSString *folderName in userFolders)
    }
    NSSortDescriptor *descriptor = [[NSSortDescriptor alloc] initWithKey:@"description" ascending:YES];
    NSArray *descriptors = [NSArray arrayWithObject:descriptor];
    arrayChronologicalOrder = [self->sampleData sortedArrayUsingDescriptors:descriptors];

    [self.tableView reloadData];
    //
    [self.viewController.indicator stopAnimating];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self->arrayChronologicalOrder count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"NKContainerCellTableViewCell%ld",indexPath.section];
    NKContainerCellTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (nil == cell) {
        cell = [[NKContainerCellTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault
                                                   reuseIdentifier:CellIdentifier];
    }
    
    NSDictionary *cellData = [arrayChronologicalOrder objectAtIndex:[indexPath section]];
    NSArray *BlockData = [cellData objectForKey:@"Blocks"];
    [cell setCollectionData:BlockData];
    
    return cell;
}

- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath
{
    // Return NO if you do not want the specified item to be editable.
    NSDictionary *rowData = [arrayChronologicalOrder objectAtIndex:[indexPath section]];
    NSString *folderName = [rowData objectForKey:@"folderName"];
    if([folderName isEqualToString: @"MyCodesee"] == NO) {
        return NO;
    } else {
        return YES;
    }
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        //
        NSFileManager *fileManager = [NSFileManager defaultManager];
        NSDictionary *cellData = [self->arrayChronologicalOrder objectAtIndex:[indexPath section]];
        NSString *qrcode = [[cellData objectForKey:@"qrcode"] stringByDeletingPathExtension];
        NSString *folderName = [cellData objectForKey:@"folderName"];
        NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: folderName], qrcode];
        NSError *error;
        [fileManager removeItemAtPath: qrcodeFolder error:&error];
        // FTS
        NSString *ftsFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.fts.db3"]];
        CodeseeFTS *fts = [CodeseeFTS new];
        if([fts open: ftsFile] == NO) {
            NSLog(@"fts open file error");
        }
        [fts removeNote:qrcode];
        [fts close];
        //
        CodeseeDB *database = [CodeseeDB new];
        [database open: self->databaseFile];
        [database log: qrcode Action: CodeseeDBDeleteFolder];
        [database log: [NSString stringWithFormat:@"codesee.fts.db3"] Action: CodeseeDBUpdate];
        [database close];
        //https://stackoverflow.com/questions/9471642/swipe-to-delete-tableview-row
        //remove the deleted object from your data source.
        //If your data source is an NSMutableArray, do this
        NSMutableArray *tmpArray = [NSMutableArray new];
        for(int i=0;i<[self->arrayChronologicalOrder count];i++) {
            if(i == indexPath.row) {
                continue;
            }
            [tmpArray addObject: self->arrayChronologicalOrder[i]];
        }
        self->arrayChronologicalOrder = [tmpArray copy];
        //[self->arrayChronologicalOrder removeObjectAtIndex:indexPath.row];
        [self.tableView reloadData]; // tell table to refresh now
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
}

#pragma mark UITableViewDelegate methods

- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    NSDictionary *sectionData = [arrayChronologicalOrder objectAtIndex:section];
    NSString *header = [sectionData objectForKey:@"description"];
    return header;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 100.0;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 132.0;
}

-(UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section{
    //https://stackoverflow.com/questions/23539422/ios-tableview-get-index-of-header-section-on-tapping-button
    NSDictionary *sectionData = [arrayChronologicalOrder objectAtIndex:section];
    NSString *description = [sectionData objectForKey:@"description"];
    NSString *note = [NSString stringWithFormat:@"#%@", [sectionData objectForKey:@"note"]];
    NSString *folderName = [sectionData objectForKey:@"folderName"];

    // create custom header here
    UIView *headerView = [UIView new];
    headerView.frame = CGRectMake(0.f, 0.f, tableView.bounds.size.width, 100.f);
    // DESCRIPTION
    UITextField *descTextField = [[UITextField alloc]init];
    descTextField.frame = CGRectMake(0.f, 0.f, tableView.bounds.size.width, 50.f);
    descTextField.backgroundColor=[UIColor colorWithRed:0.82 green:0.82 blue:0.82 alpha:1.0];
    descTextField.text = description;
    descTextField.delegate = self;
    [descTextField addTarget:self action:@selector(descTextEndEditingAction:) forControlEvents:UIControlEventEditingDidEnd];
    if([folderName isEqualToString: @"MyCodesee"] == NO) {
        descTextField.enabled = NO;
    }
    // set the button tag as section
    descTextField.tag = section;
    // NOTE
    UITextField *noteTextField = [[UITextField alloc]init];
    noteTextField.frame = CGRectMake(0.f, 50.f, tableView.bounds.size.width, 50.f);
    noteTextField.text = note;
    noteTextField.delegate = self;
    [noteTextField addTarget:self action:@selector(noteTextEndEditingAction:) forControlEvents:UIControlEventEditingDidEnd];
    if([folderName isEqualToString: @"MyCodesee"] == NO) {
        noteTextField.enabled = NO;
    }
    // set the button tag as section
    noteTextField.tag = section;
    //
    [headerView addSubview: descTextField];
    [headerView addSubview: noteTextField];
    return headerView;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
    [textField resignFirstResponder];
    return YES;
}

#pragma mark - NSNotification to select table cell

- (void) didSelectItemFromCollectionView:(NSNotification *)notification
{
    NSDictionary *cellData = [notification object];
    NSLog(@"Data:-->%@",cellData);
    UIImage *image = [CodeseeUtilities getThumbnail: cellData[@"image"]];
    if(image == nil) return;
    JTAlertView *alertView = [[JTAlertView alloc] initWithTitle:nil andImage:image];
    alertView.size = CGSizeMake(image.size.width, image.size.height+120);
    alertView.overlayColor = [UIColor colorWithRed:0.0 green:0.0 blue:0.0 alpha:0.0];

    [alertView addButtonWithTitle:@"OK" style:JTAlertViewStyleDefault action:^(JTAlertView *alertView) {
        [alertView hide];
    }];
    
    if([cellData[@"folderName"] isEqualToString: @"MyCodesee"]) {
        [alertView addButtonWithTitle:@"Delete" style:JTAlertViewStyleDestructive action:^(JTAlertView *alertView) {
            NSString *removedImageFile = cellData[@"image"];
            NSString *removedImageFilename = [removedImageFile lastPathComponent];
            NSString *qrcode = cellData[@"qrcode"];
            // Get QR code metadata
            NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
            NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: @"MyCodesee"], qrcode];
            NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
            NSError *error;
            NSData *data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
            CodeseeMetadata *qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
            if(error != nil) {
                NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
            }
            [qrcodeMetadata removeImage: removedImageFilename];
            // Archive QR code metadata
            data = [NSKeyedArchiver archivedDataWithRootObject: qrcodeMetadata requiringSecureCoding: NO error:&error];
            if(error == nil && data != nil) {
                [data writeToFile: qrcodeMetadataFile atomically:YES];
            } else {
                NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
            }
            // Keep QR code metadata update event in journal (Maybe create or update)
            CodeseeDB *database = [CodeseeDB new];
            [database open: self->databaseFile];
            [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
            // Remove image from QR code metadata
            // Delete image
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if ([fileManager fileExistsAtPath:removedImageFile]){
                NSLog(@"remove file %@", removedImageFilename);
                [fileManager removeItemAtPath: removedImageFile error:&error];
            } else {
                NSLog(@"file %@ not found", removedImageFilename);
            }
            // Keep image removed event in journal
            [database log: [NSString stringWithFormat:@"%@/%@", qrcode, removedImageFilename] Action: CodeseeDBDelete];
            [database close];
            //
            [alertView hide];
            // Refresh
            [self viewDidAppear:TRUE];
        }];
    }
    
    [alertView show];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

-(NSArray*)searchFiles:(NSString*)basePath ofTypes:(NSString *)fileTypes{
    NSMutableArray *files = [[NSMutableArray alloc] init];
    NSArray *dirPath = [self listFolderAtPath: basePath];
    NSString *path;
    for(path in dirPath){
        path = [basePath stringByAppendingPathComponent:path];
        NSString *file;
        for(file in [self searchFiles:path ofTypes: fileTypes]) {
            [files addObject: [file stringByDeletingPathExtension]];
        }
    }

    NSString *file;
    for(file in [self listFileAtPath: basePath fileType: fileTypes]) {
        [files addObject: [file stringByDeletingPathExtension]];
    }

    return [files copy];
}

- (NSArray *) listFileAtPath:(NSString *)path fileType: (NSString *) type
{
    NSArray *extensions = [NSArray arrayWithObjects:type, nil];
    NSArray *dirContents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath: path error:NULL];
    NSArray *files = [dirContents filteredArrayUsingPredicate:[NSPredicate predicateWithFormat:@"pathExtension IN %@", extensions]];
    return files;
}

- (NSArray *) listFolderAtPath: (NSString *) basePath
{
    NSMutableArray *dirs = [NSMutableArray new];
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *tmp = [fileManager contentsOfDirectoryAtPath:basePath error: &error];
    NSString *dir;
    for(dir in tmp){
        BOOL isDir;
        NSString *path = [basePath stringByAppendingPathComponent:dir];
        if([fileManager fileExistsAtPath:path isDirectory:&isDir] && isDir){
            [dirs addObject: dir];
        }
    }
    return dirs;
}

-(void) descTextEndEditingAction:(id)sender{
    UITextField *textField = (UITextField*)sender;
    // Get QR code
    NSDictionary *sectionData = [arrayChronologicalOrder objectAtIndex: textField.tag];
    NSString *qrcode = [sectionData objectForKey:@"qrcode"];
    NSString *folderName = [sectionData objectForKey:@"folderName"];
    NSString *header = [sectionData objectForKey:@"description"];
    if([header isEqualToString: textField.text]) return;
    // Get QR code metadata
    NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
    NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: folderName], qrcode];
    NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
    CodeseeMetadata *qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
    if(error != nil) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    [qrcodeMetadata setData: @"description" Value: textField.text];
    data = [NSKeyedArchiver archivedDataWithRootObject: qrcodeMetadata requiringSecureCoding: NO error:&error];
    if(error != nil) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    if([data writeToFile: qrcodeMetadataFile atomically:YES] == NO) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    // Keep QR code metadata event in journal (Maybe create or update)
    CodeseeDB *database = [CodeseeDB new];
    [database open: self->databaseFile];
    [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
    [database close];
}

-(void) noteTextEndEditingAction:(id)sender{
    UITextField *textField = (UITextField*)sender;
    // Get QR code
    NSDictionary *sectionData = [arrayChronologicalOrder objectAtIndex: textField.tag];
    NSString *qrcode = [sectionData objectForKey:@"qrcode"];
    NSString *folderName = [sectionData objectForKey:@"folderName"];
    NSString *header = [sectionData objectForKey:@"note"];
    if([header isEqualToString: [textField.text substringFromIndex:1]]) return;
    // Get QR code metadata
    NSString *qrcodeMetadataFilename = [NSString stringWithFormat:@"%@.meta", qrcode];
    NSString *qrcodeFolder = [NSString stringWithFormat:@"%@/%@", [CodeseeUtilities getDocPath: folderName], qrcode];
    NSString *qrcodeMetadataFile = [qrcodeFolder stringByAppendingPathComponent: qrcodeMetadataFilename];
    NSError *error;
    NSData *data = [NSData dataWithContentsOfFile:qrcodeMetadataFile];
    CodeseeMetadata *qrcodeMetadata = [NSKeyedUnarchiver unarchivedObjectOfClass:[CodeseeMetadata class] fromData:data error:&error];
    if(error != nil) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    [qrcodeMetadata setData: @"note" Value: [textField.text substringFromIndex:1]];
    data = [NSKeyedArchiver archivedDataWithRootObject: qrcodeMetadata requiringSecureCoding: NO error:&error];
    if(error != nil) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    if([data writeToFile: qrcodeMetadataFile atomically:YES] == NO) {
        NSLog(@"[Codesee] %s %d error", __FUNCTION__, __LINE__);
    }
    // FTS
    NSString *ftsFile = [[CodeseeUtilities getDocPath: @"MyCodesee"] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.fts.db3"]];
    CodeseeFTS *fts = [CodeseeFTS new];
    if([fts open: ftsFile] == NO) {
        NSLog(@"fts open file error");
    }
    [fts updateNote:qrcode note: [textField.text substringFromIndex:1]];
    [fts close];
    // Keep QR code metadata event in journal (Maybe create or update)
    CodeseeDB *database = [CodeseeDB new];
    [database open: self->databaseFile];
    [database log: [NSString stringWithFormat:@"%@/%@", qrcode, qrcodeMetadataFilename] Action: CodeseeDBUpdate];
    [database log: [NSString stringWithFormat:@"codesee.fts.db3"] Action: CodeseeDBUpdate];
    [database close];
}

#pragma mark - Search Bar Implementation

- (void)searchBar:(UISearchBar *)searchBar textDidChange:(NSString *)searchText {
    if([searchText length] == 0 ) {
        self->ftsSearchResult = nil;
        // Refresh
        [self viewDidAppear:TRUE];
        return;
    }
}

- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    [self.searchBar resignFirstResponder];
    if([searchBar.text length] == 0 ) {
        self->ftsSearchResult = nil;
        // Refresh
        [self viewDidAppear:TRUE];
        return;
    }

    NSArray *userFolders = [self listFolderAtPath: [CodeseeUtilities getDocPath: @""]];
    NSMutableSet *qrocdes = [NSMutableSet new];
    for(NSString *folderName in userFolders) {
        NSString *ftsFile = [[CodeseeUtilities getDocPath: folderName] stringByAppendingPathComponent: [NSString stringWithFormat:@"codesee.fts.db3"]];
        CodeseeFTS *fts = [CodeseeFTS new];
        if([fts open: ftsFile] == NO) {
            NSLog(@"fts open file error");
        }
        [qrocdes unionSet: [NSSet setWithArray: [fts search: searchBar.text]]];
        [fts close];
    }
    self->ftsSearchResult = [qrocdes allObjects];
    // Refresh
    [self viewDidAppear:TRUE];
}
/*
// Override to support editing the table view.
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {
    if (editingStyle == UITableViewCellEditingStyleDelete) {
        // Delete the row from the data source
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationFade];
    } else if (editingStyle == UITableViewCellEditingStyleInsert) {
        // Create a new instance of the appropriate class, insert it into the array, and add a new row to the table view
    }   
}
*/

/*
// Override to support rearranging the table view.
- (void)tableView:(UITableView *)tableView moveRowAtIndexPath:(NSIndexPath *)fromIndexPath toIndexPath:(NSIndexPath *)toIndexPath {
}
*/

/*
// Override to support conditional rearranging of the table view.
- (BOOL)tableView:(UITableView *)tableView canMoveRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the item to be re-orderable.
    return YES;
}
*/

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
