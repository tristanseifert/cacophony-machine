//
//  SQUMIDIOutputController.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>

// set to 1 to log note events to console
#define LOG_NOTE_EVENTS	1

@class SQUMidiDeviceController;
@interface SQUMIDIOutputController : NSObject {	
	// midi stuff
	AUGraph _outGraph;
	AUNode _synthNode, _limiterNode, _outNode;
	AudioUnit _outSynth;
	
	NSTimer *_statsTimer;
	
	SQUMidiDeviceController *_midiDevice;
	
@public
	// audio states
	UInt32 _lastNote[2];
	UInt32 _noteStates[2];
}

@property (nonatomic, readonly) NSNumber *averageCPUUsage;
@property (nonatomic, readonly) NSNumber *peakCPUUsage;

@property (nonatomic) CGFloat limiterGain;

- (void) initMIDI;

- (void) doPatchChangeOnChannel:(unsigned int) i forPatch:(UInt32) patch;
- (void) doNoteOnOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum andVelocity:(UInt32) velocity;
- (void) doNoteOffOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum;

@end
