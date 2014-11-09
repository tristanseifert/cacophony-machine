//
//  SQUTrackingImageController.h
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "LeapObjectiveC.h"

@interface SQUTrackingImageController : NSObject {
	
}

@property (nonatomic, readonly) NSImage *cameraImageLeft;
@property (nonatomic, readonly) NSImage *cameraImageRight;

- (void) updateWithFrame:(LeapFrame *) frame;

@end
