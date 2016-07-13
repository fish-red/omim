#import "MWMNavigationInfoView.h"
#import "Common.h"
#import "MWMLocationHelpers.h"
#import "MWMLocationManager.h"
#import "MWMRouter.h"
#import "UIFont+MapsMeFonts.h"
#import "UIImageView+Coloring.h"

#include "geometry/angles.hpp"

namespace
{
CGFloat constexpr kTurnsiPhoneWidth = 96;
CGFloat constexpr kTurnsiPadWidth = 140;
}  // namespace

@interface MWMNavigationInfoView ()<MWMLocationObserver>

@property(weak, nonatomic) IBOutlet UIView * streetNameView;
@property(weak, nonatomic) IBOutlet UILabel * streetNameLabel;
@property(weak, nonatomic) IBOutlet UIView * turnsView;
@property(weak, nonatomic) IBOutlet UIImageView * nextTurnImageView;
@property(weak, nonatomic) IBOutlet UILabel * distanceToNextTurnLabel;
@property(weak, nonatomic) IBOutlet UIView * secondTurnView;
@property(weak, nonatomic) IBOutlet UIImageView * secondTurnImageView;
@property(weak, nonatomic) IBOutlet NSLayoutConstraint * turnsWidth;

@property(nonatomic) BOOL isVisible;

@property(weak, nonatomic) MWMNavigationDashboardEntity * navigationInfo;

@end

@implementation MWMNavigationInfoView

- (void)addToView:(UIView *)superview
{
  self.isVisible = YES;
  if (IPAD)
  {
    self.turnsWidth.constant = kTurnsiPadWidth;
    self.distanceToNextTurnLabel.font = [UIFont bold36];
  }
  else
  {
    self.turnsWidth.constant = kTurnsiPhoneWidth;
    self.distanceToNextTurnLabel.font = [UIFont bold24];
  }
  NSAssert(superview != nil, @"Superview can't be nil");
  if ([superview.subviews containsObject:self])
    return;
  [superview insertSubview:self atIndex:0];
}

- (void)remove { self.isVisible = NO; }
- (void)layoutSubviews
{
  if (!CGRectEqualToRect(self.frame, self.defaultFrame))
  {
    self.frame = self.defaultFrame;
    [self setNeedsLayout];
  }
  if (!self.isVisible)
    [self removeFromSuperview];
  [super layoutSubviews];
}

- (void)setIsVisible:(BOOL)isVisible
{
  _isVisible = isVisible;
  [self setNeedsLayout];
  if (isVisible && [MWMRouter router].type == routing::RouterType::Pedestrian)
    [MWMLocationManager addObserver:self];
  else
    [MWMLocationManager removeObserver:self];
}

- (CGFloat)visibleHeight { return self.streetNameView.maxY; }
#pragma mark - MWMNavigationDashboardInfoProtocol

- (void)updateNavigationInfo:(MWMNavigationDashboardEntity *)info
{
  self.navigationInfo = info;
  if (info.streetName.length != 0)
  {
    self.streetNameView.hidden = NO;
    self.streetNameLabel.text = info.streetName;
  }
  else
  {
    self.streetNameView.hidden = YES;
  }
  if (info.turnImage)
  {
    self.turnsView.hidden = NO;
    self.nextTurnImageView.image = info.turnImage;
    if (isIOS7)
      [self.nextTurnImageView makeImageAlwaysTemplate];
    self.nextTurnImageView.mwm_coloring = MWMImageColoringWhite;
    self.distanceToNextTurnLabel.text =
        [NSString stringWithFormat:@"%@%@", info.distanceToTurn, info.turnUnits];
    if (info.nextTurnImage)
    {
      self.secondTurnView.hidden = NO;
      self.secondTurnImageView.image = info.nextTurnImage;
      if (isIOS7)
        [self.secondTurnImageView makeImageAlwaysTemplate];
      self.secondTurnImageView.mwm_coloring = MWMImageColoringBlack;
    }
    else
    {
      self.secondTurnView.hidden = YES;
    }
  }
  else
  {
    self.turnsView.hidden = YES;
  }
  self.hidden = self.streetNameView.hidden && self.turnsView.hidden;
}

#pragma mark - MWMLocationObserver

- (void)onHeadingUpdate:(location::CompassInfo const &)info
{
  CLLocation * lastLocation = [MWMLocationManager lastLocation];
  if (!lastLocation)
    return;

  CGFloat const angle =
      ang::AngleTo(lastLocation.mercator,
                   location_helpers::ToMercator(self.navigationInfo.pedestrianDirectionPosition)) +
      info.m_bearing;
  self.nextTurnImageView.transform = CGAffineTransformMakeRotation(M_PI_2 - angle);
}

#pragma mark - Properties

- (CGRect)defaultFrame
{
  return CGRectMake(self.leftBound, 0.0, self.superview.width - self.leftBound,
                    self.superview.height);
}

- (void)setLeftBound:(CGFloat)leftBound
{
  _leftBound = MAX(leftBound, 0.0);
  [self setNeedsLayout];
}

@end