//
//  EGOLoadMoreTableFooterView.h
//
//  Created by Ye Dingding on 10-12-24.
//  Copyright 2010 Intridea, Inc. All rights reserved.
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in
//  all copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
//  THE SOFTWARE.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

typedef enum{
	EGOOPullLoadPulling = 0,
	EGOOPullLoadNormal,
	EGOOPullLoadLoading,
} EGOPullLoadState;

@protocol EGOLoadMoreTableFooterDelegate;

@interface EGOLoadMoreTableFooterView : UIView {
	
	id _delegate;
    BOOL _loadOver;
	EGOPullLoadState _state;
    
    UILabel *_statusLabel;
	UIActivityIndicatorView *_activityView;
}

@property (nonatomic, assign) id <EGOLoadMoreTableFooterDelegate> delegate;

- (void)setLoadOver:(BOOL)loadOver;

- (void)egoLoadMoreScrollViewDidScroll:(UIScrollView *)scrollView;
- (void)egoLoadMoreScrollViewDidEndDragging:(UIScrollView *)scrollView;
- (void)egoLoadMoreScrollViewDataSourceDidFinishedLoading:(UIScrollView *)scrollView;

@end


@protocol EGOLoadMoreTableFooterDelegate
- (void)egoLoadMoreTableFooterDidTriggerLoad:(EGOLoadMoreTableFooterView*)view;
- (BOOL)egoLoadMoreTableFooterDataSourceIsLoading:(EGOLoadMoreTableFooterView*)view;
@optional
- (BOOL)enableEGOLoadMoreTableFooterView;
@end
