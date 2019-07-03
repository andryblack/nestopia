#import "nst_view.h"
#import "nst_application.h"

#include "nstcommon.h"
#include "video.h"
#include "input.h"
#include "config.h"

void nst_video_refresh();
extern Input::Controllers *cNstPads;

@implementation NSTView

- (id) initWithFrame:(NSRect)frameRect pixelFormat:(NSOpenGLPixelFormat *)format
{
    self = [super initWithFrame:frameRect pixelFormat:format];
    if (self) {
        m_timer = nil;
        m_null_cursor = nil;
        m_cursor_visible = YES;
        m_need_video_refresh = NO;
        m_need_retina = [[NSScreen mainScreen] respondsToSelector:@selector(backingScaleFactor)];
        if (m_need_retina) {
            [self  setWantsBestResolutionOpenGLSurface:YES];
        } else {
            [self  setWantsBestResolutionOpenGLSurface:NO];
        }
        NSLog( @"NSTView::initWithFrame ok" );
    } else {
        NSLog(@"NSTView::initWithFrame failed");
    }
    return self;
}

-(void)setApplication:(NSTAppDelegate*) app {
    m_application = app;
}

-(void)refreshVideo {
    m_need_video_refresh = YES;
}
-(void)setCursorVisible:(BOOL) visible
{
    m_cursor_visible = visible;
    [self.window invalidateCursorRectsForView:self];
}

-(void)resetCursorRects
{
    [super resetCursorRects];
    if ( !m_null_cursor && !m_cursor_visible ) {
        NSImage* img = [[NSImage alloc] initWithSize:NSMakeSize(8, 8)];
        m_null_cursor = [[NSCursor alloc] initWithImage:img hotSpot:NSMakePoint(0, 0)];
        [img release];
    }
    if (m_cursor_visible) {
        NSCursor* cursor = [NSCursor arrowCursor];
        [self addCursorRect:self.visibleRect cursor:cursor];
    } else {
        [self addCursorRect:self.visibleRect cursor:m_null_cursor];
    }
}

- (void)processKeyboardEvent:(NSEvent*)event {
    nesinput_t input;
    
    input.nescode = 0x00;
    input.player = 0;
    input.pressed = (event.type == NSEventTypeKeyDown) ? 1 : 0;
    input.turboa = 0;
    input.turbob = 0;
    
    switch (event.keyCode) {
        case 0x00: /* A */
            input.nescode = Input::Controllers::Pad::LEFT;
            break;
        case 0x0d: /* W */
            input.nescode = Input::Controllers::Pad::UP;
            break;
        case 0x01: /* S */
            input.nescode = Input::Controllers::Pad::DOWN;
            break;
        case 0x02: /* D */
            input.nescode = Input::Controllers::Pad::RIGHT;
            break;
        case 0x31: /* SPACE */
            input.nescode = Input::Controllers::Pad::START;
            break;
        case 0x28: /* K */
            input.nescode = Input::Controllers::Pad::A;
            break;
        case 0x25: /* L */
            input.nescode = Input::Controllers::Pad::B;
            break;
        case 0x22: /* I */
            input.nescode = Input::Controllers::Pad::A;
            input.turboa = 1;
            break;
        case 0x1f: /* O */
            input.nescode = Input::Controllers::Pad::B;
            input.turbob = 1;
            break;
            
        case 0x30: /* TAB */
            input.nescode = Input::Controllers::Pad::SELECT;
            break;
            
        default:
            return;
    }
    switch(event.type) {
        case NSEventTypeKeyDown:
            input.pressed = 1;
            break;
        case NSEventTypeFlagsChanged:
            //input.pressed = 1;
            break;
    }
    nst_input_inject(cNstPads, input);
}

- (void)keyDown:(NSEvent *)event {
    [self processKeyboardEvent:event];
}
- (void)keyUp:(NSEvent *)event {
    [self processKeyboardEvent:event];
}

- (NSPoint) scale_point:(NSPoint)point {
    NSPoint res = point;
    res.y = self.frame.size.height - res.y;
    if (m_need_retina) {
        res.x *= self.window.backingScaleFactor;
        res.y *= self.window.backingScaleFactor;
    }
    return res;
}
- (void)mouseDown:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)mouseUp:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)mouseMoved:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)mouseDragged:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)rightMouseDown:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)rightMouseUp:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)rightMouseDragged:(NSEvent *)theEvent {
    NSPoint event_location = [theEvent locationInWindow];
    NSPoint local_point = [self convertPoint:event_location fromView:nil];
    local_point = [self scale_point: local_point ];
}
- (void)scrollWheel:(NSEvent *)event {
}

- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (BOOL)canBecomeKeyView {
    return YES;
}

- (void)setTimerInterval {
    int framerate = nst_pal() ? (conf.timing_speed / 6) * 5 : conf.timing_speed;
    NSTimeInterval interval = 1/framerate;
    if (m_timer) {
        [m_timer invalidate];
    }
    m_timer = [NSTimer scheduledTimerWithTimeInterval: interval target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
}
- (void)prepareOpenGL {
    NSLog( @"NSTView::prepareOpenGL" );
    
    NSAutoreleasePool* pool = [[NSAutoreleasePool alloc] init];
    
    NSSize size = self.bounds.size;
    if (m_need_retina) {
        size.width *= self.window.backingScaleFactor;
        size.height *= self.window.backingScaleFactor;
    }
   
    [[self openGLContext] makeCurrentContext];
    
    NSLog(@"RENDERER: %s",(char*)glGetString(GL_RENDERER));
    NSLog(@"VERSION: %s",(char*)glGetString(GL_VERSION));
    NSLog(@"GLSL: %s",(char*)glGetString(GL_SHADING_LANGUAGE_VERSION));
    
    dimensions_t dim = { size.width, size.height };
    nst_video_set_dimensions_screen(dim);
    
    video_init();
    
    [self setTimerInterval];
    [pool drain];
    [super prepareOpenGL];
}

- (void)updateRenderSize {
    
    NSSize size = self.bounds.size;
    if (m_need_retina) {
        size.width *= self.window.backingScaleFactor;
        size.height *= self.window.backingScaleFactor;
    }
    //NSLog(@"updateRenderSize : %fx%f",size.width,size.height);
    dimensions_t dim = { size.width, size.height };
    nst_video_set_dimensions_screen(dim);
    video_set_dimensions();
    
}
- (void)reshape {
    [self updateRenderSize];
    [super reshape];
}
- (void)update {
    [super update];
}

- (void)drawRect:(NSRect)dirtyRect {
    (void)dirtyRect;
    if ([self isHidden])
        return;
    static bool in_draw = false;
    if (in_draw) return;
    if ([m_application waitSwitchFullscreen]) {
        return;
    }
    if ( true  ) {
        in_draw = true;
        
        [[self openGLContext] makeCurrentContext];
        if (m_need_video_refresh) {
            video_init();
            m_need_video_refresh = NO;
        }
        dimensions_t screensize = nst_video_get_dimensions_screen();
        dimensions_t rendersize = nst_video_get_dimensions_render();
        conf.video_fullscreen ?
            glViewport(screensize.w / 2.0f - rendersize.w / 2.0f, 0, rendersize.w, rendersize.h) :
            glViewport(0, 0, screensize.w, screensize.h);
        nst_ogl_render();
        
        [[self openGLContext] flushBuffer];
        in_draw = false;
    }
    [super drawRect:dirtyRect];
}

- (void)renewGState
{
    /* Overload this function to ensure the NSOpenGLView doesn't
     flicker when you resize it.                               */
    NSWindow *window;
    [super renewGState];
    window = [self window];
    
    /* Only available in 10.4 and later, so check that it exists */
    if(window && [window respondsToSelector:@selector(disableScreenUpdatesUntilFlush)])
        [window disableScreenUpdatesUntilFlush];
}

- (void)timerFireMethod:(NSTimer*)theTimer {
    (void)theTimer;
    
    if ( [m_application waitSwitchFullscreen] ) {
        [m_application switchFullscreen];
        [self reshape];
    }
    
    nst_emuloop();
    
    if ([self window] && [self.window isVisible] && self.canDraw) {
        [self drawRect:self.bounds];
    }
}


-(void)dealloc {
    NSLog( @"NSTView::dealloc" );
    if (m_timer) {
        [m_timer release];
    }
   
    [m_null_cursor release];
    [super dealloc];
}

@end

