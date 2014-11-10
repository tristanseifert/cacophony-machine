//
//  AppDelegate.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@class SQUPreferencesController;
@interface SQUAppDelegate : NSObject <NSApplicationDelegate> {
	IBOutlet NSPopUpButton *_patch1;
	IBOutlet NSPopUpButton *_patch2;
	
	SQUPreferencesController *_prefsController;
}

- (IBAction) openPreferencesWindow:(id) sender;

@end

