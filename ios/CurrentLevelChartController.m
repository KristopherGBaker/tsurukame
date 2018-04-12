#import "CurrentLevelChartController.h"

#import "DataLoader.h"
#import "Style.h"
#import "proto/Wanikani+Convenience.h"

#import "wk-Swift.h"

enum PieSlice {
  LockedPieSlice,
  LessonPieSlice,
  NovicePieSlice,
  ApprenticePieSlice,
  GuruPieSlice,
  
  PieSlice_Count
};

static NSString *PieSliceLabel(enum PieSlice slice) {
  switch (slice) {
    case LockedPieSlice: return @"Locked";
    case LessonPieSlice: return @"Lesson";
    case NovicePieSlice: return @"Novice";
    case ApprenticePieSlice: return @"Apprentice";
    case GuruPieSlice: return @"Guru";
      
    case PieSlice_Count: break;
  }
  return nil;
}

static UIColor *PieSliceColor(enum PieSlice slice, UIColor *baseColor) {
  CGFloat saturationMod = 1.f;
  CGFloat brightnessMod = 1.f;
  switch (slice) {
    case LockedPieSlice: return [UIColor colorWithWhite:0.8f alpha:1];
    case LessonPieSlice: return [UIColor colorWithWhite:0.6f alpha:1];
    case NovicePieSlice: saturationMod = 0.4f; break;
    case ApprenticePieSlice: saturationMod = 0.6f; break;
    default: break;
  }
  CGFloat hue, saturation, brightness, alpha;
  [baseColor getHue:&hue saturation:&saturation brightness:&brightness alpha:&alpha];
  return [UIColor colorWithHue:hue
                    saturation:saturation*saturationMod
                    brightness:brightness*brightnessMod
                         alpha:alpha];
}

static void UnsetAllLabels(ChartViewBase *view) {
  PieChartDataSet *dataSet = (PieChartDataSet *)view.data.dataSets[0];
  for (PieChartDataEntry *otherEntry in dataSet.values) {
    otherEntry.label = nil;
  }
}

@interface CurrentLevelChartController () <ChartViewDelegate>
@end

@implementation CurrentLevelChartController {
  DataLoader *_dataLoader;
}

- (instancetype)initWithChartView:(PieChartView *)view
                      subjectType:(WKSubject_Type)subjectType
                       dataLoader:(nonnull DataLoader *)dataLoader {
  self = [super init];
  if (self) {
    _subjectType = subjectType;
    _dataLoader = dataLoader;
    _view = view;
    _view.chartDescription = nil;
    _view.legend.enabled = NO;
    _view.holeRadiusPercent = 0.2f;
    _view.delegate = self;
  }
  return self;
}

- (void)update:(NSArray<WKAssignment *> *)maxLevelAssignments {
  int sliceSizes[PieSlice_Count] = {0};
  int total = 0;
  for (WKAssignment *assignment in maxLevelAssignments) {
    if (assignment.subjectType != _subjectType) {
      continue;
    }
    enum PieSlice slice = LockedPieSlice;
    if (assignment.isLessonStage) {
      slice = LessonPieSlice;
    } else if (assignment.srsStage <= 1) {
      slice = NovicePieSlice;
    } else if (assignment.srsStage < 5) {
      slice = ApprenticePieSlice;
    } else {
      slice = GuruPieSlice;
    }
    sliceSizes[slice] ++;
    total ++;
  }
  sliceSizes[LockedPieSlice] = [_dataLoader subjectsByLevel:maxLevelAssignments[0].level
                                                     byType:_subjectType] - total;
  
  UIColor *baseColor = WKColor2ForSubjectType(_subjectType);
  NSMutableArray<PieChartDataEntry *> *values = [NSMutableArray array];
  NSMutableArray<UIColor *> *colors = [NSMutableArray array];
  for (int i = 0; i < PieSlice_Count; ++i) {
    if (sliceSizes[i] <= 0) {
      continue;
    }
    [values addObject:[[PieChartDataEntry alloc] initWithValue:sliceSizes[i] data:@(i)]];
    [colors addObject:PieSliceColor(i, baseColor)];
  }
  
  PieChartDataSet *dataSet = [[PieChartDataSet alloc] initWithValues:values];
  dataSet.valueTextColor = [UIColor darkGrayColor];
  dataSet.entryLabelColor = [UIColor blackColor];
  dataSet.valueFont = [UIFont systemFontOfSize:10.f];
  dataSet.colors = colors;
  dataSet.sliceSpace = 1.f;  // Space between slices.
  dataSet.selectionShift = 10.f;  // Amount to grow when tapped.
  dataSet.valueLineColor = nil;
  dataSet.valueFormatter = [[ChartDefaultValueFormatter alloc] initWithDecimals:0];
  
  PieChartData *data = [[PieChartData alloc] initWithDataSet:dataSet];
  _view.data = data;
}

- (void)chartValueSelected:(ChartViewBase *)chartView
                     entry:(ChartDataEntry *)entry
                 highlight:(ChartHighlight *)highlight {
  [self chartValueNothingSelected:chartView];
  
  // Set this label.
  PieChartDataEntry *pieEntry = (PieChartDataEntry *)entry;
  pieEntry.label = PieSliceLabel([pieEntry.data intValue]);
}

- (void)chartValueNothingSelected:(ChartViewBase *)chartView {
  // Unset all the labels.
  UnsetAllLabels(chartView);
  
  // Bit of a hack - unselect everything in the other charts.
  for (UIView *view in chartView.superview.subviews) {
    if (view == chartView || ![view isKindOfClass:PieChartView.class]) {
      continue;
    }
    PieChartView *otherChart = (PieChartView *)view;
    [otherChart highlightValue:nil callDelegate:NO];
    UnsetAllLabels(otherChart);
  }
}

@end
