//
//  SQUPreferencePaneMIDI.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Cocoa/Cocoa.h>

@interface SQUPreferencePaneMIDI : NSViewController

@property (nonatomic, readonly) NSArray *sampleBanks;
@property (nonatomic, readonly) NSArray *sampleBankDisplayName;

@property (nonatomic, readonly) NSArray *midiDevices;

@end
