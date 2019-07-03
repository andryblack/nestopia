#ifndef _NST_VIEW_H_INCLUDED_
#define _NST_VIEW_H_INCLUDED_

#import <Cocoa/Cocoa.h>

@class NSTAppDelegate;

@interface NSTView : NSOpenGLView
{
    NSTAppDelegate* m_application;
    NSTimer*    m_timer;
    NSCursor*   m_null_cursor;
    BOOL        m_cursor_visible;
    BOOL        m_need_retina;
    int         m_frame_interval;
    BOOL        m_need_video_refresh;
}
-(id) initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format;
-(void)setApplication:(NSTAppDelegate*) app;
-(void)setCursorVisible:(BOOL) visible;
-(void)updateRenderSize;
-(void)setTimerInterval;
-(void)refreshVideo;
@end


#endif /*_OPENGL_VIEW_H_INCLUDED_*/

