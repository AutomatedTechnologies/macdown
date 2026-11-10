//
//  MPWelcomeController.m
//  MacDown
//
//  Code-constructed SDS-8 welcome screen, following the estate's
//  conforming patterns: `DistroWelcomeController` (Distro,
//  distro-test-40) for the window/label/version-line construction
//  and the AirPods Max Diagnostics welcome for the icon pulse.
//  No nib, no auto-dismiss: a single user-driven Continue action.
//

#import "MPWelcomeController.h"


static NSTextField *MPWelcomeLabel(NSString *text, CGFloat size, BOOL bold,
                                   NSColor *color)
{
    NSTextField *label = [[NSTextField alloc] initWithFrame:NSZeroRect];
    [label setStringValue:text];
    [label setFont:bold ? [NSFont boldSystemFontOfSize:size]
                        : [NSFont systemFontOfSize:size]];
    [label setTextColor:color];
    [label setBezeled:NO];
    [label setDrawsBackground:NO];
    [label setEditable:NO];
    [label setSelectable:NO];
    [label setAlignment:NSTextAlignmentCenter];
    return label;
}


@interface MPWelcomeController ()
@property (nonatomic, strong) NSImageView *iconView;
@property (nonatomic, strong) NSSound *startupSound;
@property (nonatomic, strong) NSTimer *pulseTimer;
@property (nonatomic) BOOL soundPlayed;
@property (nonatomic) BOOL pulseUp;
@end


@implementation MPWelcomeController

- (instancetype)init
{
    NSRect frame = NSMakeRect(0, 0, 480, 440);
    NSWindow *window = [[NSWindow alloc] initWithContentRect:frame
        styleMask:(NSWindowStyleMaskTitled | NSWindowStyleMaskClosable)
          backing:NSBackingStoreBuffered
            defer:NO];
    [window setTitle:@"Welcome to MacDown"];
    [window setReleasedWhenClosed:NO];
    self = [super initWithWindow:window];
    if (self)
    {
        NSView *content = [window contentView];
        CGFloat w = NSWidth(frame);

        // SDS-10 10.1.2: the welcome mark is the bundle AppIcon
        // composition itself — the application icon image, not a
        // second drawing that could drift from the Dock icon.
        NSImageView *icon = [[NSImageView alloc]
            initWithFrame:NSMakeRect((w - 112) / 2, 440 - 40 - 112, 112, 112)];
        [icon setImage:[NSApp applicationIconImage]];
        [icon setImageScaling:NSImageScaleProportionallyUpOrDown];
        [content addSubview:icon];
        self.iconView = icon;

        NSTextField *name = MPWelcomeLabel(@"MacDown", 28, YES,
                                           [NSColor blackColor]);
        [name setFrame:NSMakeRect(40, NSMinY(icon.frame) - 52, w - 80, 36)];
        [content addSubview:name];

        NSTextField *signature = MPWelcomeLabel(
            @"Detroit Automation Academy", 13, NO,
            [NSColor colorWithCalibratedWhite:0.27 alpha:1.0]);
        [signature setFrame:NSMakeRect(40, NSMinY(name.frame) - 28, w - 80, 20)];
        [content addSubview:signature];

        NSTextField *copyLine = MPWelcomeLabel(
            @"A Markdown editor with live preview, maintained for "
            @"macOS High Sierra.", 12.5, NO, [NSColor blackColor]);
        [copyLine setFrame:NSMakeRect(50, NSMinY(signature.frame) - 58,
                                      w - 100, 44)];
        [[copyLine cell] setWraps:YES];
        [content addSubview:copyLine];

        NSButton *continueButton = [[NSButton alloc]
            initWithFrame:NSMakeRect((w - 140) / 2, 44, 140, 32)];
        [continueButton setTitle:@"Continue"];
        [continueButton setBezelStyle:NSBezelStyleRounded];
        [continueButton setFont:[NSFont systemFontOfSize:13]];
        [continueButton setTarget:self];
        [continueButton setAction:@selector(continuePressed:)];
        [continueButton setKeyEquivalent:@"\r"];
        [content addSubview:continueButton];

        // SDS-10 10.2: the version line is composed at runtime from
        // the bundle's own Info.plist (CFBundleShortVersionString +
        // CFBundleVersion) — never hardcoded into the interface.
        NSDictionary *info = [[NSBundle mainBundle] infoDictionary];
        NSString *shortVersion = info[@"CFBundleShortVersionString"];
        NSString *buildVersion = info[@"CFBundleVersion"];
        NSString *versionText;
        if (buildVersion.length && ![buildVersion isEqualToString:shortVersion])
            versionText = [NSString stringWithFormat:@"Version %@ (%@)",
                           shortVersion, buildVersion];
        else
            versionText = [NSString stringWithFormat:@"Version %@",
                           shortVersion];
        NSTextField *version = MPWelcomeLabel(
            versionText, 11, NO,
            [NSColor colorWithCalibratedWhite:0.27 alpha:1.0]);
        [version setFrame:NSMakeRect(40, 14, w - 80, 16)];
        [content addSubview:version];

        [window center];

        [[NSNotificationCenter defaultCenter]
            addObserver:self selector:@selector(windowWillClose:)
                   name:NSWindowWillCloseNotification object:window];
    }
    return self;
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [_pulseTimer invalidate];
    [_startupSound stop];
}

// SDS-8 addendum / SDS-10 10.3: the standard startup sound plays
// ONCE when the welcome screen presents, at system volume, no loop.
// A missing asset proceeds silently; there is no error surface.
- (void)playStartupSoundOnce
{
    if (self.soundPlayed)
        return;
    self.soundPlayed = YES;
    NSString *path = [[NSBundle mainBundle] pathForResource:@"startup-sound"
                                                     ofType:@"wav"];
    if (path == nil)
        return;
    self.startupSound = [[NSSound alloc] initWithContentsOfFile:path
                                                     byReference:NO];
    [self.startupSound play];
}

// SDS-8 motion: a gentle pulse on the mark while the welcome is up,
// static under Reduce Motion (the APD welcome's form).
- (void)startPulseIfAllowed
{
    if ([[NSWorkspace sharedWorkspace] accessibilityDisplayShouldReduceMotion])
        return;
    if (self.pulseTimer)
        return;
    self.pulseUp = NO;
    self.pulseTimer = [NSTimer scheduledTimerWithTimeInterval:0.9
                                                        target:self
                                                      selector:@selector(tickPulse:)
                                                      userInfo:nil
                                                       repeats:YES];
}

- (void)tickPulse:(NSTimer *)timer
{
    self.pulseUp = !self.pulseUp;
    [NSAnimationContext runAnimationGroup:^(NSAnimationContext *ctx) {
        ctx.duration = 0.85;
        self.iconView.animator.alphaValue = self.pulseUp ? 0.72 : 1.0;
    } completionHandler:nil];
}

- (void)showWindow:(id)sender
{
    [super showWindow:sender];
    [self playStartupSoundOnce];
    [self startPulseIfAllowed];
}

- (void)continuePressed:(id)sender
{
    [[self window] close];
}

// Escape dismisses, exactly like Continue (SDS-8: user-driven dismissal).
- (void)cancelOperation:(id)sender
{
    [self continuePressed:sender];
}

- (void)windowWillClose:(NSNotification *)notification
{
    [self.pulseTimer invalidate];
    self.pulseTimer = nil;
}

@end
