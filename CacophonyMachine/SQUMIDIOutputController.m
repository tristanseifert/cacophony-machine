//
//  SQUMIDIOutputController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#include "MidiDefines.h"

#import "SQUMIDIOutputController.h"

@interface SQUMIDIOutputController ()

- (void) updateStats;

@end

@implementation SQUMIDIOutputController

- (id) init {
	if(self = [super init]) {
		[self initMIDI];
		
		// set up timer
		_statsTimer = [NSTimer scheduledTimerWithTimeInterval:0.25 target:self selector:@selector(updateStats) userInfo:nil repeats:YES];
	}

	return self;
}

- (void) dealloc {
	[_statsTimer invalidate];
	_statsTimer = nil;
}

/**
 * Updates the patch for a given channel.
 */
- (void) doPatchChangeOnChannel:(unsigned int) i forPatch:(UInt32) patch {
	// patch change
	OSStatus result = MusicDeviceMIDIEvent(_outSynth, (kMidiMessage_ProgramChange << 4) | i, patch, 0, 0);
	DDAssert(result == 0, @"MusicDeviceMIDIEvent: patch change");
}

/**
 * Sends a note on event to a channel, with the given note on number. Does not
 * check for validity.
 */
- (void) doNoteOnOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum andVelocity:(UInt32) velocity {
	// send note on event
	_lastNote[i] = noteNum;
	
	OSStatus result = MusicDeviceMIDIEvent(_outSynth, (kMidiMessage_NoteOn << 4 | i), noteNum, velocity, 0);
	DDAssert(result == 0, @"MusicDeviceMIDIEvent: Note On");
	
	_noteStates[i] = 1;
	
#if LOG_NOTE_EVENTS
	DDLogVerbose(@"Note on (ch %u): note %u, velocity %u", i, noteNum, velocity);
#endif
}

/**
 * Performs a note off event for a given note on teh specified channel.
 */
- (void) doNoteOffOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum {
	_noteStates[i] = 0;
	
	OSStatus result = MusicDeviceMIDIEvent(_outSynth, (kMidiMessage_NoteOff << 4 | i), noteNum, 0, 0);
	DDAssert(result == 0, @"MusicDeviceMIDIEvent: Note Off");
	
#if LOG_NOTE_EVENTS
	DDLogVerbose(@"Note off (ch %u): note %u", i, noteNum);
#endif
}

#pragma mark - Stats
/**
 * Gets the average and max CPU usage stats.
 */
- (void) updateStats {
	[self willChangeValueForKey:@"averageCPUUsage"];
	[self willChangeValueForKey:@"peakCPUUsage"];
	
	Float32 average, peak;
	
	AUGraphGetCPULoad(_outGraph, &average);
	AUGraphGetMaxCPULoad(_outGraph, &peak);
	
	_averageCPUUsage = @(average * 100.f);
	_peakCPUUsage = @(peak * 100.f);
	
	[self didChangeValueForKey:@"averageCPUUsage"];
	[self didChangeValueForKey:@"peakCPUUsage"];
}

- (void) setLimiterGain:(CGFloat) limiterGain {
	_limiterGain = limiterGain;
	
	AudioUnit unit;
	AUGraphNodeInfo(_outGraph, _limiterNode, NULL, &unit);
	AudioUnitSetParameter(unit, kLimiterParam_PreGain, kAudioUnitScope_Global, 0, _limiterGain, 0);
	DDLogVerbose(@"Gain: %f", _limiterGain);
}

#pragma mark - MIDI
- (void) initMIDI {
	OSStatus result;
	AudioComponentDescription cd;
	
	result = NewAUGraph(&_outGraph);
	DDAssert(result == 0, @"NewAUGraph");
	
	cd.componentManufacturer = kAudioUnitManufacturer_Apple;
	cd.componentFlags = 0;
	cd.componentFlagsMask = 0;
	
	cd.componentType = kAudioUnitType_MusicDevice;
	cd.componentSubType = kAudioUnitSubType_DLSSynth;
	result = AUGraphAddNode(_outGraph, &cd, &_synthNode);
	DDAssert(result == 0, @"AUGraphAddNode");
	
	cd.componentType = kAudioUnitType_Effect;
	cd.componentSubType = kAudioUnitSubType_PeakLimiter;
	
	result = AUGraphAddNode(_outGraph, &cd, &_limiterNode);
	DDAssert(result == 0, @"AUGraphAddNode");
	
	cd.componentType = kAudioUnitType_Output;
	cd.componentSubType = kAudioUnitSubType_DefaultOutput;
	result = AUGraphAddNode(_outGraph, &cd, &_outNode);
	DDAssert(result == 0, @"AUGraphAddNode");
	
	result = AUGraphOpen(_outGraph);
	DDAssert(result == 0, @"AUGraphOpen");
	
	result = AUGraphConnectNodeInput(_outGraph, _synthNode, 0, _limiterNode, 0);
	DDAssert(result == 0, @"AUGraphConnectNodeInput");
	result = AUGraphConnectNodeInput(_outGraph, _limiterNode, 0, _outNode, 0);
	DDAssert(result == 0, @"AUGraphConnectNodeInput");
	
	// get synth unit
	result = AUGraphNodeInfo(_outGraph, _synthNode, 0, &_outSynth);
	DDAssert(result == 0, @"AUGraphNodeInfo");
	
	result = AUGraphInitialize(_outGraph);
	DDAssert(result == 0, @"AUGraphInitialize");
	
	
	for(unsigned int i = 0; i < 2; i++) {
		result = MusicDeviceMIDIEvent(_outSynth,
									  kMidiMessage_ControlChange << 4 | i,
									  kMidiMessage_BankMSBControl, 0,
									  0);
		DDAssert(result == 0, @"MusicDeviceMIDIEvent");
	}	
	for(unsigned int i = 0; i < 2; i++) {
		result = MusicDeviceMIDIEvent(_outSynth,
									  kMidiMessage_ProgramChange << 4 | i,
									  0/*prog change num*/, 0, 0);
		DDAssert(result == 0, @"MusicDeviceMIDIEvent");
	}
	
	CAShow(_outGraph);
	
	result = AUGraphStart(_outGraph);
	DDAssert(result == 0, @"AUGraphStart");
}

@end
