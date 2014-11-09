//
//  SQUTrackingController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#include "MidiDefines.h"

#import "SQUTrackingImageController.h"
#import "SQUTrackingController.h"

@interface SQUTrackingController ()

- (void) initAudioUnit;
- (void) initMIDI;

- (void) doPatchChangeOnChannel:(unsigned int) i forPatch:(UInt32) patch;
- (void) doNoteOnOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum andVelocity:(UInt32) velocity;
- (void) doNoteOffOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum;

@end

static OSStatus RenderTone(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
					const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
					UInt32 inNumberFrames, AudioBufferList *ioData);

@implementation SQUTrackingController

- (id) init {
	if(self = [super init]) {
		_controller = [[LeapController alloc] init];
		[_controller addListener:self];
		[_controller setPolicy:LEAP_POLICY_IMAGES];
		
		_leftHandData = [NSMutableDictionary new];
		_rightHandData = [NSMutableDictionary new];
		
		_leftSensitivity = 2.f;
		_rightSensitivity = 2.f;
		
		_leftOffset = 32;
		_rightOffset = 32;
		
		_leftPatch = 2;
		_rightPatch = 9;
		
		[self initMIDI];
	}
	
	return self;
}

#pragma mark - Leap delegate
- (void) onInit:(NSNotification *) notification {
	DDLogVerbose(@"Initialised leap controller");
}

- (void) onConnect:(NSNotification *) notification {
	[self willChangeValueForKey:@"connectionStatus"];
	_connectionStatus = 1;
	[self didChangeValueForKey:@"connectionStatus"];
	
/*	// start audio unit
	OSErr err = AudioUnitInitialize(_toneUnit);
	DDAssert(err == noErr, @"Error initializing unit: %hd", err);

	// Start playback
	err = AudioOutputUnitStart(_toneUnit);
	DDAssert(err == noErr, @"Error starting unit: %hd", err);*/
}

- (void) onDisconnect:(NSNotification *) notification {
	[self willChangeValueForKey:@"connectionStatus"];
	_connectionStatus = 0;
	[self didChangeValueForKey:@"connectionStatus"];
	
/*	// stop playing
	AudioOutputUnitStop(_toneUnit);
	AudioUnitUninitialize(_toneUnit);
	AudioComponentInstanceDispose(_toneUnit);
	_toneUnit = nil;*/
}

- (void) onFrame:(NSNotification *) notification {
	LeapFrame *frame = [_controller frame:0];
	
	// update with frame
	[_imageController updateWithFrame:frame];
	
	[self willChangeValueForKey:@"leftHandData"];
	[self willChangeValueForKey:@"rightHandData"];
	
	// clear out left/right hand data
	_leftHandData[@"pitch"] = @(0.0);
	_rightHandData[@"pitch"] = @(0.0);
	_leftHandData[@"roll"] = @(0.0);
	_rightHandData[@"roll"] = @(0.0);
	_leftHandData[@"yaw"] = @(0.0);
	_rightHandData[@"yaw"] = @(0.0);
	_leftHandData[@"x"] = @(0.0);
	_rightHandData[@"x"] = @(0.0);
	_leftHandData[@"y"] = @(0.0);
	_rightHandData[@"y"] = @(0.0);
	_leftHandData[@"z"] = @(0.0);
	_rightHandData[@"z"] = @(0.0);
	
	// interpret it: divide it in the left and right quadrants
	for (LeapHand *hand in frame.hands) {
		if(hand.fingers.count) {
			// Calculate the average position
			LeapVector *avgPos = [[LeapVector alloc] init];
			
			for (LeapFinger *finger in hand.fingers) {
				avgPos = [avgPos plus:[finger tipPosition]];
			}
			
			avgPos = [avgPos divide:hand.fingers.count];
			
			// Get the yaw, pitch, and roll
			const LeapVector *normal = [hand palmNormal];
			const LeapVector *direction = [hand direction];
			
			// determine: left or right hand
			if(avgPos.x > 0) { // right
				_rightHandData[@"pitch"] = @(direction.pitch * LEAP_RAD_TO_DEG);
				_rightHandData[@"roll"] = @(normal.roll * LEAP_RAD_TO_DEG);
				_rightHandData[@"yaw"] = @(direction.yaw * LEAP_RAD_TO_DEG);
				
				_rightHandData[@"x"] = @(avgPos.x);
				_rightHandData[@"y"] = @(avgPos.y);
				_rightHandData[@"z"] = @(avgPos.z);
			} else {
				_leftHandData[@"pitch"] = @(direction.pitch * LEAP_RAD_TO_DEG);
				_leftHandData[@"roll"] = @(normal.roll * LEAP_RAD_TO_DEG);
				_leftHandData[@"yaw"] = @(direction.yaw * LEAP_RAD_TO_DEG);
				
				_leftHandData[@"x"] = @(avgPos.x);
				_leftHandData[@"y"] = @(avgPos.y);
				_leftHandData[@"z"] = @(avgPos.z);
			}
		}
	}
	
	[self didChangeValueForKey:@"leftHandData"];
	[self didChangeValueForKey:@"rightHandData"];
	
	// calculate frequency
	frequency[0] = [_leftHandData[@"y"] floatValue] * _leftSensitivity;
	frequency[1] = [_rightHandData[@"y"] floatValue] * _rightSensitivity;
	
	for(unsigned int i = 0; i < 2; i++) {
		if(frequency[i] <= 10.f) {
			theta[i] = 0.f;
		}
	}
	
	// calculate amplitude (abs(sqrt(x)))
	amplitude[0] = MIN((sqrtf(0.1 * fabs([_leftHandData[@"x"] floatValue])) * .25), 1.0);
	amplitude[1] = MIN((sqrtf(0.1 * [_rightHandData[@"x"] floatValue]) * .25), 1.0);
	
	// Interpret left and right channels
	for(unsigned int i = 0; i < 2; i++) {
		// is the channel on?
		if(frequency[i]) {
			// calculate the note number
			UInt32 noteNum = (127 * (frequency[i] / 8000.f));
			noteNum += (i == 0) ? _leftOffset : _rightOffset;
			noteNum = MIN(noteNum, 0x7F);
			
			// calculate the velocity number
			UInt32 velocity = (UInt32) (127.f * amplitude[i]);
			velocity = MIN(velocity, 0x7F);
			
			// Is it different from the last note?
			if(noteNum != lastNote[i] && noteStates[i] == 1) {
				[self doNoteOffOnChannel:i forNoteValue:lastNote[i]];
			}
			
			// Note on events are triggered by non-negative yaw values
			BOOL doNoteOn = NO;
			doNoteOn = ((i == 0 ? [_leftHandData[@"yaw"] floatValue] : [_rightHandData[@"yaw"] floatValue]) > 0);
			
			// process note on event, if needed
			if(noteStates[i] == 0 && doNoteOn) {
				UInt32 patch = (UInt32) ((i == 0) ? _leftPatch : _rightPatch);
				[self doPatchChangeOnChannel:i forPatch:patch];
				
				[self doNoteOnOnChannel:i forNoteValue:noteNum andVelocity:velocity];
			}
		} else {
			if(noteStates[i] == 1) {
				[self doNoteOffOnChannel:i forNoteValue:lastNote[i]];
			}
		}
	}
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
	lastNote[i] = noteNum;
	
	OSStatus result = MusicDeviceMIDIEvent(_outSynth, (kMidiMessage_NoteOn << 4 | i), noteNum, velocity, 0);
	DDAssert(result == 0, @"MusicDeviceMIDIEvent: Note On");
	
	noteStates[i] = 1;
	
#if LOG_NOTE_EVENTS
	DDLogVerbose(@"Note on (ch %u): note %u, velocity %u", i, noteNum, velocity);
#endif
}

/**
 * Performs a note off event for a given note on teh specified channel.
 */
- (void) doNoteOffOnChannel:(unsigned int) i forNoteValue:(UInt32) noteNum {
	noteStates[i] = 0;
	
	OSStatus result = MusicDeviceMIDIEvent(_outSynth, (kMidiMessage_NoteOff << 4 | i), noteNum, 0, 0);
	DDAssert(result == 0, @"MusicDeviceMIDIEvent: Note Off");
	
#if LOG_NOTE_EVENTS
	DDLogVerbose(@"Note off (ch %u): note %u", i, noteNum);
#endif
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
									  0/*sample offset*/);
		DDAssert(result == 0, @"MusicDeviceMIDIEvent");
	}
	
	for(unsigned int i = 0; i < 2; i++) {
		result = MusicDeviceMIDIEvent(_outSynth,
									  kMidiMessage_ProgramChange << 4 | i,
									  0/*prog change num*/, 0,
									  0/*sample offset*/);
		DDAssert(result == 0, @"MusicDeviceMIDIEvent");
	}
	
	CAShow(_outGraph);
	
	result = AUGraphStart(_outGraph);
	DDAssert(result == 0, @"AUGraphStart");
}

#pragma mark - AudioUnit
static OSStatus RenderTone(void *inRefCon, AudioUnitRenderActionFlags *ioActionFlags,
						   const AudioTimeStamp *inTimeStamp, UInt32 inBusNumber,
						   UInt32 inNumberFrames, AudioBufferList *ioData) {
	SQUTrackingController *ctrlr = (__bridge SQUTrackingController *) inRefCon;
	
	// Process each channels
	for(unsigned int channel = 0; channel < ioData->mNumberBuffers; channel++) {
		double theta = ctrlr->theta[channel];
		double theta_increment = 2.0 * M_PI * ctrlr->frequency[channel] / 44100;
		
		Float32 *buffer = (Float32 *) ioData->mBuffers[channel].mData;
	
		// Generate the samples
		for (UInt32 frame = 0; frame < inNumberFrames; frame++) {
			buffer[frame] = sin(theta) * ctrlr->amplitude[channel];
			
			theta += theta_increment;
			if (theta > 2.0 * M_PI) {
				theta -= 2.0 * M_PI;
			}
		}
		
		// save theta back
		ctrlr->theta[channel] = theta;
	}
 
	return noErr;
}

- (void) initAudioUnit {
	// Configure the search parameters to find the default playback output unit
	// (called the kAudioUnitSubType_RemoteIO on iOS but
	// kAudioUnitSubType_DefaultOutput on Mac OS X)
	AudioComponentDescription defaultOutputDescription;
	defaultOutputDescription.componentType = kAudioUnitType_Output;
	defaultOutputDescription.componentSubType = kAudioUnitSubType_DefaultOutput;
	defaultOutputDescription.componentManufacturer = kAudioUnitManufacturer_Apple;
	defaultOutputDescription.componentFlags = 0;
	defaultOutputDescription.componentFlagsMask = 0;
 
	// Get the default playback output unit
	AudioComponent defaultOutput = AudioComponentFindNext(NULL, &defaultOutputDescription);
	DDAssert(defaultOutput, @"Can't find default output");
 
	// Create a new unit based on this that we'll use for output
	OSErr err = AudioComponentInstanceNew(defaultOutput, &_toneUnit);
	DDAssert(_toneUnit, @"Error creating unit: %hd", err);
 
	// Set our tone rendering function on the unit
	AURenderCallbackStruct input;
	input.inputProc = RenderTone;
	input.inputProcRefCon = (__bridge void *)(self);
	err = AudioUnitSetProperty(_toneUnit,
							   kAudioUnitProperty_SetRenderCallback,
							   kAudioUnitScope_Input,
							   0,
							   &input,
							   sizeof(input));
	DDAssert(err == noErr, @"Error setting callback: %hd", err);
 
	// Set the format to 32 bit, single channel, floating point, linear PCM
	const int four_bytes_per_float = 4;
	const int eight_bits_per_byte = 8;
	
	AudioStreamBasicDescription streamFormat;
	streamFormat.mSampleRate = 44100;
	streamFormat.mFormatID = kAudioFormatLinearPCM;
	streamFormat.mFormatFlags =
	kAudioFormatFlagsNativeFloatPacked | kAudioFormatFlagIsNonInterleaved;
	streamFormat.mBytesPerPacket = four_bytes_per_float;
	streamFormat.mFramesPerPacket = 1;
	streamFormat.mBytesPerFrame = four_bytes_per_float;
	streamFormat.mChannelsPerFrame = 2;
	streamFormat.mBitsPerChannel = four_bytes_per_float * eight_bits_per_byte;

	err = AudioUnitSetProperty (_toneUnit,
								kAudioUnitProperty_StreamFormat,
								kAudioUnitScope_Input,
								0,
								&streamFormat,
								sizeof(AudioStreamBasicDescription));
	DDAssert(err == noErr, @"Error setting stream format: %hd", err);
}

@end
