//
//  SettingTableViewController.m
//  Codesee
//
//  Created by Leo Tang on 2019/1/21.
//  Copyright © 2019 Leo Tang. All rights reserved.
//

#import "SettingTableViewController.h"
#import "DTCustomColoredAccessory.h"
#import "SigninViewController.h"

extern SigninViewController *signinViewController;

typedef enum _CodeseeSetting {
    CodeseeSettingTitle = 0,
    CodeseeSettingMySharing,
    CodeseeSettingSharedWithMe,
    CodeseeSettingSync
} CodeseeSetting;

@interface SettingTableViewController ()
{
    NSMutableIndexSet *expandedSections;
    NSArray *settingArray;
    NSArray *mySharingArray;
    NSArray *sharedWithMeArray;
}
@end

@implementation SettingTableViewController

- (void)viewDidLoad {
    [super viewDidLoad];

    self->settingArray = @[@"Title", NSLocalizedString(@"Mysharing",nil), NSLocalizedString(@"Sharedwithme",nil), NSLocalizedString(@"Synchronize",nil)];

    // Uncomment the following line to preserve selection between presentations.
    // self.clearsSelectionOnViewWillAppear = NO;
    
    // Uncomment the following line to display an Edit button in the navigation bar for this view controller.
    // self.navigationItem.rightBarButtonItem = self.editButtonItem;
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];

    // For testing
    //self->mySharingArray = @[@{@"email":@"b8809040@gmail.com", @"name":@"Leo Tang"}];

    self->mySharingArray = [signinViewController.cloud getMySharing];

    self->sharedWithMeArray = [signinViewController.cloud getSharedWithMe];

    if (!expandedSections)
    {
        expandedSections = [[NSMutableIndexSet alloc] init];
    }

    //
    [self.tableView reloadData];
    //
    [self.viewController.indicator stopAnimating];
}

#pragma mark - Table view data source

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return [self->settingArray count];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if ([self tableView:tableView canCollapseSection:section])
    {
        if ([expandedSections containsIndex:section])
        {
            // return rows when expanded
            switch(section) {
            case CodeseeSettingMySharing:
                {
                    return [self->mySharingArray count] + 2;
                }
            case CodeseeSettingSharedWithMe:
                {
                    return [self->sharedWithMeArray count] + 1;
                }
            case CodeseeSettingSync:
                {
                    return 2;
                }
            default:
                {
                    break;
                }
            }
        }

        return 1; // only top row showing
    }

    // Return the number of rows in the section.
    return 0;
}

- (BOOL)tableView:(UITableView *)tableView canCollapseSection:(NSInteger)section
{
    if (section>0) return YES;

    return NO;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    NSString *CellIdentifier = [NSString stringWithFormat:@"Cell%ld%ld", (long)[indexPath section], (long)[indexPath row]];

    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier];
    }

    // Configure the cell...

    if ([self tableView:tableView canCollapseSection:indexPath.section])
    {
        if (!indexPath.row)
        {
            // first row
            [cell setBackgroundColor:[UIColor colorWithRed:1.00 green:0.72 blue:0.00 alpha:1.0]];
            cell.textLabel.text = [self->settingArray objectAtIndex: indexPath.section]; // only top row showing

            if ([expandedSections containsIndex:indexPath.section])
            {
                cell.accessoryView = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
            }
            else
            {
                cell.accessoryView = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
            }
        }
        else
        {
            // all other rows
            switch([indexPath section]) {
                case CodeseeSettingMySharing:
                {
                    if(indexPath.row == (self->mySharingArray.count+1)) {
                        // last cell
                        [cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1]];
                        cell.textLabel.text = NSLocalizedString(@"New",nil);
                        cell.imageView.image = [UIImage imageNamed:@"setting-view-add-button.png"];
                        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sharingAddTapAction:)];
                        [cell addGestureRecognizer:tapGestureRecognizer];
                    } else {
                        NSDictionary *account = [self->mySharingArray objectAtIndex: (indexPath.row-1)];
                        //NSLog(@"account:%@", account);
                        [cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1]];
                        cell.textLabel.text = account[@"email"];
                        cell.imageView.image = [UIImage imageNamed:@"setting-view-remove-button.png"];
                        UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(sharingRemoveTapAction:)];
                        [cell addGestureRecognizer:tapGestureRecognizer];
                    }
                    break;
                }
                case CodeseeSettingSharedWithMe:
                {
                    NSDictionary *account = [self->sharedWithMeArray objectAtIndex: (indexPath.row-1)];
                    [cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1]];
                    cell.textLabel.text = account[@"email"];
                    break;
                }
                case CodeseeSettingSync:
                {
                    [cell setBackgroundColor:[UIColor colorWithRed:.8 green:.8 blue:1 alpha:1]];
                    cell.textLabel.text = NSLocalizedString(@"Startsync",nil);
                    cell.imageView.image = [UIImage imageNamed:@"setting-view-sync-button.png"];
                    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(syncTapAction:)];
                    [cell addGestureRecognizer:tapGestureRecognizer];
                    break;
                }
                default:
                {
                    break;
                }
            }
            cell.accessoryView = nil;
            cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
        }
    }
    else
    {
        cell.accessoryView = nil;
        cell.textLabel.text = @"Error!";
    }

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self tableView:tableView canCollapseSection:indexPath.section])
    {
        if (!indexPath.row)
        {
            // only first row toggles exapand/collapse
            [tableView deselectRowAtIndexPath:indexPath animated:YES];

            NSInteger section = indexPath.section;
            BOOL currentlyExpanded = [expandedSections containsIndex:section];
            NSInteger rows;

            NSMutableArray *tmpArray = [NSMutableArray array];

            if (currentlyExpanded)
            {
                rows = [self tableView:tableView numberOfRowsInSection:section];
                [expandedSections removeIndex:section];
            }
            else
            {
                [expandedSections addIndex:section];
                rows = [self tableView:tableView numberOfRowsInSection:section];
            }

            for (int i=1; i<rows; i++)
            {
                NSIndexPath *tmpIndexPath = [NSIndexPath indexPathForRow:i inSection:section];
                [tmpArray addObject:tmpIndexPath];
            }

            UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

            if (currentlyExpanded)
            {
                [tableView deleteRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                cell.accessoryView = [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeDown];
            }
            else
            {
                [tableView insertRowsAtIndexPaths:tmpArray withRowAnimation:UITableViewRowAnimationTop];
                cell.accessoryView =  [DTCustomColoredAccessory accessoryWithColor:[UIColor grayColor] type:DTCustomColoredAccessoryTypeUp];
            }
        }//if (!indexPath.row)
    }//if ([self tableView:tableView canCollapseSection:indexPath.section])
}

- (void) sharingAddTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    // For testing
    //[signinViewController.cloud share: @"b8809040@gmail.com" folderName: @"MyCodesee"];
    NSArray *searchResult = [signinViewController.cloud search: @"Codesee" isFolder: YES ownerAccount: signinViewController.cloud.account];
    if(searchResult == nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Error",nil)
                                                                                  message: NSLocalizedString(@"Tapsyncitembeforesharing",nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler: nil]];

        [self presentViewController:alertController animated:YES completion:nil];
    } else {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Newsharing",nil)
                                                                                  message: NSLocalizedString(@"Inputaccount",nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addTextFieldWithConfigurationHandler:^(UITextField *textField) {
            textField.placeholder = @"name";
            textField.textColor = [UIColor blueColor];
            textField.clearButtonMode = UITextFieldViewModeWhileEditing;
            textField.borderStyle = UITextBorderStyleRoundedRect;
        }];

        [alertController addAction:[UIAlertAction actionWithTitle:NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
            NSArray * textfields = alertController.textFields;
            NSString *account = ((UITextField *) textfields[0]).text;
            if(account != nil && account.length != 0) {
                [signinViewController.cloud share: account folderName: @"MyCodesee"];

                self->mySharingArray = [signinViewController.cloud getMySharing];

                [self.tableView reloadData];
            }
        }]];

        [self presentViewController:alertController animated:YES completion:nil];
    }
}

- (void) sharingRemoveTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Removesharing",nil)
                                                                              message: NSLocalizedString(@"Removethisaccountfromyoursharing",nil)
                                                                       preferredStyle:UIAlertControllerStyleAlert];

    [alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        UITableViewCell *cell = (UITableViewCell *) tapGestureRecognizer.view;
        NSString *accountEmail = cell.textLabel.text;
        //NSLog(@"email:%@ removed", accountEmail);

        [signinViewController.cloud unshare: accountEmail folderName: @"MyCodesee"];
        //self->mySharingArray = [signinViewController.cloud getMySharing];
        // FIXME: workaround
        NSMutableArray *tmpArray = [NSMutableArray array];

        for(int i=0;i<[self->mySharingArray count];i++) {
            NSString *email = (NSString *) self->mySharingArray[i][@"email"];
            if([email isEqualToString: accountEmail] == YES) {
                continue;
            }
            [tmpArray addObject: self->mySharingArray[i]];
        }
        self->mySharingArray = [tmpArray copy];

        [self.tableView reloadData];
    }]];

    [alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"Cancel",nil) style:UIAlertActionStyleDefault handler:nil]];

    [self presentViewController:alertController animated:YES completion:nil];
}

- (void) syncTapAction:(UITapGestureRecognizer *)tapGestureRecognizer {
    if(signinViewController.cloud.service.authorizer == nil) {
        UIAlertController * alertController = [UIAlertController alertControllerWithTitle: NSLocalizedString(@"Nocloudfound",nil)
                                                                                  message: NSLocalizedString(@"Loginbeforesync",nil)
                                                                           preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle: NSLocalizedString(@"OK",nil) style:UIAlertActionStyleDefault handler: nil]];

        [self presentViewController:alertController animated:YES completion:nil];
        return;
    }
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:nil
                                                                   message:NSLocalizedString(@"Synchronizing",nil)
                                                            preferredStyle:UIAlertControllerStyleAlert];
    UIAlertAction *cancelAction = [UIAlertAction actionWithTitle:NSLocalizedString(@"Cancel",nil)
                                                           style:UIAlertActionStyleDefault
                                                         handler:^(UIAlertAction * action) {
                                                             [signinViewController.cloud stopSync];
                                                             NSLog(@"Sync. cancel");
                                                             dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
                                                                 [alert dismissViewControllerAnimated:YES completion:nil];
                                                             });
                                                         }];
    [alert addAction:cancelAction];
    // Daisy
    UIActivityIndicatorView *indicator = [[UIActivityIndicatorView alloc] initWithFrame: alert.view.bounds];
    indicator.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    indicator.color = [UIColor colorWithRed:0.60 green:0.59 blue:0.59 alpha:1.0];
    [alert.view addSubview: indicator];
    [indicator setUserInteractionEnabled:NO];
    [indicator startAnimating];
    //
    NSThread *thread = [[NSThread alloc] initWithTarget:self selector:@selector(runCloudSync:) object:alert];
    [thread start];

    [self presentViewController:alert animated:YES completion:nil];
}

- (void) runCloudSync: (UIAlertController *) alert
{
    [signinViewController.cloud sync];
    NSLog(@"Sync. done");
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 1 * NSEC_PER_SEC), dispatch_get_main_queue(), ^{
        [alert dismissViewControllerAnimated:YES completion:nil];
    });
}
/*
// Override to support conditional editing of the table view.
- (BOOL)tableView:(UITableView *)tableView canEditRowAtIndexPath:(NSIndexPath *)indexPath {
    // Return NO if you do not want the specified item to be editable.
    return YES;
}
*/

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
