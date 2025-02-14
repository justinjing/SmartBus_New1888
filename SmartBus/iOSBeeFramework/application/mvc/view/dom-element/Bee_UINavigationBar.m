//
//	 ______    ______    ______
//	/\  __ \  /\  ___\  /\  ___\
//	\ \  __<  \ \  __\_ \ \  __\_
//	 \ \_____\ \ \_____\ \ \_____\
//	  \/_____/  \/_____/  \/_____/
//
//
//	Copyright (c) 2013-2014, {Bee} open source community
//	http://www.bee-framework.com
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

#import "Bee_UINavigationBar.h"
#import "UIView+BeeUISignal.h"
#import "UIView+LifeCycle.h"

#pragma mark -

@interface BeeUINavigationBar()
{
	BOOL						_inited;
	BOOL						_rounded;
	UINavigationController *	_navigationController;
	UIImage *					_backgroundImage;
}

- (void)initSelf;

@end

#pragma mark -

@implementation BeeUINavigationBar

DEF_NOTIFICATION( BACKGROUND_CHANGED )

DEF_INT( LEFT,	0 )
DEF_INT( RIGHT,	1 )

DEF_SIGNAL( LEFT_TOUCHED )
DEF_SIGNAL( RIGHT_TOUCHED )

@dynamic backgroundImage;
@synthesize navigationController = _navigationController;

static UIImage * __defaultBackgroundImage = nil;

- (id)init
{
    self = [super initWithFrame:CGRectZero];
    if ( self )
	{
		[self initSelf];
    }
    return self;
}

- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if ( self )
	{
		[self initSelf];
    }
    return self;
}

- (void)initSelf
{
	if ( NO == _inited )
	{
		[self setBarStyle:UIBarStyleBlackOpaque];
		[self observeNotification:self.BACKGROUND_CHANGED];
		
		_inited = YES;
		
		[self load];
	}
}

- (void)dealloc
{
	[self unload];
	[self unobserveAllNotifications];
	
    [_backgroundImage release];
	
    [super dealloc];
}

- (void)drawRect:(CGRect)rect
{
    if ( _backgroundImage )
	{
        [_backgroundImage drawInRect:rect];
    }
	else if ( __defaultBackgroundImage )
	{
		[__defaultBackgroundImage drawInRect:rect];
	}
	else
	{
        [super drawRect:rect];
    }
}

- (void)setFrame:(CGRect)frame
{
	[super setFrame:frame];

	self.layer.shadowOpacity = 0.7f;
	self.layer.shadowRadius = 1.5f;
	self.layer.shadowOffset = CGSizeMake(0.0f, 0.3f);
	self.layer.shadowColor = [UIColor blackColor].CGColor;
	self.layer.shadowPath = [UIBezierPath bezierPathWithRect:self.bounds].CGPath;
	self.layer.shouldRasterize = YES;

//	CAShapeLayer * maskLayer = nil;
//	
//	for ( CALayer * layer in self.layer.sublayers )
//	{
//		if ( [layer isKindOfClass:[CAShapeLayer class]] && [layer.name isEqualToString:@"maskLayer"] )
//		{
//			maskLayer = (CAShapeLayer *)layer;
//			break;
//		}
//	}
//
//	if ( nil == maskLayer )
//	{
//		maskLayer = [CAShapeLayer layer];
//		[self.layer addSublayer:maskLayer];
//		[self.layer setMask:maskLayer];
//	}
//	
//	CGRect bounds = self.bounds;
//	UIBezierPath * maskPath = [UIBezierPath bezierPathWithRoundedRect:bounds
//													byRoundingCorners:(UIRectCornerTopLeft|UIRectCornerTopRight)
//														  cornerRadii:CGSizeMake(4.0, 4.0)];
//	if ( maskPath && maskLayer )
//	{
//		maskLayer.frame = bounds;
//		maskLayer.path = maskPath.CGPath;
//		maskLayer.name = @"maskLayer";
//	}
}

- (void)handleNotification:(NSNotification *)notification
{
	if ( [notification is:self.BACKGROUND_CHANGED] )
	{
		[self setNeedsDisplay];
	}
}

- (void)handleUISignal:(BeeUISignal *)signal
{
	if ( _navigationController )
	{
		UIViewController * vc = _navigationController.topViewController;
		if ( vc )
		{
			[signal forward:vc];
		}
	}
	else
	{
		[super handleUISignal:signal];
	}
}

- (void)setBackgroundImage:(UIImage *)image
{
	[image retain];
	[_backgroundImage release];
	_backgroundImage = image;
	
	[self setNeedsDisplay];
}

+ (void)setBackgroundImage:(UIImage *)image
{
	[image retain];
	[__defaultBackgroundImage release];
	__defaultBackgroundImage = image;
	
	[[NSNotificationCenter defaultCenter] postNotificationName:self.BACKGROUND_CHANGED object:nil];
}

@end

#endif	// #if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
