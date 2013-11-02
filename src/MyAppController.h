/* MyAppController */

#import <Cocoa/Cocoa.h>
#import <WebKit/WebKit.h>
#import "MyVolumeView.h"

@interface MyAppController : NSObject
{
    IBOutlet NSTextField		*fdrTextField;
    IBOutlet NSTextField		*tagTextField;
    IBOutlet NSObjectController	*settings;
    IBOutlet MyVolumeView		*stereo;
	IBOutlet WebView			*help;

	int				oxs,oxc,oxa;
	short			*vol;
	GlobalDefaults	gd;
}
- (IBAction)fdr:(id)sender;
- (IBAction)redrawAndUpdate:(id)sender;
- (IBAction)saveImage:(id)sender;
- (IBAction)savePeaks:(id)sender;
- (IBAction)update:(id)sender;

-(void)loadDataAtSag:(int)s cor:(int)c axi:(int)a;
@end
