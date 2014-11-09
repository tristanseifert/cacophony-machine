//
//  SQUTrackingController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#include "MidiDefines.h"

#import "SQUMIDIOutputController.h"
#import "SQUTrackingImageController.h"
#import "SQUTrackingController.h"

@interface SQUTrackingController ()

- (void) initAudioUnit;

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
	
/*	for(unsigned int i = 0; i < 2; i++) {
		if(frequency[i] <= 10.f) {
			theta[i] = 0.f;
		}
	}*/
	
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
			
			// Note on events are triggered by non-negative yaw values
			BOOL doNoteOn = NO;
			doNoteOn = ((i == 0 ? [_leftHandData[@"yaw"] floatValue] : [_rightHandData[@"yaw"] floatValue]) > 0);
			
			// Is it different from the last note?
			if((noteNum != _midiController->_lastNote[i] || !doNoteOn) && _midiController->_noteStates[i] == 1) {
				[_midiController doNoteOffOnChannel:i forNoteValue:_midiController->_lastNote[i]];
			}
			
			// process note on event, if needed
			if(_midiController->_noteStates[i] == 0 && doNoteOn) {
				UInt32 patch = (UInt32) ((i == 0) ? _leftPatch : _rightPatch);
				[_midiController doPatchChangeOnChannel:i forPatch:patch];
				
				[_midiController doNoteOnOnChannel:i forNoteValue:noteNum andVelocity:velocity];
			}
		} else {
			if(_midiController->_noteStates[i] == 1) {
				[_midiController doNoteOffOnChannel:i forNoteValue:_midiController->_lastNote[i]];
			}
		}
	}
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
