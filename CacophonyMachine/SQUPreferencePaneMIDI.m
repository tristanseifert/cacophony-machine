//
//  SQUPreferencePaneMIDI.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <CoreMIDI/CoreMIDI.h>

#import "SQUPreferencePaneMIDI.h"

@interface SQUPreferencePaneMIDI ()

-  (NSArray *) pathsInLibraries:(NSString *) inSubPath;

- (void) enumerateMIDIDestinations;

@end

@implementation SQUPreferencePaneMIDI

- (id) init {
	if(self = [super initWithNibName:@"SQUPreferencePaneMIDI"
							  bundle:[NSBundle bundleForClass:self.class]]) {
		// discover the MIDI banks: /Library/Audio/Sounds/Banks and ~/Library/Audio/Sounds/Banks
		NSArray *banks = [self pathsInLibraries:@"/Audio/Sounds/Banks/"];
		NSMutableArray *files = [NSMutableArray new];
		
		for (NSString *path in banks) {
			// check if the directory exists
			if(![[NSFileManager defaultManager] fileExistsAtPath:path]) {
				continue;
			}
			
			NSError *err = nil;
			NSArray *paths = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:path
																				 error:&err];
			DDAssert(!err, @"Error enumerating %@: %@", path, err);
			
			for (NSString *fragment in paths) {
				NSString *full = [path stringByAppendingPathComponent:fragment];
				
				// end with .sf2?
				if([full hasSuffix:@".sf2"]) {
					[files addObject:full];
				}
			}
		}
		
		//DDLogVerbose(@"Found banks: %@", files);
		_sampleBanks = files;
		
		// get the display names
		_sampleBankDisplayName = [NSMutableArray new];
		for (NSString *path in files) {
			[((NSMutableArray *) _sampleBankDisplayName) addObject:[path lastPathComponent]];
		}
		
		// enumerate for MIDI devices
		[self enumerateMIDIDestinations];
	}
	
	return self;
}

- (void) viewDidLoad {
    [super viewDidLoad];
    // Do view setup here.
}

#pragma mark - Helpers
/**
 * Returns an array of three paths of "inSubPath" in the system, local, and user
 * library directories.
 */
-  (NSArray *) pathsInLibraries:(NSString *) inSubPath {
	NSMutableArray *arr = [NSMutableArray new];
	
	// system library (/System/Library)
	NSArray *domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSSystemDomainMask, YES);
	NSString *baseDir= [domains objectAtIndex:0];
	NSString *result = [baseDir stringByAppendingPathComponent:inSubPath];
	[arr addObject:result];
	
	// local library (/Library)
	domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSLocalDomainMask, YES);
	baseDir= [domains objectAtIndex:0];
	result = [baseDir stringByAppendingPathComponent:inSubPath];
	[arr addObject:result];
	
	// user's library (~/Library)
	domains = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	baseDir= [domains objectAtIndex:0];
	result = [baseDir stringByAppendingPathComponent:inSubPath];
	[arr addObject:result];
	
	return arr;
}

#pragma mark - Hardware MIDI
/**
 * Detects the different MIDI destinations in the system.
 */
- (void) enumerateMIDIDestinations {
	ItemCount numDevices = MIDIGetNumberOfDestinations();
	DDLogVerbose(@"Found %lu MIDI destinations", numDevices);
	
	NSMutableArray *arr = [NSMutableArray new];
	
	// go through all destinations
	for (unsigned int i = 0; i < numDevices; i++) {
		NSMutableDictionary *info = [NSMutableDictionary new];
		
		// get destination reference
		MIDIEndpointRef dest = MIDIGetDestination(i);
		DDAssert(dest, @"Couldn't get MIDI endpoint %u", i);
		
		// get name property
		CFStringRef str;
		MIDIObjectGetStringProperty(dest, kMIDIPropertyDisplayName, &str);
		info[@"name"] = (NSString *) CFBridgingRelease(str);
		
		// get number of ports
		SInt32 channels;
		MIDIObjectGetIntegerProperty(dest, kMIDIPropertyTransmitChannels, &channels);
		info[@"channels"] = @(channels);
		
		// get icon
		CFStringRef iconPath;
		MIDIObjectGetStringProperty(dest, kMIDIPropertyImage, &iconPath);
		NSString *path = CFBridgingRelease(iconPath);

		if(path) {
			NSImage *img = [[NSImage alloc] initWithContentsOfFile:path];
			if(img) {
				info[@"icon"] = img;
			}
		}
		
		// add to array
		[arr addObject:info];
	}

	_midiDevices = arr;
	DDLogVerbose(@"MIDI destinations: %@", _midiDevices);
}

@end
