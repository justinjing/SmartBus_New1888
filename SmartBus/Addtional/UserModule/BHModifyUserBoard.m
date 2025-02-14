//
//  BHModifyUserBoard.m
//  SmartBus
//
//  Created by launching on 13-11-7.
//  Copyright (c) 2013年 launching. All rights reserved.
//

#import "BHModifyUserBoard.h"
#import "BHUserCheckBoard.h"
#import "BHPhotoPickerPreviewer.h"
#import "UIImageView+WebCache.h"
#import "BHUserHelper.h"
#import "XHImageViewer.h"

@interface BHModifyUserBoard ()<UIScrollViewDelegate, BHPhotoPickerDelegate>
{
    BHPhotoPickerPreviewer *_photoPicker;
    
    BeeUIButton *menu;
    UIScrollView *_scrollView;
    UIImageView *_avatorHeaderView;
    UIImageView *_profileItemView;
    
    NSInteger _userId;
    NSArray *_items;
    NSInteger _selectedItemIndex;
    BHUserHelper *_userHelper;
    UIImage *_localImage;
}
- (void)addAvatorHeader;
- (void)reloadAvator;
- (void)reloadAvator:(UIImage *)image;
- (void)addProfileItemView;
- (void)reloadProfileAtIndex:(int)idx withValue:(NSString *)value;
- (void)addItemInView:(UIView *)view atIndex:(int)idx;
- (void)addSignature:(NSString *)title inView:(UIView *)view;
- (void)toggleEditStatus:(BOOL)edit;
- (NSString *)itemValueAtIndex:(int)idx;
- (void)submitUserInfo;
@end

#define kAvatorHeaderHeight  72.f
#define kItemBaseTag         991

@implementation BHModifyUserBoard

DEF_SIGNAL( EDIT_AVATOR );
DEF_SIGNAL( TOGGLE_EDIT );
DEF_NOTIFICATION( HAVE_UPDATE );

- (id)initWithUserId:(NSInteger)uid
{
    if ( self = [super init] )
    {
        _userId = uid;
    }
    return self;
}

- (void)load
{
    _userHelper = [[BHUserHelper alloc] init];
    [_userHelper addObserver:self];
    _selectedItemIndex = NSNotFound;
    _items = [[NSArray alloc] initWithObjects:@"昵称", @"性别", @"出生日期", @"地区", @"职业", @"简介", nil];
    [super load];
}

- (void)unload
{
    [_userHelper removeObserver:self];
    SAFE_RELEASE(_userHelper);
    SAFE_RELEASE(_items);
    SAFE_RELEASE(_photoPicker);
    SAFE_RELEASE(_localImage);
    [super unload];
}

- (void)handleMenu
{
    [_userHelper removeObserver:self];
    SAFE_RELEASE(_userHelper);
    
    if ( self.registed )
    {
        [self dismissViewControllerAnimated:YES completion:nil];
    }
    else
    {
        [self.stack popBoardAnimated:YES];
    }
}

ON_SIGNAL2( BeeUIBoard, signal )
{
	[super handleUISignal_BeeUIBoard:signal];
	
	if ( [signal is:BeeUIBoard.CREATE_VIEWS] )
	{
        [self indicateIsFirstBoard:NO image:[UIImage imageNamed:@"nav_setting.png"] title:@"个人资料"];
        
        // 只有自己才可以编辑资料
        if ( _userId == [BHUserModel sharedInstance].uid )
        {
            menu = [[BeeUIButton alloc] initWithFrame:CGRectMake(280.f, 2.f, 40.f, 40.f)];
            menu.stateNormal.image = [UIImage imageNamed:@"icon_edit.png"];
            menu.stateSelected.image = [UIImage imageNamed:@"icon_certain.png"];
            [menu addSignal:self.TOGGLE_EDIT forControlEvents:UIControlEventTouchUpInside];
            [self.navigationBar addSubview:menu];
        }
        
        _scrollView = [[UIScrollView alloc] initWithFrame:CGRectZero];
        _scrollView.backgroundColor = [UIColor clearColor];
        _scrollView.showsVerticalScrollIndicator = NO;
        _scrollView.delegate = self;
        [self.beeView addSubview:_scrollView];
        
        [self addAvatorHeader];
        [self addProfileItemView];
	}
	else if ( [signal is:BeeUIBoard.DELETE_VIEWS] )
	{
		SAFE_RELEASE_SUBVIEW(_scrollView);
	}
    else if ( [signal is:BeeUIBoard.LAYOUT_VIEWS] )
	{
		_scrollView.frame = self.beeView.bounds;
        _scrollView.contentSize = CGSizeMake(320.f, _scrollView.frame.size.height + 1.f);
	}
    else if ( [signal is:BeeUIBoard.LOAD_DATAS] )
	{
        [_userHelper getUserDetail:_userId shower:[BHUserModel sharedInstance].uid];
	}
    else if ( [signal is:BeeUIBoard.WILL_APPEAR] )
    {
        if ( _selectedItemIndex != NSNotFound )
        {
            NSString *value = nil;
            switch ( _selectedItemIndex )
            {
                case 0:
                    value = [BHUserModel sharedInstance].uname;
                    break;
                case 1:
                    if ( [BHUserModel sharedInstance].ugender == 0 ) {
                        value = @"保密";
                    } else if ( [BHUserModel sharedInstance].ugender == 1 ) {
                        value = @"男";
                    } else {
                        value = @"女";
                    }
                    break;
                case 2:
                    value = [BHUserModel sharedInstance].birth;
                    break;
                case 3:
                    value = [BHUserModel sharedInstance].location;
                    break;
                case 4:
                    value = [BHUserModel sharedInstance].profession;
                    break;
                default:
                    value = [BHUserModel sharedInstance].signature;
                    break;
            }
            [self reloadProfileAtIndex:_selectedItemIndex withValue:value];
        }
    }
}

ON_SIGNAL2( BeeUIButton, signal )
{
    if ( [signal is:self.EDIT_AVATOR] )
    {
        if ( !_photoPicker ) {
            _photoPicker = [[BHPhotoPickerPreviewer alloc] initWithDelegate:self];
        }
        [_photoPicker show];
    }
    else if ( [signal is:self.TOGGLE_EDIT] )
    {
        menu.selected = !menu.selected;
        [self toggleEditStatus:menu.selected];
        if ( !menu.selected )
        {
            [self submitUserInfo];
        }
    }
}


#pragma mark -
#pragma mark NetworkRequestDelegate

- (void)handleRequest:(BeeHTTPRequest *)request
{
    if ( request.sending )
    {
        NSString *tips = [request.userInfo is:@"uploadAvator"] ? @"正在上传..." : @"加载中...";
        [self presentLoadingTips:tips];
    }
	else if ( request.succeed )
	{
        [self dismissTips];
        
        if ( [request.userInfo is:@"getUserDetail"] )
        {
            [self reloadAvator];
            
            for (int i = 0; i < _items.count; i++) {
                [self reloadProfileAtIndex:i withValue:[self itemValueAtIndex:i]];
            }
        }
        else if ( [request.userInfo is:@"uploadAvator"] )
        {
            if ( _userHelper.succeed )
            {
                [self reloadAvator:_localImage];
                [self postNotification:self.HAVE_UPDATE];
            }
        }
        else if ( [request.userInfo is:@"updateUserInfo"] )
        {
            if ( _userHelper.succeed )
            {
                [self postNotification:self.HAVE_UPDATE];
            }
        }
    }
    else if ( request.failed )
    {
        [self dismissTips];
    }
}


#pragma mark -
#pragma mark private methods

- (void)addAvatorHeader
{
    _avatorHeaderView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bubble.png"] stretchableImageWithLeftCapWidth:5.f topCapHeight:5.f]];
    _avatorHeaderView.frame = CGRectMake(10.f, 10.f, 300.f, kAvatorHeaderHeight);
    _avatorHeaderView.userInteractionEnabled = YES;
    [_scrollView addSubview:_avatorHeaderView];
    
    UIImageView *avatorImageView = [[UIImageView alloc] initWithFrame:CGRectMake(11.f, 11.f, 50.f, 50.f)];
    avatorImageView.layer.masksToBounds = YES;
    avatorImageView.layer.cornerRadius = 5.f;
    avatorImageView.userInteractionEnabled = YES;
    [_avatorHeaderView addSubview:avatorImageView];
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapped:)];
    [avatorImageView addGestureRecognizer:tap];
    [tap release];
    [avatorImageView release];
    
    if ( _userId == [BHUserModel sharedInstance].uid )
    {
        BeeUIButton *button = [BeeUIButton new];
        button.frame = CGRectMake(210.f, 21.f, 70.f, 30.f);
        button.backgroundColor = [UIColor flatDarkRedColor];
        button.layer.cornerRadius = 4.f;
        button.layer.masksToBounds = YES;
        button.title = @"编辑头像";
        button.titleFont = FONT_SIZE(14);
        [button addSignal:self.EDIT_AVATOR forControlEvents:UIControlEventTouchUpInside];
        [_avatorHeaderView addSubview:button];
    }
}

- (void)reloadAvator
{
    UIImageView *avatorImageView = (UIImageView *)[_avatorHeaderView.subviews objectAtIndex:0];
    [avatorImageView setImageWithURL:[NSURL URLWithString:_userHelper.user.avator] placeholderImage:[UIImage imageNamed:@"default_man.png"]];
}

- (void)reloadAvator:(UIImage *)image
{
    UIButton *avatorButton = (UIButton *)[_avatorHeaderView.subviews objectAtIndex:0];
    [avatorButton setImage:image forState:UIControlStateNormal];
}

- (void)addProfileItemView
{
    _profileItemView = [[UIImageView alloc] initWithImage:[[UIImage imageNamed:@"bubble.png"] stretchableImageWithLeftCapWidth:5.f topCapHeight:5.f]];
    _profileItemView.frame = CGRectMake(10.f, 20.f+kAvatorHeaderHeight, 300.f, 300.f);
    _profileItemView.userInteractionEnabled = YES;
    [_scrollView addSubview:_profileItemView];
    
    for (int i = 0; i < _items.count - 1; i++)
    {
        [self addItemInView:_profileItemView atIndex:i];
    }
    [self addSignature:_items[_items.count - 1] inView:_profileItemView];
}

- (void)reloadProfileAtIndex:(int)idx withValue:(NSString *)value
{
    UIButton *cell = (UIButton *)[_profileItemView viewWithTag:kItemBaseTag + idx];
    UILabel *subtitleLabel = (UILabel *)[cell.subviews objectAtIndex:1];
    [subtitleLabel setText:value];
}

- (void)addItemInView:(UIView *)view atIndex:(int)idx
{
    UIButton *cell = [UIButton buttonWithType:UIButtonTypeCustom];
    cell.frame = CGRectMake(0.f, idx*44.f, view.frame.size.width, 44.f);
    cell.backgroundColor = [UIColor clearColor];
    cell.tag = kItemBaseTag + idx;
    
    // 标题
    UILabel *titlelLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 10.f, 70.f, 24.f)];
    titlelLabel.backgroundColor = [UIColor clearColor];
    titlelLabel.font = FONT_SIZE(14);
    titlelLabel.text = [_items objectAtIndex:idx];
    [cell addSubview:titlelLabel];
    [titlelLabel release];
    
    // 内容
    UILabel *subtitleLabel = [[UILabel alloc] initWithFrame:CGRectMake(90.f, 10.f, 180.f, 24.f)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.font = FONT_SIZE(14);
    subtitleLabel.textAlignment = UITextAlignmentRight;
    subtitleLabel.textColor = [UIColor lightGrayColor];
    [cell addSubview:subtitleLabel];
    [subtitleLabel release];
    
    // 箭头
    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_right_arrow.png"]];
    arrowImageView.frame = CGRectMake(280.f, 16.f, 6.f, 12.f);
    [cell addSubview:arrowImageView];
    arrowImageView.hidden = YES;
    [arrowImageView release];
    
    // 划线
    UIView *line = [[UIView alloc] initWithFrame:CGRectMake(10.f, 43.f, 280.f, 1.f)];
    line.backgroundColor = [UIColor flatWhiteColor];
    [cell addSubview:line];
    [line release];
    
    [cell addTarget:self action:@selector(itemDidSelect:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:cell];
    cell.enabled = NO;
}

- (void)addSignature:(NSString *)title inView:(UIView *)view
{
    UIButton *cell = [UIButton buttonWithType:UIButtonTypeCustom];
    cell.frame = CGRectMake(0.f, (_items.count-1)*44.f, view.frame.size.width, 80.f);
    cell.backgroundColor = [UIColor clearColor];
    cell.tag = kItemBaseTag + (_items.count - 1);
    
    // 标题
    UILabel *titleLabel = [[UILabel alloc] initWithFrame:CGRectMake(10.f, 28.f, 70.f, 24.f)];
    titleLabel.backgroundColor = [UIColor clearColor];
    titleLabel.font = FONT_SIZE(14);
    titleLabel.text = title;
    [cell addSubview:titleLabel];
    [titleLabel release];
    
    // 内容
    BeeUILabel *subtitleLabel = [[BeeUILabel alloc] initWithFrame:CGRectMake(90.f, 5.f, 180.f, 70.f)];
    subtitleLabel.backgroundColor = [UIColor clearColor];
    subtitleLabel.font = FONT_SIZE(14);
    subtitleLabel.textColor = [UIColor lightGrayColor];
    subtitleLabel.textAlignment = UITextAlignmentRight;
    subtitleLabel.text = [BHUserModel sharedInstance].signature;
    subtitleLabel.numberOfLines = 0;
    [cell addSubview:subtitleLabel];
    [subtitleLabel release];
    
    // 箭头
    UIImageView *arrowImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"icon_right_arrow.png"]];
    arrowImageView.frame = CGRectMake(280.f, 34.f, 6.f, 12.f);
    [cell addSubview:arrowImageView];
    arrowImageView.hidden = YES;
    [arrowImageView release];
    
    [cell addTarget:self action:@selector(itemDidSelect:) forControlEvents:UIControlEventTouchUpInside];
    [view addSubview:cell];
    cell.enabled = NO;
}

- (void)toggleEditStatus:(BOOL)edit
{
    for (int i = 0; i < _items.count; i++)
    {
        UIButton *button = (UIButton *)[_profileItemView viewWithTag:kItemBaseTag + i];
        button.enabled = edit;
        UIImageView *arrowImageView = (UIImageView *)[button.subviews objectAtIndex:2];
        arrowImageView.hidden = !edit;
    }
}

- (NSString *)itemValueAtIndex:(int)idx
{
    NSString *text = nil;
    
    switch ( idx )
    {
        case 0:
            text = _userHelper.user.uname;
            break;
        case 1:
            if ( _userHelper.user.ugender == 0 ) {
                text = @"保密";
            } else if ( _userHelper.user.ugender == 1 ) {
                text = @"男";
            } else {
                text = @"女";
            }
            break;
        case 2:
            text = _userHelper.user.birth;
            break;
        case 3:
            text = _userHelper.user.location;
            break;
        case 4:
            text = _userHelper.user.profession;
            break;
        default:
            text = _userHelper.user.signature;
            break;
    }
    
    return text;
}

- (void)submitUserInfo
{
    BHUserModel *user = [[BHUserModel alloc] init];
    for (int i = 0; i < _items.count; i++)
    {
        UIButton *button = (UIButton *)[_profileItemView viewWithTag:kItemBaseTag + i];
        UILabel *label = (UILabel *)[button.subviews objectAtIndex:1];
        switch ( i )
        {
            case 0:
                user.uname = label.text;
                break;
            case 1:
                if ( [label.text is:@"男"] ) {
                    user.ugender = 1;
                } else if ( [label.text is:@"女"] ) {
                    user.ugender = 2;
                } else {
                    user.ugender = 0;
                }
                break;
            case 2:
                user.birth = label.text;
                break;
            case 3:
                user.location = label.text;
                break;
            case 4:
                user.profession = label.text;
                break;
            case 5:
                user.signature = label.text;
                break;
            default:
                break;
        }
    }
    
    [_userHelper updateUserInfo:user withUserID:[BHUserModel sharedInstance].uid];
    SAFE_RELEASE(user);
}


#pragma mark - 
#pragma mark button events

- (void)itemDidSelect:(UIButton *)sender
{
    _selectedItemIndex = sender.tag - kItemBaseTag;
    BHUserCheckBoard *board = [[BHUserCheckBoard alloc] initWithCheckMode:_selectedItemIndex];
    [self.stack pushBoard:board animated:YES];
    [board release];
}

- (void)tapped:(UITapGestureRecognizer *)recognizer
{
    UIImageView *avatorImageView = (UIImageView *)recognizer.view;
    XHImageViewer *imageViewer = [[XHImageViewer alloc] init];
    [imageViewer showWithImageViews:[NSArray arrayWithObject:avatorImageView] selectedView:avatorImageView];
    [imageViewer release];
}


#pragma mark -
#pragma mark BHPhotoPickerDelegate

- (void)photoPickerPreviewer:(id)previewer didFinishPickingWithImage:(UIImage *)image
{
    SAFE_RELEASE(_localImage);
    _localImage = [image retain];
    
    [_userHelper uploadUserAvator:image withUserId:[BHUserModel sharedInstance].uid];
}

@end
