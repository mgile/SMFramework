//
//  SMFolderBrowser.m
//  SoftwareMenuFramework
//
//  Created by Thomas on 4/19/09.
//  Copyright 2010 Thomas Cool. All rights reserved.
//



#import "SMFFolderBrowser.h"
#import "SMFBaseAsset.h"
#import "SMFMediaPreview.h"
#import "SMFMenuItem.h"
#import "SMFThemeInfo.h"

@implementation SMFFolderBrowser
@synthesize separate;
@synthesize showHidden;
@synthesize showOnlyFolders;
@synthesize delegate;
@synthesize plistKey;
@synthesize plistPath;
@synthesize fpath;

//- (id) previewControlForItem: (long) item
//{
//	////NSLog(@"%@ %s", self, _cmd);
//	SMFBaseAsset	*meta = [[SMFBaseAsset alloc] init];
//	[meta setTitle:[_paths objectAtIndex:item]];
//	[meta setCoverArt:[[BRThemeInfo sharedTheme] appleTVImage]];
//    [meta setSummary:[_paths objectAtIndex:item]];
//	BRMetadataPreviewControl *obj = [[BRMetadataPreviewControl alloc] init];
//	[obj setShowsMetadataImmediately:NO];
//	[obj setAsset:meta];
//    [meta release];
//	return [obj autorelease];
//}
+ (void)setString:(NSString *)inputString forKey:(NSString *)theKey inDomain:(NSString *)theDomain
{
	CFPreferencesSetAppValue((CFStringRef)theKey, (CFStringRef)inputString, (CFStringRef)theDomain);
	CFPreferencesAppSynchronize((CFStringRef)theDomain);
	//CFRelease(inputString);
}
+ (NSString *)stringForKey:(NSString *)theKey inDomain:(NSString *)theDomain
{
    NSLog(@"The Domain: %@",theDomain);
	CFPreferencesAppSynchronize((CFStringRef)theDomain);
	NSString * myString = (NSString *)CFPreferencesCopyAppValue((CFStringRef)theKey, (CFStringRef)theDomain);
	return [(NSString *)myString autorelease];
}
-(id)init{
	self = [super init];
	[self addLabel:@"org.tomcool.Software.SMF"];
    separate = TRUE;
    showHidden = FALSE;
	_items = [[NSMutableArray alloc] initWithObjects:nil];
	_paths = [[NSMutableArray alloc] initWithObjects:nil];
	_man = [[NSFileManager defaultManager] retain];
    _files = [[NSMutableArray alloc]init];
    _folders = [[NSMutableArray alloc]init];
    [[self list] setDatasource:self];
	return self;
}
- (id)initWithPath:(NSString *)thePath
{
	self = [super init];
	[self addLabel:@"org.tomcool.Software.SMF"];
    separate = TRUE;
    showHidden = FALSE;
	_items = [[NSMutableArray alloc] initWithObjects:nil];
	_paths = [[NSMutableArray alloc] initWithObjects:nil];
	_man = [[NSFileManager defaultManager] retain];
    _files = [[NSMutableArray alloc]init];
    _folders = [[NSMutableArray alloc]init];
    [[self list] setDatasource:self];
    [self setPath:thePath];
    return self;
}
- (void)setPath:(NSString *)thePath
{
	[path release];
	path = thePath;
	[path retain];
	[self setListTitle: [path lastPathComponent]];
    [self reloadFiles];
}

-(void)reloadFiles
{
    [_paths removeAllObjects];
    [_items removeAllObjects];
    [_folders removeAllObjects];
    if (plistKey!=nil && plistPath!=nil ) {
        [self setFpath:[SMFFolderBrowser stringForKey:plistKey inDomain:plistPath]];
    }
    
    [[self list] removeDividers];
    NSFileManager *man = [NSFileManager defaultManager];
    BOOL isDir;
    NSArray *files= [man contentsOfDirectoryAtPath:path error:nil];
    for (NSString *file in files) 
    {
        //NSLog(@"file: %@",file);
        if (![file hasPrefix:@":"]) {
            if (![file hasPrefix:@"."] || showHidden) {
                NSString *tf = [path stringByAppendingPathComponent:file];
                if ([man fileExistsAtPath:tf isDirectory:&isDir])
                {
                    if (!(!isDir && showOnlyFolders)) 
                    {
                        if (separate) 
                        {
                            if (isDir)
                                [_folders addObject:tf];
                            else
                                [_files addObject:tf];
                        }
                        else
                            [_files addObject:tf];
                    }
                }
            }
        }
    }
    [[self list] addDividerAtIndex:[_folders count] withLabel:@"Files"];
    NSLog(@"files count: %i",[_files count]);
    NSLog(@"folders count: %i",[_folders count]);
    //[[self list] reload];
}
-(void)leftActionForRow:(long)row
{
    [self rightActionForRow:row];
}
-(void)rightActionForRow:(long)row
{
    NSString *p=nil;
    BOOL dir=NO;
    if (separate && row<[_folders count]) 
    {
        p=[_folders objectAtIndex:row];
    }
    else if(!separate && 
            [[NSFileManager defaultManager] fileExistsAtPath:[_folders objectAtIndex:row] isDirectory:&dir]
            && dir)
    {
        p=[_files objectAtIndex:row];
    }
    NSLog(@"p: %@",p);
    NSLog(@"plistKey: %@",plistKey);
    NSLog(@"plistPath: %@",plistPath);
    if (p) 
    {
        
        if (plistKey!=nil && plistPath!=nil) {
            [SMFFolderBrowser setString:p forKey:plistKey inDomain:plistPath];
            NSLog(@"plistKey and Path is good");
        }
        NSLog(@"p is good");
    }
    [self reloadFiles];
    [[self list] reload];
    
}
-(void)itemSelected:(long)row
{
    NSFileManager *man = [NSFileManager defaultManager];
    if (separate) 
    {
        if (row<[_folders count]) 
        {
            NSString *newPath = [path stringByAppendingPathComponent:[_folders objectAtIndex:row]];
            SMFFolderBrowser *p = [[SMFFolderBrowser alloc]initWithPath:newPath];
            [[self stack]pushController:p];
            [p release];
        }
    }
    else
    {
        NSString *newPath = [_files objectAtIndex:row];//[path stringByAppendingPathComponent:[_files objectAtIndex:row]];
        BOOL isDir;
        if([man fileExistsAtPath:newPath isDirectory:&isDir] && isDir)
        {
            SMFFolderBrowser *p = [[SMFFolderBrowser alloc]initWithPath:[_files objectAtIndex:row]];
            [[self stack]pushController:p];
            [p release];
        }
    }
}

- (id)itemForRow:(long)row					
{ 
	if (separate) 
    {
        if (row<[_folders count]) 
        {
            SMFMenuItem *it = [SMFMenuItem folderMenuItem];
            [it setText:[[_folders objectAtIndex:row] lastPathComponent] 
         withAttributes:[[BRThemeInfo sharedTheme]menuItemTextAttributes]];
            if (fpath!=nil&& 
                [[_folders objectAtIndex:row] localizedCaseInsensitiveCompare:fpath]==NSOrderedSame) {
                //NSLog(@"it :%@ %@",[_folders objectAtIndex:row],fpath);
                [it setImage:[[SMFThemeInfo sharedTheme] selectedImage]];
            }
            return it;
        }
        else if(row<([_folders count]+[_files count]))
        {
            SMFMenuItem *it = [SMFMenuItem menuItem];
            [it setText:[[_files objectAtIndex:(row-[_folders count])] lastPathComponent] 
         withAttributes:[[BRThemeInfo sharedTheme]menuItemTextAttributes]];

            return it;
        }
    }
    else 
    {
        BRMenuItem *it = [[BRMenuItem alloc] init];
        //NSLog(@"it: %@, %@",it,[[_files objectAtIndex:row] lastPathComponent]);
        [it setText:[[_files objectAtIndex:row] lastPathComponent] 
     withAttributes:[[BRThemeInfo sharedTheme]menuItemTextAttributes]];
        if (fpath && [[_files objectAtIndex:row] localizedCaseInsensitiveCompare:fpath]==NSOrderedSame) {
            
            [it setImage:[[SMFThemeInfo sharedTheme] selectedImage]];
        }
        return [it autorelease];
    }
    return nil;

}
-(id)titleForRow:(long)row
{
    if (separate) 
    {
        if (row<[_folders count]) 
        {
            return [[_folders objectAtIndex:row] lastPathComponent];
        }
        else if(row<([_folders count]+[_files count]))
        {
            return [[_files objectAtIndex:(row-[_folders count])] lastPathComponent];
        }
    }
    else 
    {
        //NSLog(@"title: %@",[[_files objectAtIndex:row] lastPathComponent]);
        return [[_files objectAtIndex:row] lastPathComponent];
    }
    return nil;
}
-(long)itemCount
{
    return ([_folders count]+[_files count]);
}
-(void)dealloc
{
    [_man release];
    [_folders release];
    [_files release];
    [super dealloc];
    
}

@end
