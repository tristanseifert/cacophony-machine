//
//  SQUPreferencesController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import "SQUPreferencesController.h"

@interface SQUPreferencesController ()

- (void) toolbarItemSelected:(id) sender;
- (void) updateWithIdentifier:(NSString *) identifier andAnimation:(BOOL) animate;

@end

@implementation SQUPreferencesController

/**
 * Custom initialiser to make life easier
 */
- (id) init {
	if(self = [super initWithWindowNibName:@"SQUPreferencesController"]) {
		
	}
	
	return self;
}

/**
 * Sets up the toolbar.
 */
- (void) windowDidLoad {
    [super windowDidLoad];
    
	// Load the preference panel information
	_panels = [NSArray arrayWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"SQUPreferencesPanels" ofType:@"plist"]];
	_identifiers = [NSMutableArray new];
	
	for (NSDictionary *dict in _panels) {
		[_identifiers addObject:dict[@"identifier"]];
	}
	
	// Set up toolbar
	_toolbar = [[NSToolbar alloc] initWithIdentifier:@"SQUPreferencesController"];
	_toolbar.allowsUserCustomization = NO;
	_toolbar.delegate = self;
	
	self.window.toolbar = _toolbar;
	
	// is the last selection valid
	NSString *lastPanel = [[NSUserDefaults standardUserDefaults] objectForKey:@"SQUPreferencesControllerLast"];
	if([_identifiers containsObject:lastPanel]) {
		[_toolbar setSelectedItemIdentifier:lastPanel];
	} else {
		[[NSUserDefaults standardUserDefaults] removeObjectForKey:@"SQUPreferencesControllerLast"];
		[_toolbar setSelectedItemIdentifier:_identifiers[0]];
	}
	
	// update selection
	[self updateWithIdentifier:_toolbar.selectedItemIdentifier andAnimation:NO];
}

#pragma mark - Toolbar
- (NSToolbarItem *) toolbar:(NSToolbar *) toolbar itemForItemIdentifier:(NSString *) itemIdentifier willBeInsertedIntoToolbar:(BOOL) flag {
	NSDictionary *itemInfo = nil;
	
	// try to find it
	for (NSDictionary *dict in _panels) {
		if([dict[@"identifier"] isEqualToString:itemIdentifier]) {
			itemInfo = dict;
			break;
		}
	}
	
	DDAssert(itemInfo, @"Could not find preferences item: %@", itemIdentifier);
	
	// determine icon name
	NSImage *icon = [NSImage imageNamed:itemInfo[@"icon"]];
	if(!icon) {
		icon = [NSImage imageNamed:NSImageNamePreferencesGeneral];
	}
	
	// build the toolbar item
	NSToolbarItem *item = [[NSToolbarItem alloc] initWithItemIdentifier:itemIdentifier];
	item.label = itemInfo[@"title"];
	item.image = icon;
	
	item.target = self;
	item.action = @selector(toolbarItemSelected:);
	
	return item;
}

- (NSArray *) toolbarDefaultItemIdentifiers:(NSToolbar *) toolbar {
	return _identifiers;
}

- (NSArray *)toolbarAllowedItemIdentifiers:(NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

- (NSArray *) toolbarSelectableItemIdentifiers:(NSToolbar *) toolbar {
	return [self toolbarDefaultItemIdentifiers:toolbar];
}

#pragma mark - Selection and View Updating
/**
 * Called when a toolbar item is actually selected.
 */
- (void) toolbarItemSelected:(id) sender {
	NSToolbarItem *item = sender;
	[self updateWithIdentifier:item.itemIdentifier andAnimation:YES];
}

/**
 * Called to update the user interface with a new pane. Does the grunt work of
 * reconfiguring the window, and updating the title.
 */
- (void) updateWithIdentifier:(NSString *) identifier andAnimation:(BOOL) animate {
	NSDictionary *itemInfo = nil;
	
	// try to find it
	for (NSDictionary *dict in _panels) {
		if([dict[@"identifier"] isEqualToString:identifier]) {
			itemInfo = dict;
			break;
		}
	}
	DDAssert(itemInfo, @"Could not find preferences item: %@", identifier);
	
	// Load the controller
	NSString *class = itemInfo[@"class"];
	if(NSClassFromString(class)) {
		NSViewController *ctrlr = [[NSClassFromString(class) alloc] init];
		
		// update content view
		NSView *view = ctrlr.view;
		if (self.window.contentView == view)
			return;
		
		NSRect windowRect = self.window.frame;
		
		CGFloat difference = (NSHeight([view frame]) - NSHeight([self.window.contentView frame])) * [self.window backingScaleFactor];
		windowRect.origin.y -= difference;
		windowRect.size.height += difference;
		
		difference = (NSWidth([view frame]) - NSWidth([self.window.contentView frame])) * [self.window backingScaleFactor];
		windowRect.size.width += difference;
		
		[view setHidden:YES];
		[self.window setContentView:view];
		[self.window setFrame:windowRect display:animate animate:animate];
		[view setHidden:NO];
	} else {
		DDAssert(false, @"Couldn't load %@", class);
	}
	
	// update window title
	self.window.title = itemInfo[@"title"];
	
	// store selected item
	[[NSUserDefaults standardUserDefaults] setObject:identifier
											  forKey:@"SQUPreferencesControllerLast"];
}

@end
