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

@class SQUMIDIOutputController;
@class SQUTrackingImageController;
@interface SQUTrackingController : NSObject <LeapListener> {
	LeapController *_controller;
	
	AudioComponentInstance _toneUnit;
	
	IBOutlet SQUTrackingImageController *_imageController;
	IBOutlet SQUMIDIOutputController *_midiController;
	
@public
	float theta[2];
	float amplitude[2];
	float frequency[2];
}

@property (readonly, nonatomic) CGFloat leftSensitivity;
@property (readonly, nonatomic) CGFloat rightSensitivity;
@property (readonly, nonatomic) NSUInteger leftOffset;
@property (readonly, nonatomic) NSUInteger rightOffset;

@property (readonly, nonatomic) NSUInteger leftPatch;
@property (readonly, nonatomic) NSUInteger rightPatch;

@property (readonly, nonatomic) NSUInteger connectionStatus;

@property (readonly, nonatomic) NSMutableDictionary *leftHandData;
@property (readonly, nonatomic) NSMutableDictionary *rightHandData;

@end
