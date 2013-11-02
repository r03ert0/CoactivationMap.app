//
//  MyVolumeView.h
//  pac_explorer
//
//  Created by Roberto Toro on 06/Jun/2006.
//  Copyright 2006 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#include "defaults.h"
#include "coactivation.h"
#include "colourmap.h"
#include "fdr.h"


@interface MyVolumeView : NSView
{
	id					ctrl;
	GlobalDefaults		*gd;

	NSMutableDictionary	*settings;
	NSImage				*image;
	NSImage				*tmpl_image;
	float				zo;
	
	char	*tmpl;
	short	*vol,*sum;
}
-(void)setSettings:(NSMutableDictionary*)newSettings;
-(void)setParentController:(id)newCtrl;
-(void)setGlobalDefaults:(GlobalDefaults*)theGd;
-(void)setVolume:(short*)newVol;
-(void)draw;
-(char*)tmpl;

-(float)fdr:(float)q;
-(void)savePeaks;
@end
