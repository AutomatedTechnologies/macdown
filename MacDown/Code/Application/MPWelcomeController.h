//
//  MPWelcomeController.h
//  MacDown
//
//  SDS-8 standard animated-logo welcome screen + SDS-10 conformance
//  (Detroit Automation Academy, 2026-11-10): the welcome draws the
//  app's own AppIcon composition (via [NSApp applicationIconImage],
//  so the welcome mark is the bundle icon by construction — SDS-10
//  10.1.2), displays the build's version read from the bundle's own
//  Info.plist at runtime (10.2.2, never hardcoded), and plays the
//  standard startup sound once at presentation (10.3; the bundled
//  startup-sound.wav is byte-identical to the library master).
//

#import <Cocoa/Cocoa.h>

@interface MPWelcomeController : NSWindowController

@end
