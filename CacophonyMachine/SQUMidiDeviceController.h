//
//  SQUMidiDeviceController.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreMIDI/CoreMIDI.h>

@interface SQUMidiDeviceController : NSObject {
	MIDIClientRef _client;
	MIDIEndpointRef _endpoint;
}

@end
