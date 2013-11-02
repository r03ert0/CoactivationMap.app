#import "MyVolumeView.h"
#include "defaults.h"

@implementation MyVolumeView

- (id)initWithFrame:(NSRect)frameRect
{
	if ((self = [super initWithFrame:frameRect]) != nil)
	{
		gd=nil;
	}
	return self;
}

- (void)drawRect:(NSRect)rect
{
	[[NSColor blackColor] set];
	NSRectFill(rect);

	if(gd==nil)
		return;
	
	int		view=[[settings objectForKey:@"ysca"] intValue];
	int		xs=[[settings objectForKey:@"xsag"] intValue];
	int		xc=[[settings objectForKey:@"xcor"] intValue];
	int		xa=[[settings objectForKey:@"xaxi"] intValue];
	int		ys=[[settings objectForKey:@"ysag"] intValue];
	int		yc=[[settings objectForKey:@"ycor"] intValue];
	int		ya=[[settings objectForKey:@"yaxi"] intValue];
	float	t=[[settings objectForKey:@"mix"] floatValue]/100.0;
	NSBezierPath	*bp=nil;
	
	NSSize s=[image size];
	NSSize ts=[tmpl_image size];
	
	[[NSGraphicsContext currentContext] setImageInterpolation:NSImageInterpolationNone];
	[tmpl_image drawInRect:(NSRect){0,0,ts.width*zo,ts.height*zo} fromRect:(NSRect){0,0,ts.width,ts.height} operation:NSCompositeCopy fraction:1];
	[image drawInRect:(NSRect){0,0,s.width*gd->VSIZE*zo,s.height*gd->VSIZE*zo} fromRect:(NSRect){0,0,s.width,s.height} operation:NSCompositeSourceAtop fraction:t];

	[[NSColor whiteColor] set];
	switch(view)
	{
		case 0: // Sagital
			if(xs==ys)
				bp=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(gd->VSIZE*zo*xc,gd->VSIZE*zo*xa,gd->VSIZE*zo,gd->VSIZE*zo)];
			NSFrameRect(NSMakeRect(gd->VSIZE*zo*yc,gd->VSIZE*zo*ya,gd->VSIZE*zo,gd->VSIZE*zo));
			break;
		case 1: // Coronal
			if(xc==yc)
				bp=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(gd->VSIZE*zo*xs,gd->VSIZE*zo*xa,gd->VSIZE*zo,gd->VSIZE*zo)];
			NSFrameRect(NSMakeRect(gd->VSIZE*zo*ys,gd->VSIZE*zo*ya,gd->VSIZE*zo,gd->VSIZE*zo));
			break;
		case 2: // Axial
			if(xa==ya)
				bp=[NSBezierPath bezierPathWithOvalInRect:NSMakeRect(gd->VSIZE*zo*xs,gd->VSIZE*zo*xc,gd->VSIZE*zo,gd->VSIZE*zo)];
			NSFrameRect(NSMakeRect(gd->VSIZE*zo*ys,gd->VSIZE*zo*yc,gd->VSIZE*zo,gd->VSIZE*zo));
			break;
	}
	if (bp)
		[bp fill];
}
-(void)mouseDown:(NSEvent*)e
{
	[self mouseDragged:e];
}
-(void)mouseDragged:(NSEvent*)e
{
	NSPoint	m=[self convertPoint:[e locationInWindow] fromView:nil];
	int		view=[[settings objectForKey:@"ysca"] intValue];
	int		xs=[[settings objectForKey:@"xsag"] intValue];
	int		xc=[[settings objectForKey:@"xcor"] intValue];
	int		xa=[[settings objectForKey:@"xaxi"] intValue];
	int		ys=[[settings objectForKey:@"ysag"] intValue];
	int		yc=[[settings objectForKey:@"ycor"] intValue];
	int		ya=[[settings objectForKey:@"yaxi"] intValue];
	int		sync=[[settings objectForKey:@"sync"] intValue];
	int		s,c,a;
	short	v,s1,s2;
	
	switch(view)
	{
		case 0: // Sagital
			s=ys;
			c=m.x/zo/gd->VSIZE;
			a=m.y/zo/gd->VSIZE;
			break;
		case 1: // Coronal
			s=m.x/zo/gd->VSIZE;
			c=yc;
			a=m.y/zo/gd->VSIZE;
			break;
		case 2: // Axial
			s=m.x/zo/gd->VSIZE;
			c=m.y/zo/gd->VSIZE ;
			a=ya;
			break;
	}
    
    if(s<0||s>=gd->LR||c<0||c>=gd->PA||a<0||a>=gd->IS)
        return;

	s1=sum[xa*gd->PA*gd->LR+xc*gd->LR+xs];
	s2=sum[a*gd->PA*gd->LR+c*gd->LR+s];
	v=vol[a*gd->PA*gd->LR+c*gd->LR+s];
	
	[settings setObject:[NSString stringWithFormat:@"a:%i b:%i k:%i lr:%.1f",s1,s2,v,likelihood_ratio(s1, s2, v, gd->N)] forKey:@"value"];

	if(sync)
	{
		[settings setValue:[NSNumber numberWithInt:s] forKey:@"xsag"];
		[settings setValue:[NSNumber numberWithInt:c] forKey:@"xcor"];
		[settings setValue:[NSNumber numberWithInt:a] forKey:@"xaxi"];
	}
	else
	{
		[settings setValue:[NSNumber numberWithInt:s] forKey:@"ysag"];
		[settings setValue:[NSNumber numberWithInt:c] forKey:@"ycor"];
		[settings setValue:[NSNumber numberWithInt:a] forKey:@"yaxi"];
	}
	
	[ctrl redrawAndUpdate:self];
}
#pragma mark -
-(char*)tmpl
{
	return tmpl;
}
-(void)setSettings:(NSMutableDictionary*)newSettings
{
	settings=newSettings;
}
-(void)setParentController:(id)newCtrl
{
	ctrl=newCtrl;
}
-(void)setGlobalDefaults:(GlobalDefaults*)theGd
{
    gd=theGd;

    printf("loading defaults\n");
    NSString    *c=[[[NSUserDefaultsController sharedUserDefaultsController] values]valueForKey:@"dataDirectoryPath"];

    if(c==nil)
    {
        [[ctrl prefMsg] setStringValue:@"CoactivationMap requires a local copy of the Brain Coactivation Map data. Choose the path to the data or download it from NITRC (~2 GB), and restart the application."];
        [[ctrl pref] makeKeyAndOrderFront:self];
        return;
    }

    //NSString	*c=[NSString stringWithFormat:@"%@/..",[[NSBundle mainBundle] bundlePath]];
    NSString	*d=[NSString stringWithFormat:@"%@/defaults.txt",c];
    NSString	*s=[NSString stringWithFormat:@"%@/sum.img",c];
    NSString	*t=[NSString stringWithFormat:@"%@/colin180.img",c];
    FILE		*f;
    int         result;
    
    result=defaults((char*)[d UTF8String],gd);
    
    if(result==0)
    {
        [[ctrl prefMsg] setStringValue:@"The current path to the Brain Coactivation Map data does not contain the appropriate type of data. Change the path or download a new copy from NITRC (~2 GB), and restart the application."];
        [[ctrl pref] makeKeyAndOrderFront:self];
        return;
    }
    strcpy(gd->coin_dir,(char*)[c UTF8String]);
    strcpy(gd->sum_file,(char*)[s UTF8String]);
    strcpy(gd->temp_file,(char*)[t UTF8String]);
    
    tmpl=(char*)calloc(gd->TSAG*gd->TCOR*gd->TAXI,sizeof(char));
    f=fopen((char*)[t UTF8String],"r");
    fread(tmpl,gd->TSAG*gd->TCOR*gd->TAXI,sizeof(char),f);
    fclose(f);

    sum=(short*)calloc(gd->TSAG*gd->TCOR*gd->TAXI,sizeof(short));
    f=fopen(gd->sum_file,"r");
    fread(sum,gd->TSAG*gd->TCOR*gd->TAXI,sizeof(short),f);
    fclose(f);

    zo=2.32; // zoom
    image=nil;
    tmpl_image=nil;
    [[self window] makeFirstResponder:self];
    [[self window] setAcceptsMouseMovedEvents:YES];
}

-(void)setVolume:(short*)newVol
{
	vol=newVol;
}
// result_vector = vector x matrix
void v_m(float *r,float *v,float *m)
{
	// v=1x3
	// m=4x4
	// r=1x3
	r[0]=v[0]*m[0*4+0]+v[1]*m[1*4+0]+v[2]*m[2*4+0] + m[3*4+0];
	r[1]=v[0]*m[0*4+1]+v[1]*m[1*4+1]+v[2]*m[2*4+1] + m[3*4+1];
	r[2]=v[0]*m[0*4+2]+v[1]*m[1*4+2]+v[2]*m[2*4+2] + m[3*4+2];
}
-(void)draw
{
	int		xs=[[settings objectForKey:@"xsag"] intValue];
	int		xc=[[settings objectForKey:@"xcor"] intValue];
	int		xa=[[settings objectForKey:@"xaxi"] intValue];
	int		ys=[[settings objectForKey:@"ysag"] intValue];
	int		yc=[[settings objectForKey:@"ycor"] intValue];
	int		ya=[[settings objectForKey:@"yaxi"] intValue];
	int		view=[[settings objectForKey:@"ysca"] intValue];
	float	thrs,vox[3],tal[3];
	int		i1,i2;
	float	val,disp;
	unsigned char	*b;
	int		i,x,y,W,H,bpr;
	NSBitmapImageRep	*bmp;
	NSBitmapImageRep	*tbmp;
	
	vox[0]=xs;	vox[1]=xc;	vox[2]=xa;	v_m(tal,vox,gd->v2t);
	[settings setObject:[NSString stringWithFormat:@"MNI %.2f,%.2f,%.2f",tal[0],tal[1],tal[2]] forKey:@"xmni"];
	vox[0]=ys;	vox[1]=yc;	vox[2]=ya;	v_m(tal,vox,gd->v2t);
	[settings setObject:[NSString stringWithFormat:@"MNI %.2f,%.2f,%.2f",tal[0],tal[1],tal[2]] forKey:@"ymni"];
	
	i1=xa*gd->PA*gd->LR+xc*gd->LR+xs;
	
	thrs=[[settings objectForKey:@"thresh"] floatValue];

	// 1. Data volume
	switch(view)
	{	case 0:	W=gd->PA; H=gd->IS; break; // sagital
		case 1:	W=gd->LR, H=gd->IS; break; // coronal
		case 2:	W=gd->LR; H=gd->PA; break; // axial
	}
	bmp=[[NSBitmapImageRep alloc]	initWithBitmapDataPlanes:NULL pixelsWide:W pixelsHigh:H
									bitsPerSample:8 samplesPerPixel:4 hasAlpha:YES isPlanar:NO
									colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	b=(unsigned char*)[bmp bitmapData];
	bpr=[bmp bytesPerRow];

	for(y=0;y<H;y++)
	for(x=0;x<W;x++)
	{	i=bpr*(H-1-y)+x*4;
		b[i]=b[i+1]=b[i+2]=b[i+3]=0;
		
		switch(view)
		{	case 0:i2=y*gd->PA*gd->LR+x*gd->LR+ys; break;
			case 1:i2=y*gd->PA*gd->LR+yc*gd->LR+x; break;
			case 2:i2=ya*gd->PA*gd->LR+y*gd->LR+x; break;
		}
		
		if(vol[i2])
        {
            val=likelihood_ratio(sum[i1], sum[i2], vol[i2],gd->N);
            disp=val/400.0;
            
            if(disp>1)	disp=1;
            if(disp<-1)	disp=-1;
        }
        else
            disp=0;
		if(fabs(val)>=thrs || (val!=val))
			colourmap(0.5+0.5*disp,&b[i],NEGPOS);
	}

	if(image) [image release];
	image=[NSImage new];
	[image addRepresentation:bmp];
	[bmp release];

	// 2. Template image
	switch(view)
	{	case 0:	W=gd->TCOR; H=gd->TAXI; break; // sagital
		case 1:	W=gd->TSAG, H=gd->TAXI; break; // coronal
		case 2:	W=gd->TSAG; H=gd->TCOR; break; // axial
	}
	tbmp=[[NSBitmapImageRep alloc]	initWithBitmapDataPlanes:NULL pixelsWide:W pixelsHigh:H
									bitsPerSample:8 samplesPerPixel:3 hasAlpha:NO isPlanar:NO
									colorSpaceName:NSCalibratedRGBColorSpace bytesPerRow:0 bitsPerPixel:0];
	b=(unsigned char*)[tbmp bitmapData];
	bpr=[tbmp bytesPerRow];
	for(y=0;y<H;y++)
	for(x=0;x<W;x++)
	{
		i=bpr*(H-1-y)+x*3;
		switch(view)
		{	case 0:val=tmpl[y*gd->TCOR*gd->TSAG+x*gd->TSAG+(int)(ys*gd->VSIZE)];break;
			case 1:val=tmpl[y*gd->TCOR*gd->TSAG+(int)(yc*gd->VSIZE)*gd->TSAG+x];break;
			case 2:val=tmpl[(int)(ya*gd->VSIZE)*gd->TCOR*gd->TSAG+y*gd->TSAG+x];break;
		}
		b[i]=b[i+1]=b[i+2]=val;
	}
	if(tmpl_image) [tmpl_image release];
	tmpl_image=[NSImage new];
	[tmpl_image addRepresentation:tbmp];
	[tbmp release];
}

-(float)fdr:(float)q
{
	// Compute likelihood ratio threshold for false discovery ratio q
	
	int		xs=[[settings objectForKey:@"xsag"] intValue];
	int		xc=[[settings objectForKey:@"xcor"] intValue];
	int		xa=[[settings objectForKey:@"xaxi"] intValue];
	float	*lrv,*pvv;
	float	pvthr,lrthr,l0,l1,p0,p1,m,n;
	int		i1,i,df=1;
	
	i1=xa*gd->PA*gd->LR+xc*gd->LR+xs;
	
	// 1. compute likelihood ratio volume from current coincidence volume
	lrv=(float*)calloc(gd->LR*gd->PA*gd->IS,sizeof(float));
	for(i=0;i<gd->LR*gd->PA*gd->IS;i++)
		if(vol[i])
		{
			lrv[i]=likelihood_ratio(sum[i1],sum[i],vol[i],gd->N);
		}
	
	// 2. compute p-value volume from likelihood ratio volume
	pvv=(float*)calloc(gd->LR*gd->PA*gd->IS,sizeof(float));
	for(i=0;i<gd->LR*gd->PA*gd->IS;i++)
		pvv[i]=1-gammp(df/2.0,lrv[i]/2.0);
	free(lrv);

	// 3. compute p-value threshold corresponding to a fdr of q
	pvthr=fdr_nonparametric(pvv,gd->LR*gd->PA*gd->IS,q);
	free(pvv);
	
	// 4. convert p-value threshold to likelihood ratio threshold
	l0=1;	p0=1-gammp(df/2.0,l0/2.0);
	l1=10;	p1=1-gammp(df/2.0,l1/2.0);
	
	lrthr=0.5*(l0+l1);

	for(i=0;i<10;i++)
	{
		m=(l1-l0)/(p1-p0);
		n=l0-m*p0;
		lrthr=m*pvthr+n;
		if(fabs(pvthr-p0)<fabs(pvthr-p1))
		{
			p1=1-gammp(df/2.0,lrthr/2.0);
			l1=lrthr;
		}
		else
		{
			p0=1-gammp(df/2.0,lrthr/2.0);
			l0=lrthr;
		}
		
		if(fabs(l0-l1)<10e-6)
			break;
	}
	
	return lrthr;
}
-(void)savePeaks
{
	NSSavePanel	*save=[NSSavePanel savePanel];
	int			result;
	FILE		*f;
	
	float	threshold=[[settings objectForKey:@"thresh"] floatValue];
	int		i,x,y,z,R=4;
	int		co[3],sz[3];
	Peak	*peaks;
	int		npeaks;
	
	co[0]=[[settings objectForKey:@"xsag"] intValue];
	co[1]=[[settings objectForKey:@"xcor"] intValue];
	co[2]=[[settings objectForKey:@"xaxi"] intValue];
	sz[0]=gd->LR;
	sz[1]=gd->PA;
	sz[2]=gd->IS;
	
	peaks=(Peak*)calloc(KMAXPEAKS,sizeof(Peak));
	findpeaks(threshold,R,co,sz,sum,vol,gd->N,peaks,&npeaks);

	[save setRequiredFileType:@"txt"];
	[save setCanSelectHiddenExtension:YES];
	result=[save runModal];
	if(result==NSOKButton)
	{
		f=fopen((char*)[[save filename] UTF8String],"w");
		for(i=0;i<npeaks;i++)
		{
			x=peaks[i].a;
			y=peaks[i].b;
			z=peaks[i].c;
			fprintf(f,"%i,%i,%i,%03i\n",(x-22)*4-2,(y-31)*4-2,(z-18)*4,i+1);
		}
		fclose(f);
	}
	free(peaks);
}
@end
