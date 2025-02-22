/*
 * Backpack - Skyscanner's Design System
 *
 * Copyright 2018 Skyscanner Ltd
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */
#import "BPKNavigationBar.h"

#import <Backpack/Color.h>
#import <Backpack/Common.h>
#import <Backpack/DarkMode.h>
#import <Backpack/Label.h>
#import <Backpack/Spacing.h>

#import "BPKNavigationBarButton.h"
#import "BPKNavigationBarLargeTitleView.h"
#import "BPKNavigationBarTitleView.h"

const CGFloat BPKNavigationBarExpandedFullHeight = 96;

NS_ASSUME_NONNULL_BEGIN

@interface BPKNavigationBar ()
// Title views
@property(nonatomic, strong, readonly) BPKNavigationBarLargeTitleView *largeTitleView;
@property(nonatomic, strong, readonly) BPKNavigationBarTitleView *titleView;

// Background
@property(nonatomic, strong, readonly) UIView *backgroundView;
@property(nonatomic, strong, readonly) UIView *borderView;
@property(nonatomic, strong, readonly) UIBlurEffect *backgroundEffect;
@property(nonatomic, strong, readonly) UIColor *borderViewBackgroundColor;
@property(nonatomic, strong, readonly) UIColor *contentColor;
@property(nonatomic, strong, readonly) UIColor *backgroundViewColor;

// Constraints
@property(nonatomic, strong) NSLayoutConstraint *heightConstraint;
@property(nonatomic, strong) NSLayoutConstraint *backgroundViewTopConstraint;

/**
 * Keeps track of the state of the navigation bar. Will be `YES`
 * when the large title is hidden and the title is displayed in
 * `titleView`. Otherwise it's `NO`.
 * The default values is `NO`.
 */
@property(nonatomic, assign, getter=isCollapsed) BOOL collapsed;

@property(nonatomic) CGFloat baseYOffset;
@property(nonatomic) CGFloat baseLargeTitleFontSize;
@end

@implementation BPKNavigationBar
@synthesize largeTitleView = _largeTitleView, titleView = _titleView, backgroundView = _backgroundView, borderView = _borderView,
            backgroundEffect = _backgroundEffect;

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];

    if (self) {
        [self setUp];
    }

    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];

    if (self) {
        [self setUp];
    }

    return self;
}

- (void)setTitle:(NSString *)title {
    BPKAssertMainThread();
    if (title != _title) {
        _title = [title copy];

        self.largeTitleView.titleLabel.text = _title;
        self.titleView.titleLabel.text = _title;
        self.baseLargeTitleFontSize = self.largeTitleView.titleLabel.font.pointSize;
    }
}

- (void)setStyle:(BPKNavigationBarStyle)style {
    BPKAssertMainThread();
    if (style != _style) {
        _style = style;
        [self updateAppearance];
    }
}

- (void)setLargeTitleTextColor:(UIColor *_Nullable)largeTitleTextColor {
    BPKAssertMainThread();
    if (largeTitleTextColor != _largeTitleTextColor) {
        _largeTitleTextColor = largeTitleTextColor;
        [self updateAppearance];
    }
}

- (UIEdgeInsets)largeTitleLayoutMargins {
    return self.largeTitleView.layoutMargins;
}

- (void)setLargeTitleLayoutMargins:(UIEdgeInsets)largeTitleLayoutMargins {
    self.largeTitleView.layoutMargins = largeTitleLayoutMargins;
}

- (NSTextAlignment)largeTitleTextAlignment {
    return self.largeTitleView.titleLabel.textAlignment;
}

- (void)setLargeTitleTextAlignment:(NSTextAlignment)largeTitleTextAlignment {
    self.largeTitleView.titleLabel.textAlignment = largeTitleTextAlignment;
}

- (void)setUpForScrollview:(UIScrollView *)scrollView {
    scrollView.contentInset = UIEdgeInsetsMake(BPKNavigationBarExpandedFullHeight, 0, 0, 0);
    scrollView.scrollIndicatorInsets = scrollView.contentInset;
}

- (CGFloat)calculateYOffset:(UIScrollView *)scrollView {
    return (scrollView.adjustedContentInset.top - scrollView.contentInset.top) + scrollView.contentOffset.y;
}

- (void)makeTitleVisibleWithScrollView:(UIScrollView *)scrollView {
    CGFloat adjustedYOffset = [self calculateYOffset:scrollView];
    CGFloat thresholdPoint = self.baseYOffset + (BPKNavigationBarLargeTitleViewHeight / 2.0);

    if (adjustedYOffset <= self.baseYOffset) {
        // There is no need to adjust as the large title is fully in view
        return;
    } else if (adjustedYOffset >= self.baseYOffset + BPKNavigationBarLargeTitleViewHeight) {
        // There is no need to adjust as the small title is fully in view
        return;
    }

    CGFloat adjustmentRequired = 0.0;
    if (adjustedYOffset < thresholdPoint) {
        // A small adjustment is needed to bring the large title fully into view
        adjustmentRequired = adjustedYOffset - self.baseYOffset;
    } else {
        // A small adjustment is needed to bring the small title fully into view
        adjustmentRequired = adjustedYOffset - (self.baseYOffset + BPKNavigationBarLargeTitleViewHeight);
    }

    [scrollView setContentOffset:CGPointMake(scrollView.contentOffset.x, scrollView.contentOffset.y - adjustmentRequired) animated:YES];
}

- (void)updateWithScrollView:(UIScrollView *)scrollView {
    CGFloat adjustedYOffset = [self calculateYOffset:scrollView];

    if (adjustedYOffset >= -BPKNavigationBarTitleHeight) {
        // Collapsed state

        // Making modifications on each scroll is very expensive.
        // To prevent extra work the changes between collapsed and expanded
        // are only executed a single time per transition.
        if (!self.isCollapsed) {
            self.heightConstraint.constant = BPKNavigationBarTitleHeight;
            scrollView.contentInset = UIEdgeInsetsMake(BPKNavigationBarTitleHeight, 0, 0, 0);
            scrollView.scrollIndicatorInsets = scrollView.contentInset;
            self.titleView.showsContent = YES;
            self.borderView.alpha = 1.0;

            self.collapsed = YES;
            [self updateAppearance];
        }
    } else {
        // Expanded state
        CGFloat absAdjustedYOffset = fabs(adjustedYOffset);
        self.heightConstraint.constant = absAdjustedYOffset;
        scrollView.scrollIndicatorInsets = UIEdgeInsetsMake(absAdjustedYOffset, 0, 0, 0);

        if (absAdjustedYOffset <= BPKNavigationBarExpandedFullHeight) {
            scrollView.contentInset = UIEdgeInsetsMake(absAdjustedYOffset, 0, 0, 0);
        }

        // Making modifications on each scroll is very expensive.
        // To prevent extra work the changes between collapsed and expanded
        // are only executed a single time per transition.
        if (self.isCollapsed) {
            self.titleView.showsContent = NO;
            self.borderView.alpha = 0.0;

            self.collapsed = NO;
            [self updateAppearance];
        }

        self.largeTitleView.titleLabel.font = [self.largeTitleView.titleLabel.font fontWithSize:[self fontSizeForScrollOffset:adjustedYOffset]];
    }
}

- (CGFloat)fontSizeForScrollOffset:(CGFloat)offset {
    CGFloat netOffset = fabs(self.baseYOffset - offset);
    CGFloat fontSizeDiff = MIN(4.0, 4.0 * netOffset / 120.0);
    return self.baseLargeTitleFontSize + fontSizeDiff;
}

- (void)didMoveToWindow {
    [super didMoveToWindow];

    if (self.window) {
        // On iOS 11 on iPhones with a 20pt tall status bar the value of
        // safeAreaInsets.top is `0` rather than 20.
        self.backgroundViewTopConstraint.constant = -MAX(self.window.safeAreaInsets.top, 20);
    }
}

#pragma mark - Private

- (BPKNavigationBarLargeTitleView *)largeTitleView {
    if (!_largeTitleView) {
        _largeTitleView = [[BPKNavigationBarLargeTitleView alloc] initWithFrame:CGRectZero];
        _largeTitleView.translatesAutoresizingMaskIntoConstraints = NO;
        _largeTitleView.clipsToBounds = YES;
    }

    return _largeTitleView;
}

- (BPKNavigationBarTitleView *)titleView {
    if (!_titleView) {
        _titleView = [[BPKNavigationBarTitleView alloc] initWithFrame:CGRectZero];
        _titleView.translatesAutoresizingMaskIntoConstraints = NO;
    }

    return _titleView;
}

- (UIVisualEffectView *)backgroundView {
    if (!_backgroundView) {
        _backgroundView = [[UIVisualEffectView alloc] initWithEffect:nil];
        _backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    }

    return _backgroundView;
}

- (UIView *)borderView {
    if (!_borderView) {
        _borderView = [[UIView alloc] initWithFrame:CGRectZero];
        _borderView.translatesAutoresizingMaskIntoConstraints = NO;
        _borderView.backgroundColor = self.borderViewBackgroundColor;
        _borderView.alpha = 0.0;
    }

    return _borderView;
}

- (BPKNavigationBarButton *)leftButton {
    if (!_leftButton) {
        _leftButton = [[BPKNavigationBarButton alloc] init];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.title = @"";
        _leftButton.imagePosition = BPKButtonImagePositionLeading;
        _leftButton.hidden = YES;
    }
    return _leftButton;
}

- (BPKNavigationBarButton *)rightButton {
    if (!_rightButton) {
        _rightButton = [[BPKNavigationBarButton alloc] init];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.title = @"";
        _rightButton.hidden = YES;
    }
    return _rightButton;
}

- (void)setUp {
    _collapsed = NO;
    _largeTitleTextColor = nil;
    self.baseYOffset = -BPKNavigationBarExpandedFullHeight;
    self.backgroundColor = BPKColor.clear;
    [self addSubview:self.backgroundView];
    [self addSubview:self.borderView];
    [self addSubview:self.largeTitleView];
    [self addSubview:self.titleView];
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self updateAppearance];

    self.heightConstraint = [self.heightAnchor constraintEqualToConstant:BPKNavigationBarExpandedFullHeight];

    NSLayoutConstraint *largeTitleViewHeightConstraint =
        [self.largeTitleView.heightAnchor constraintGreaterThanOrEqualToConstant:BPKNavigationBarLargeTitleViewHeight];
    largeTitleViewHeightConstraint.priority = UILayoutPriorityDefaultHigh;

    self.backgroundViewTopConstraint = [self.backgroundView.topAnchor constraintEqualToAnchor:self.topAnchor constant:0.0];

    [NSLayoutConstraint activateConstraints:@[
        // Background view
        self.backgroundViewTopConstraint,
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],

        // Title View
        [self.titleView.topAnchor constraintEqualToAnchor:self.topAnchor],
        [self.titleView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.titleView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.titleView.bottomAnchor constraintLessThanOrEqualToAnchor:self.bottomAnchor],
        [self.titleView.heightAnchor constraintEqualToConstant:BPKNavigationBarTitleHeight],

        // Left Button
        [self.leftButton.leadingAnchor constraintEqualToAnchor:self.titleView.leadingAnchor constant:BPKSpacingMd],
        [self.leftButton.centerYAnchor constraintEqualToAnchor:self.titleView.centerYAnchor],

        // Right Button
        [self.titleView.trailingAnchor constraintEqualToAnchor:self.rightButton.trailingAnchor constant:BPKSpacingBase],
        [self.rightButton.centerYAnchor constraintEqualToAnchor:self.titleView.centerYAnchor],

        // Border
        [self.borderView.topAnchor constraintEqualToAnchor:self.titleView.bottomAnchor],
        [self.borderView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.borderView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.borderView.heightAnchor constraintEqualToConstant:(1 / self.contentScaleFactor)],

        // Large Title View
        [self.largeTitleView.topAnchor constraintGreaterThanOrEqualToAnchor:self.titleView.bottomAnchor],
        [self.largeTitleView.leadingAnchor constraintEqualToAnchor:self.leadingAnchor],
        [self.largeTitleView.trailingAnchor constraintEqualToAnchor:self.trailingAnchor],
        [self.largeTitleView.bottomAnchor constraintEqualToAnchor:self.bottomAnchor],
        largeTitleViewHeightConstraint,

        self.heightConstraint,
    ]];
}

- (UIViewController *_Nullable)findNearestViewController {
    UIResponder *responder = self;

    while (responder && ![responder isKindOfClass:[UIViewController class]]) {
        responder = [responder nextResponder];
    }

    return (UIViewController *)responder;
}

- (void)updateAppearance {
    self.backgroundView.backgroundColor = self.backgroundViewColor;

    self.leftButton.linkContentColor = self.contentColor;
    self.rightButton.linkContentColor = self.contentColor;

    if (self.largeTitleTextColor) {
        self.largeTitleView.titleLabel.textColor = self.largeTitleTextColor;
    } else {
        self.largeTitleView.titleLabel.textColor = self.contentColor;
    }
}

- (UIColor *)borderViewBackgroundColor {
    return [BPKColor dynamicColorWithLightVariant:BPKColor.surfaceHighlightColor darkVariant:BPKColor.textSecondaryColor];
}

- (UIColor *)contentColor {
    if (!self.collapsed && self.style == BPKNavigationBarStyleOnImage) {
        return BPKColor.textOnDarkColor;
    }
    return BPKColor.textPrimaryColor;
}

- (UIColor *)backgroundViewColor {
    if (self.collapsed) {
        return BPKColor.canvasColor;
    }
    return BPKColor.clear;
}

@end

NS_ASSUME_NONNULL_END
