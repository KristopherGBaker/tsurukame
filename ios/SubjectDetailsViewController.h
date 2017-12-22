#import <UIKit/UIKit.h>

#import "DataLoader.h"
#import "LocalCachingClient.h"
#import "SubjectDetailsView.h"
#import "proto/Wanikani.pbobjc.h"

@interface SubjectDetailsViewController : UIViewController

@property (nonatomic) DataLoader *dataLoader;
@property (nonatomic) LocalCachingClient *localCachingClient;
@property (nonatomic) WKSubject *subject;

@end
