#import <Cocoa/Cocoa.h>
#import <AppKit/NSWindow.h>
#import "nst_application.h"

#include "nstcommon.h"
#include "cli.h"
#include "config.h"
#include "audio.h"
#include "video.h"



int main(int argc,char** argv) {
    
    
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    
    [NSApplication sharedApplication];
    NSTAppDelegate* delegate = [[NSTAppDelegate alloc] init];
   
    [delegate buildMenu];
    [[NSApplication sharedApplication] setDelegate:delegate];
    
    [pool release];
    
    [NSApp run];
    
    return 0;
}
