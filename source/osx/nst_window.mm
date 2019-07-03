
#import "nst_window.h"


@implementation NSTWindow

- (BOOL)canBecomeKeyWindow
{
    return YES;
}

- (BOOL) acceptsFirstResponder
{
    // We want this view to be able to receive key events
    return YES;
}

- (BOOL)isMainWindow
{
    return YES;
}
- (void)closeWindow {
    NSLog( @"NSTWindow::closeWindow" );
    [super close];
}
- (void)close {
    NSLog( @"NSTWindow::close" );
    [super close];
    [[NSApplication sharedApplication] terminate:self];
}


@end

