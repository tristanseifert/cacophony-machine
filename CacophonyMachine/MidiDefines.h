//
//  MidiDefines.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#ifndef CacophonyMachine_MidiDefines_h
#define CacophonyMachine_MidiDefines_h

enum {
	kMidiMessage_BankMSBControl 	= 0,
	kMidiMessage_NoteOff 			= 0x8,
	kMidiMessage_NoteOn 			= 0x9,
	kMidiMessage_ControlChange 		= 0xB,
	kMidiMessage_ProgramChange 		= 0xC,
	kMidiMessage_BankLSBControl		= 0x20,
};

#endif
