//
//  AppDelegate.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/8/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import "SQUAppDelegate.h"

static const char *instruments[] =
	{"Acoustic Grand Piano", "Bright Acoustic Piano",
	"Electric Grand Piano", "Honky-tonk Piano",
	"Electric Piano 1", "Electric Piano 2", "Harpsichord",
	"Clavi", "Celesta", "Glockenspiel", "Music Box",
	"Vibraphone", "Marimba", "Xylophone", "Tubular Bells",
	"Dulcimer", "Drawbar Organ", "Percussive Organ",
	"Rock Organ", "Church Organ", "Reed Organ",
	"Accordion", "Harmonica", "Tango Accordion",
	"Acoustic Guitar (nylon)", "Acoustic Guitar (steel)",
	"Electric Guitar (jazz)", "Electric Guitar (clean)",
	"Electric Guitar (muted)", "Overdriven Guitar",
	"Distortion Guitar", "Guitar harmonics",
	"Acoustic Bass", "Electric Bass (finger)",
	"Electric Bass (pick)", "Fretless Bass",
	"Slap Bass 1", "Slap Bass 2", "Synth Bass 1",
	"Synth Bass 2", "Violin", "Viola", "Cello",
	"Contrabass", "Tremolo Strings", "Pizzicato Strings",
	"Orchestral Harp", "Timpani", "String Ensemble 1",
	"String Ensemble 2", "SynthStrings 1", "SynthStrings 2",
	"Choir Aahs", "Voice Oohs", "Synth Voice",
	"Orchestra Hit", "Trumpet", "Trombone", "Tuba",
	"Muted Trumpet", "French Horn", "Brass Section",
	"SynthBrass 1", "SynthBrass 2", "Soprano Sax",
	"Alto Sax", "Tenor Sax", "Baritone Sax", "Oboe",
	"English Horn", "Bassoon", "Clarinet", "Piccolo",
	"Flute", "Recorder", "Pan Flute", "Blown Bottle",
	"Shakuhachi", "Whistle", "Ocarina", "Lead 1 (square)",
	"Lead 2 (sawtooth)", "Lead 3 (calliope)", "Lead 4 (chiff)",
	"Lead 5 (charang)", "Lead 6 (voice)", "Lead 7 (fifths)",
	"Lead 8 (bass + lead)", "Pad 1 (new age)", "Pad 2 (warm)",
	"Pad 3 (polysynth)", "Pad 4 (choir)", "Pad 5 (bowed)",
	"Pad 6 (metallic)", "Pad 7 (halo)", "Pad 8 (sweep)",
	"FX 1 (rain)", "FX 2 (soundtrack)", "FX 3 (crystal)",
	"FX 4 (atmosphere)", "FX 5 (brightness)", "FX 6 (goblins)",
	"FX 7 (echoes)", "FX 8 (sci-fi)", "Sitar", "Banjo",
	"Shamisen", "Koto", "Kalimba", "Bag pipe", "Fiddle",
	"Shanai", "Tinkle Bell", "Agogo", "Steel Drums",
	"Woodblock", "Taiko Drum", "Melodic Tom", "Synth Drum",
	"Reverse Cymbal", "Guitar Fret Noise", "Breath Noise",
	"Seashore", "Bird Tweet", "Telephone Ring",
	"Helicopter", "Applause", "Gunshot"};

@interface SQUAppDelegate ()

@property (weak) IBOutlet NSWindow *window;
@end

@implementation SQUAppDelegate

- (void) awakeFromNib {
	for (unsigned int i = 0; i < 128; i++) {
		NSString *title = [NSString stringWithCString:instruments[i]
											 encoding:NSUTF8StringEncoding];
		
		[_patch1 addItemWithTitle:title];
		[_patch2 addItemWithTitle:title];
	}
}

- (void) applicationDidFinishLaunching:(NSNotification *) aNotification {
}

- (void)applicationWillTerminate:(NSNotification *)aNotification {
	// Insert code here to tear down your application
}

@end
