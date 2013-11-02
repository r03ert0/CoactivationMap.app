#import "MyAppController.h"
#include "miniz.c"

@implementation MyAppController
-(void)applicationDidFinishLaunching:(NSNotification *)aNotification
{
	[stereo setSettings:[settings content]];
	[stereo setParentController:(id)self];
	[stereo setGlobalDefaults:&gd];

	[[settings content] setValue:[NSNumber numberWithFloat:50] forKey:@"mix"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.LR-1] forKey:@"maxsag"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.PA-1] forKey:@"maxcor"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.IS-1] forKey:@"maxaxi"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.LR/2] forKey:@"xsag"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.PA/2] forKey:@"xcor"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.IS/2] forKey:@"xaxi"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.LR/2] forKey:@"ysag"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.PA/2] forKey:@"ycor"];
	[[settings content] setValue:[NSNumber numberWithInt:gd.IS/2] forKey:@"yaxi"];

	[[settings content] setValue:[NSNumber numberWithInt:0] forKey:@"xsca"];
	[[settings content] setValue:[NSNumber numberWithInt:0] forKey:@"ysca"];
	
	[[settings content] setValue:[NSNumber numberWithFloat:0] forKey:@"thresh"];
	
	[[settings content] setValue:[NSNumber numberWithInt:1] forKey:@"sync"];
	
	[help takeStringURLFrom:self];

	oxs=oxc=oxa=-1;
	vol=(short*)calloc(gd.LR*gd.PA*gd.IS,sizeof(short));

	[self redrawAndUpdate:self];
}
-(NSString*)stringValue
{
	//return @"http://cerebrum.pbwiki.com/coactivationmap";
	return @"https://github.com/r03ert0/CoactivationMap.app/wiki";
}
-(IBAction)redrawAndUpdate:(id)sender
{
	int		sync=[[[settings content] objectForKey:@"sync"] intValue];
	int		xs,xc,xa;

	xs=[[[settings content] objectForKey:@"xsag"] intValue];
	xc=[[[settings content] objectForKey:@"xcor"] intValue];
	xa=[[[settings content] objectForKey:@"xaxi"] intValue];
	if(sync)
	{
		[[settings content] setValue:[NSNumber numberWithInt:xs] forKey:@"ysag"];
		[[settings content] setValue:[NSNumber numberWithInt:xc] forKey:@"ycor"];
		[[settings content] setValue:[NSNumber numberWithInt:xa] forKey:@"yaxi"];
	}

	[self loadDataAtSag:xs cor:xc axi:xa];

	oxs=xs; oxc=xc; oxa=xa;
	[stereo draw];
	[stereo setNeedsDisplay:YES];
}
-(IBAction)update:(id)sender
{
	[stereo setNeedsDisplay:YES];
}
-(IBAction)savePeaks:(id)sender
{
	[stereo savePeaks];
}
-(IBAction)saveImage:(id)sender
{
	NSSavePanel	*save=[NSSavePanel savePanel];
	NSString	*path;
	int			result;
	
	[save setRequiredFileType:@"tif"];
	[save setCanSelectHiddenExtension:YES];
	result=[save runModal];
	if(result==NSOKButton)
	{
		path=[save filename];
	}
}
-(IBAction)fdr:(id)sender
{
	// compute likelihood ratio threshold for false discovery ratio q
	float	q=[fdrTextField floatValue];
	float	thr;

	
	thr=[stereo fdr:q];
	[[settings content] setValue:[NSNumber numberWithFloat:thr] forKey:@"thresh"];
	[self redrawAndUpdate:self];
}
- (IBAction)downloadDataFromNITRC:(id)sender
{
	NSString	*urlText=@"http://www.nitrc.org/projects/cmap/";
	//NSString	*urlText=@"http://www.nitrc.org/frs/?group_id=761&release_id=2410";
	[[NSWorkspace sharedWorkspace] openURL:[NSURL URLWithString:urlText]];
}
- (IBAction)chooseDataPath:(id)sender
{
    NSOpenPanel *op=[NSOpenPanel openPanel];
    NSString	*filename;
    int			result;
    
    [op setCanChooseDirectories:YES];
    [op setCanChooseFiles:NO];
    result=[op runModal];
    if (result!=NSOKButton)
        return;
    filename=[[[op URLs] objectAtIndex:0] path];
    strcpy(gd.coin_dir,[[[[op URLs] objectAtIndex:0] path] UTF8String]);
    
    [[[NSUserDefaultsController sharedUserDefaultsController] values] setValue:filename forKey:@"dataDirectoryPath"];
}
- (IBAction)updateGlobalSettings:(id)sender
{
    if([[sender stringValue] isEqualToString:@"OK"])
        [stereo setGlobalDefaults:&gd];
    [pref performClose:self];
}
-(NSWindow*)pref
{
    return pref;
}
-(id)prefMsg
{
    return prefMsg;
}

#pragma mark -
mz_bool mz_zip_extract_archive_file_to_mem_no_alloc(const char *pZip_filename, const char *pArchive_name, void *pBuf, size_t buf_size, mz_uint flags)
{
    int file_index;
    mz_zip_archive zip_archive;
    mz_bool result;
    
    if ((!pZip_filename) || (!pArchive_name))
        return NULL;
    
    MZ_CLEAR_OBJ(zip_archive);
    if (!mz_zip_reader_init_file(&zip_archive, pZip_filename, flags | MZ_ZIP_FLAG_DO_NOT_SORT_CENTRAL_DIRECTORY))
        return NULL;
    
    if ((file_index = mz_zip_reader_locate_file(&zip_archive, pArchive_name, NULL, flags)) >= 0)
        result = mz_zip_reader_extract_to_mem_no_alloc(&zip_archive, file_index, pBuf, buf_size, flags, nil, 0);
    
    mz_zip_reader_end(&zip_archive);
    return result;
}
-(void)loadDataAtSag:(int)s cor:(int)c axi:(int)a
{
	int		i;
    char    *str;
    NSString    *str1;
    NSMutableAttributedString    *str2;
    char        zipfile[1024],file[64];
    mz_uint     zipflags=0;
    mz_bool     result;
    size_t  sz;
	
    if(oxs==s && oxc==c && oxa==a)
        return;

    [[settings content] setValue:[NSNumber numberWithInt:s] forKey:@"xsag"];
	[[settings content] setValue:[NSNumber numberWithInt:c] forKey:@"xcor"];
	[[settings content] setValue:[NSNumber numberWithInt:a] forKey:@"xaxi"];
	
    sprintf(zipfile,"%s/coincidences.zip",gd.coin_dir);
    sprintf(file,"%03i%03i%03i.img",s,c,a);
    result=mz_zip_extract_archive_file_to_mem_no_alloc(zipfile,file,(void *)vol,gd.LR*gd.IS*gd.PA*sizeof(short),zipflags);
    if(result==0)
		for(i=0;i<gd.LR*gd.PA*gd.IS;i++) vol[i]=0;
	[stereo setVolume:vol];
    
    sprintf(zipfile,"%s/top100.zip",gd.coin_dir);
    sprintf(file,"%03i%03i%03i.top100.0.txt",s,c,a);
    str=(char*)mz_zip_extract_archive_file_to_heap(zipfile, file, &sz, zipflags);
    if(sz==0)
        return;
    str[sz]=(char)0;
    str1=[NSString stringWithUTF8String:str];
    str2=[[NSMutableAttributedString alloc] initWithString:str1];
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:@"\t(.*)" options:NSRegularExpressionCaseInsensitive error:nil];
    [regex enumerateMatchesInString:str1 options:0 range:NSMakeRange(0, [str1 length]) usingBlock:^(NSTextCheckingResult *match, NSMatchingFlags flags, BOOL *stop){
        NSRange range = [match range];
        range.location+=1;
        range.length-=1;
        NSString    *link=[NSString stringWithFormat:@"http://brainspell.org/search?query=MeshHeadings:'%@'",[str1 substringWithRange:range]];
        [str2 addAttribute:NSLinkAttributeName value:link range:range];
        [str2 addAttribute:NSForegroundColorAttributeName value:[NSColor blueColor] range:range];
    }];
    [tagTextField setAllowsEditingTextAttributes:YES];
    [tagTextField setSelectable:YES];
    [tagTextField setAttributedStringValue:str2];
}
@end
