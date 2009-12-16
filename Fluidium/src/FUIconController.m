//  Copyright 2009 Todd Ditchendorf
//
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.

#import "FUIconController.h"
#import "FUApplication.h"
#import "IconFamily.h"

@interface FUIconController ()
- (void)generateIcnsFile;
- (void)applicationVerisonDidChange:(NSNotification *)n;
@end

@implementation FUIconController

+ (void)load {
    if ([FUIconController class] == self) {
        [self instance];
    }
}


+ (id)instance {
    static FUIconController *instance = nil;
    @synchronized (self) {
        if (!instance) {
            instance = [[FUIconController alloc] init];
        }
    }
    return instance;
}


- (id)init {
    if (self = [super init]) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationVerisonDidChange:) name:FUApplicationVersionDidChangeNotification object:NSApp];
    }
    return self;
}


- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    self.dockTileImageView = nil;
    [super dealloc];
}


#pragma mark -
#pragma mark Public

- (void)setCustomAppIconToFileAtPath:(NSString *)path {
    path = [path stringByExpandingTildeInPath];
    NSArray *exts = [NSArray arrayWithObjects:@"png", @"tiff", @"jpeg", @"jpg", nil];
    
    NSImage *image = nil;
    IconFamily *ifam = nil;
    NSString *ext = [path pathExtension];
    
    if ([exts containsObject:ext]) {
        image = [[[NSImage alloc] initWithContentsOfFile:path] autorelease];
        ifam = [IconFamily iconFamilyWithThumbnailsOfImage:image usingImageInterpolation:NSImageInterpolationHigh];
        
        // icon creator        
        //        [ifam writeToFile:@"/users/itod/Desktop/foo.icns"];
    } else if ([ext isEqualToString:@"icns"]) {
        ifam = [IconFamily iconFamilyWithContentsOfFile:path];
        image = [ifam imageWithAllReps];
        
        // icon creator        
        //        NSData *data = [image TIFFRepresentation];
        //        NSURL *furl = [NSURL fileURLWithPath:@"/users/itod/Desktop/foo.tiff"];
        //        [data writeToURL:furl atomically:YES];
        
    } else {
        image = [[NSWorkspace sharedWorkspace] iconForFile:path];
        ifam = [IconFamily iconFamilyWithIconOfFile:path];
        //        ifam = [IconFamily iconFamilyWithThumbnailsOfImage:image usingImageInterpolation:NSImageInterpolationHigh];
    }
    
    if (image) {
        NSString *bundlePath = [[NSBundle mainBundle] bundlePath];
        
        // IFamily works better than workspace :-/
        //[[NSWorkspace sharedWorkspace] setIcon:image forFile:bundlePath options:0];
        [ifam setAsCustomIconForDirectory:bundlePath withCompatibility:YES];
        [[NSWorkspace sharedWorkspace] noteFileSystemChanged:bundlePath];
        //[NSApp setApplicationIconImage:image];
        //[[NSWorkspace sharedWorkspace] noteFileSystemChanged:bundlePath];
        
        // clear out dock tile image
        self.dockTileImageView = nil;
        self.dockTileImageView = self.dockTileImageView;
        
        // create an actual appl.icns file so dialogs won't have generic app icon
        [self performSelectorInBackground:@selector(generateIcnsFile) withObject:nil];
    }    
}


// the only reason this is here is cuz dialogs seem to use the generic app icon
// unless there is an .icns file. the file created here is not migrated by Sparkle.
// it is lost on upgrading.
- (void)generateIcnsFile {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
    
    NSString *resPath  = [[[NSBundle mainBundle] resourcePath] stringByExpandingTildeInPath];
    NSString *icnsPath = [[resPath stringByAppendingPathComponent:@"appl"] stringByAppendingPathExtension:@"icns"];
    
//    BOOL icnsExists = [[NSFileManager defaultManager] fileExistsAtPath:icnsPath];
//    if (!icnsExists) {
        NSString *appPath  = [[NSBundle mainBundle].bundlePath stringByExpandingTildeInPath];
        [[IconFamily iconFamilyWithIconOfFile:appPath] writeToFile:icnsPath];
        //NSImage *image = [[NSWorkspace sharedWorkspace] iconForFile:appPath];
        //[NSApp setApplicationIconImage:image];
        //[[NSWorkspace sharedWorkspace] noteFileSystemChanged:appPath];
//    }
    
    [pool release];
}


- (void)setDockTileImageView:(NSImageView *)iv {
    if (iv != dockTileImageView) {
        [dockTileImageView autorelease];
        dockTileImageView = [iv retain];

        [[NSApp dockTile] setContentView:dockTileImageView];
        [[NSApp dockTile] display];
    }
}


- (NSImageView *)dockTileImageView {
    if (!dockTileImageView) {
        NSImageView *iv = [[[NSImageView alloc] initWithFrame:NSMakeRect(0, 0, 512, 512)] autorelease];
        [iv setImage:[[IconFamily iconFamilyWithIconOfFile:[[NSBundle mainBundle] bundlePath]] imageWithAllReps]];
        [iv setImageScaling:NSImageScaleProportionallyDown];
        [iv setAutoresizingMask:NSViewHeightSizable|NSViewWidthSizable];
        self.dockTileImageView = iv;
    }
    
    return dockTileImageView;
}


#pragma mark -
#pragma mark Notifications

- (void)applicationVerisonDidChange:(NSNotification *)n {
    [self performSelectorInBackground:@selector(generateIcnsFile) withObject:nil];
}

@synthesize dockTileImageView;
@end
