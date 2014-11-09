//
//  SQUMidiDeviceController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import "SQUMidiDeviceController.h"

@implementation SQUMidiDeviceController

static void MIDINotProc(const MIDINotification *message, void *ref) {
	SQUMidiDeviceController *ctrlr = (__bridge SQUMidiDeviceController *) ref;
}

- (id) init {
	if(self = [super init]) {
		// create client
		OSStatus result = MIDIClientCreate(CFSTR("CacophonyMachine"),
										   MIDINotProc, (__bridge void *)(self),
										   &_client);
		DDAssert(result == 0, @"MIDIClientCreate");
		
		// create endpoint
		result = MIDISourceCreate(_client, CFSTR("Port 1"), &_endpoint);
		DDAssert(result == 0, @"MIDISourceCreate");
		
		MIDIObjectSetIntegerProperty(_endpoint, kMIDIPropertyUniqueID, 0x1337);
	}
	
	return self;
}

@end
