#import "nst_application.h"
#include "nstcommon.h"
#include "nst_view.h"
#include "video.h"
#include "config.h"
#include "audio.h"

extern nstpaths_t nstpaths;


extern bool (*nst_archive_select)(const char*, char*, size_t);


const char* get_datadir() {
    static std::string data_dir;
    if (data_dir.empty()) {
        NSString* path =  [[NSBundle mainBundle] resourcePath];
        data_dir = [path UTF8String];
    }
    return data_dir.c_str();
}

@implementation NSTAppDelegate


- (id)init {
    self = [super init];
    if (self) {
        // Initialization code here.
        m_gl_view = nil;
        m_fullscreen = false;
        m_sheets_level = 0;
        m_appName = (NSString*)[[[NSBundle mainBundle] infoDictionary] objectForKey:@"CFBundleName"];
    }
    return self;
}

-(void) initSound {
}

-(NSString*) getAppName {
    return m_appName;
}

-(void) setCursorVisible:(BOOL) visible
{
    [m_gl_view setCursorVisible:visible];
}

-(void)dealloc {
    NSLog( @"NSTAppDelegate::dealloc" );
    [super dealloc];
}

- (void)createWindow {
    NSLog( @"NSTAppDelegate::createWindow" );
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];

    NSInteger style = NSTitledWindowMask | NSClosableWindowMask | NSResizableWindowMask | NSMiniaturizableWindowMask;
    
    NSScreen* screen = 0;
    
    NSRect rect = m_rect;
    
    screen = [NSScreen mainScreen];
    
    if (!m_window) {
        NSLog( @"NSTAppDelegate::createWindow create new window" );
        m_window = [[NSTWindow alloc] initWithContentRect:rect styleMask:style backing:NSBackingStoreBuffered defer:YES];
        [m_window disableFlushWindow];
        [m_window setContentView:m_gl_view];
        [m_window setDelegate:self];
        [m_gl_view setAutoresizesSubviews:YES];
    }
    
    
    [m_window setAcceptsMouseMovedEvents:YES];
    [m_window setTitle:[self getAppName] ];
    
    [m_gl_view reshape];
    
    [m_gl_view setHidden:NO];
    [m_window enableFlushWindow];
    [m_window makeKeyAndOrderFront:nil];
    [m_window makeKeyWindow];
    [m_window makeFirstResponder:m_gl_view];
    
    [pool release];
}

- (void)switchFullscreen {
    [m_window toggleFullScreen:self];
    m_fullscreen = !m_fullscreen;
}


- (void)applicationDidFinishLaunching:(NSNotification *)aNotification {
    NSLog( @"NSTAppDelegate::applicationDidFinishLaunching" );
    (void)aNotification;
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSScreen* screen = [NSScreen mainScreen];
    
    
    // Set up directories
    nst_set_dirs();
    // Set default config options
    config_set_default();
    // Read the config file and override defaults
    config_file_read(nstpaths.nstdir);
    // Handle command line arguments
    //cli_handle_command(argc, argv);
    // Set up callbacks
    nst_set_callbacks();
    
    // Set archive handler function pointer
    nst_archive_select = &nst_archive_select_file;
    
    
    dimensions_t sceensize;
    sceensize.w = screen.frame.size.width;
    sceensize.h = screen.frame.size.height;
    nst_video_set_dimensions_screen(sceensize);
    
    // Set the video dimensions
    video_set_dimensions();
    
    // Initialize and load FDS BIOS and NstDatabase.xml
    nst_fds_bios_load();
    nst_db_load();
    
    bool need_retina = [screen respondsToSelector:@selector(backingScaleFactor)];
    
    NSOpenGLPixelFormatAttribute attrs[] =
    {
        NSOpenGLPFADoubleBuffer,
        NSOpenGLPFAColorSize, 24,
        NSOpenGLPFAAlphaSize, 8,
        NSOpenGLPFAStencilSize, 8,
        NSOpenGLPFADepthSize, 24,
        NSOpenGLPFAOpenGLProfile,NSOpenGLProfileVersion3_2Core,
        0
    };
   
    
    dimensions_t rendersize = nst_video_get_dimensions_render();
    if (rendersize.w < 480) {
        rendersize.w = 480;
    }
    if (rendersize.h < 320) {
        rendersize.h = 320;
    }
    
    NSRect rect = NSMakeRect(0,
                             0,
                             rendersize.w,rendersize.h);
    if (need_retina) {
        rect.size.width /= screen.backingScaleFactor;
        rect.size.height /= screen.backingScaleFactor;
    }
    rect.origin.x = (screen.frame.size.width-rect.size.width)/2;
    rect.origin.y = (screen.frame.size.height-rect.size.height)/2;
    
    m_rect = rect;
    
    NSOpenGLPixelFormat* pf = [[NSOpenGLPixelFormat alloc] initWithAttributes:attrs];
    if (!pf) {
        NSLog(@"Create pixel format failed");
        return;
    }
    NSTView* gl = [[NSTView alloc] initWithFrame:rect pixelFormat:pf];
    [pf release];
    pf = nil;
    if (!gl) {
        NSLog(@"creating WinLibOpenGLView failed");
        return;
    }
    [gl retain];
    [gl setApplication:self];
    
    
    m_gl_view = gl;
    
    
    [self createWindow];
    [m_window setCollectionBehavior: NSWindowCollectionBehaviorFullScreenPrimary];
    [m_window makeKeyAndOrderFront:nil];
    
    [pool release];
}
- (void)applicationWillTerminate:(NSNotification *)aNotification {
    NSLog( @"NSTAppDelegate::applicationWillTerminate" );
    (void)aNotification;
  
    if (m_window)
        [m_window release];
    
    // Remove the cartridge and shut down the NES
    nst_unload();
    
    // Unload the FDS BIOS, NstDatabase.xml, and the custom palette
    nst_db_unload();
    nst_fds_bios_unload();
    nst_palette_unload();
    
    // Deinitialize audio
    audio_deinit();
    
    // Write the config file
    config_file_write(nstpaths.nstdir);
}
- (void)applicationDidBecomeActive:(NSNotification *)notification {
    
}

- (void)applicationDidResignActive:(NSNotification *)notification {
    if (m_fullscreen) {
        //[m_window setIsVisible:NO];
        [m_window setLevel:NSNormalWindowLevel];
    }
}

/// ---- NSWindowDelegate

- (void)windowWillBeginSheet:(NSNotification *)notification {
    ++m_sheets_level;
}
- (void)windowDidEndSheet:(NSNotification *)notification {
    --m_sheets_level;
}


- (void)windowDidEnterFullScreen:(NSNotification *)notification {
    if (m_gl_view) {
        [m_window setContentSize:m_window.screen.frame.size];
    }
    m_fullscreen = conf.video_fullscreen = true;
    [m_gl_view updateRenderSize];
}

- (void)windowWillExitFullScreen:(NSNotification *)notification {
    if (m_gl_view) {
        [m_window setContentSize:m_rect.size];
    }
}
- (void)windowDidExitFullScreen:(NSNotification *)notification {
    m_fullscreen = conf.video_fullscreen = false;
    [m_gl_view updateRenderSize];
    [m_window setViewsNeedDisplay:YES];
}

- (void)setResizeableWindow:(BOOL) resizeable {
    if (m_window) {
#if (__MAC_OS_X_VERSION_MAX_ALLOWED >= 101200)
        NSWindowStyleMask style = [m_window styleMask];
        if (resizeable) {
            style |= NSWindowStyleMaskResizable;
        } else {
            style &= ~NSWindowStyleMaskResizable;
        }
        [m_window setStyleMask:style];
#else
        NSInteger style = [m_window styleMask];
        if (resizeable) {
            style |= NSResizableWindowMask;
        } else {
            style &= ~NSResizableWindowMask;
        }
        [m_window setStyleMask:style];
#endif
    }
}

- (void)windowDidMiniaturize:(NSNotification *)notification {
    
}

- (void)windowDidDeminiaturize:(NSNotification *)notification {
    
}


- (BOOL) waitSwitchFullscreen {
    return conf.video_fullscreen != m_fullscreen;
}

-(void)doOpenFile:(const char*) filename {
    if (nst_load(filename)) {
        [m_window setTitle:[NSString stringWithUTF8String:nstpaths.gamename]];
        [m_gl_view updateRenderSize];
        [m_gl_view setTimerInterval];
        nst_play();
    }
}

/// emnu actions
-(void)openFile {
    NSOpenPanel* openDlg = [NSOpenPanel openPanel];
    [openDlg setCanChooseFiles:YES];
    [openDlg setCanChooseDirectories:NO];
    if ( [openDlg runModal] == NSModalResponseOK )
    {
        // Get an array containing the full filenames of all
        // files and directories selected.
        NSURL* file = openDlg.URL;
        if (file) {
            [self doOpenFile:file.fileSystemRepresentation];
        }
    };
}

- (void) saveState:(NSMenuItem*) item {
    nst_state_quicksave(0);
}

- (void) loadState:(NSMenuItem*) item {
    nst_state_quickload(0);
}

- (void) takeScreenshot {
    video_screenshot(NULL);
}

- (void) resetSystem {
    nst_reset(0);
}

- (void) setFilter:(NSMenuItem*) item {
    conf.video_filter = item.tag;
    [m_gl_view updateRenderSize];
    [m_gl_view refreshVideo];
}

- (void) buildMenu {
    NSLog( @"create menu" );
    NSMenu * mainMenu = [[[NSMenu alloc] initWithTitle:@"MainMenu"] autorelease];
    
    // The titles of the menu items are for identification purposes only
    //and shouldn't be localized.
    // The strings in the menu bar come from the submenu titles,
    // except for the application menu, whose title is ignored at runtime.
    NSMenuItem *item = [mainMenu addItemWithTitle:@"Apple" action:NULL keyEquivalent:@""];
    NSMenu *submenu = [[[NSMenu alloc] initWithTitle:@"Apple"] autorelease];
    //[NSApp performSelector:@selector(setAppleMenu:) withObject:submenu];
    
    NSMenuItem * appItem = [submenu addItemWithTitle:[NSString stringWithFormat:@"%@ %@",
                                                      NSLocalizedString(@"Quit", nil), [self getAppName]]
                                              action:@selector(terminate:)
                                       keyEquivalent:@"q"];
    [appItem setTarget:NSApp];
    
    
    [mainMenu setSubmenu:submenu forItem:item];
    
    item = [mainMenu addItemWithTitle:@"File" action:NULL keyEquivalent:@""];
    submenu = [[[NSMenu alloc] initWithTitle:@"File"] autorelease];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Open", nil)
                                 action:@selector(openFile)
                          keyEquivalent:@"o"];
    [appItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    [appItem setTarget:self];
    
    [mainMenu setSubmenu:submenu forItem:item];
    
    item = [mainMenu addItemWithTitle:@"Edit" action:NULL keyEquivalent:@""];
    submenu = [[[NSMenu alloc] initWithTitle:@"Edit"] autorelease];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Copy", nil)
                                 action:@selector(copy:)
                          keyEquivalent:@"c"];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Paste", nil)
                                 action:@selector(paste:)
                          keyEquivalent:@"v"];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Select all", nil)
                                 action:@selector(selectAll:)
                          keyEquivalent:@"a"];
    
    [mainMenu setSubmenu:submenu forItem:item];
    
    // state menu
    item = [mainMenu addItemWithTitle:@"State" action:NULL keyEquivalent:@""];
    submenu = [[[NSMenu alloc] initWithTitle:@"State"] autorelease];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Save", nil)
                                 action:@selector(saveState:)
                          keyEquivalent:@"s"];
    [appItem setTarget:self];
    [appItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    
    appItem = [submenu addItemWithTitle: NSLocalizedString(@"Load", nil)
                                 action:@selector(loadState:)
                          keyEquivalent:@"l"];
    [appItem setTarget:self];
    [appItem setKeyEquivalentModifierMask:NSEventModifierFlagCommand];
    
    
    [mainMenu setSubmenu:submenu forItem:item];
    
    
    // video
    {
        item = [mainMenu addItemWithTitle:@"Video" action:NULL keyEquivalent:@""];
        submenu = [[[NSMenu alloc] initWithTitle:@"Video"] autorelease];
        
        appItem = [submenu addItemWithTitle: @"Take screenshot"
                                     action:@selector(takeScreenshot)
                              keyEquivalent:@""];
        [appItem setTarget:self];
        [mainMenu setSubmenu:submenu forItem:item];
        
        // filter
        {
            item = [submenu addItemWithTitle:@"Filter" action:NULL keyEquivalent:@""];
            NSMenu* submenu2 = [[[NSMenu alloc] initWithTitle:@"Filter"] autorelease];
            
            appItem = [submenu2 addItemWithTitle: @"None"
                                         action:@selector(setFilter:)
                                  keyEquivalent:@""];
            appItem.tag = 0;
            [appItem setTarget:self];
            
            appItem = [submenu2 addItemWithTitle: @"NTSC"
                                          action:@selector(setFilter:)
                                   keyEquivalent:@""];
            appItem.tag = 1;
            [appItem setTarget:self];
            
            appItem = [submenu2 addItemWithTitle: @"xBR"
                                          action:@selector(setFilter:)
                                   keyEquivalent:@""];
            appItem.tag = 2;
            [appItem setTarget:self];
            
            appItem = [submenu2 addItemWithTitle: @"HQx"
                                          action:@selector(setFilter:)
                                   keyEquivalent:@""];
            appItem.tag = 3;
            [appItem setTarget:self];
            
            appItem = [submenu2 addItemWithTitle: @"2xSaI"
                                          action:@selector(setFilter:)
                                   keyEquivalent:@""];
            appItem.tag = 4;
            [appItem setTarget:self];
            
            [submenu setSubmenu:submenu2 forItem:item];
        }
    }
    
    // system
    item = [mainMenu addItemWithTitle:@"System" action:NULL keyEquivalent:@""];
    submenu = [[[NSMenu alloc] initWithTitle:@"System"] autorelease];
    
    appItem = [submenu addItemWithTitle: @"Reset"
                                 action:@selector(resetSystem)
                          keyEquivalent:@""];
    [appItem setTarget:self];
    [mainMenu setSubmenu:submenu forItem:item];
    
    [NSApp setMainMenu:mainMenu];
}
@end
