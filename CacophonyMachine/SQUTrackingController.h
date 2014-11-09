//
//  SQUTrackingController.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LeapObjectiveC.h"

#import <CoreAudio/CoreAudio.h>
#import <AudioUnit/AudioUnit.h>
#include <AudioToolbox/AudioToolbox.h>

// set to 1 to log note events to console
#define LOG_NOTE_EVENTS	1

// delay between detecting note on and the timer firing
#define	NOTE_DELAY		1.0f

@class SQUTrackingImageController;
@interface SQUTrackingController : NSObject <LeapListener> {
	LeapController *_controller;
	
	AudioComponentInstance _toneUnit;
	
	// midi stuff
	AUGraph _outGraph;
	AUNode _synthNode, _limiterNode, _outNode;
	AudioUnit _outSynth;
	
	// hysterysis timer
	NSTimer *_newNoteTimer[2];
/*	struct {
		UInt32 note, channel;
	} newNoteTimerData[2];*/
	
	NSUInteger noteStates[2];
	UInt32 lastNote[2];
	
	IBOutlet SQUTrackingImageController *_imageController;
	
@public
	float theta[2];
	float amplitude[2];
	float frequency[2];
}

@property (nonatomic) CGFloat leftSensitivity;
@property (nonatomic) CGFloat rightSensitivity;
@property (nonatomic) NSUInteger leftOffset;
@property (nonatomic) NSUInteger rightOffset;

@property (nonatomic) NSUInteger leftPatch;
@property (nonatomic) NSUInteger rightPatch;

@property (nonatomic) NSUInteger connectionStatus;

@property (nonatomic) NSMutableDictionary *leftHandData;
@property (nonatomic) NSMutableDictionary *rightHandData;

@end
