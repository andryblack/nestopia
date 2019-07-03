#ifndef _APPLICATION_H_INCLUDED_
#define _APPLICATION_H_INCLUDED_

#import <Cocoa/Cocoa.h>
#import "nst_window.h"
#import "nst_view.h"


@interface NSTAppDelegate : NSObject <NSApplicationDelegate,NSWindowDelegate> {
    NSTWindow*    m_window;
    NSString*    m_appName;
    NSTView*   m_gl_view;
    NSRect      m_rect;
    int             m_sheets_level;
    bool        m_fullscreen;
}
-(void) initSound;
-(void) switchFullscreen;
-(void) createWindow;
-(void) setCursorVisible:(BOOL) visible;
-(NSString*) getAppName;
-(BOOL) waitSwitchFullscreen;
-(void) openFile;
-(void) buildMenu;
@end

#endif /*_APPLICATION_H_INCLUDED_*/
