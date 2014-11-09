//
//  SQUTrackingImageController.m
//  CacophonyMachine
//
//  Created by Tristan Seifert on 11/9/14.
//  Copyright (c) 2014 Tristan Seifert. All rights reserved.
//

#import "SQUTrackingImageController.h"

@interface SQUTrackingImageController ()

- (NSImage *) convertLeapImage:(LeapImage *) image;

@end

@implementation SQUTrackingImageController

- (NSImage *) convertLeapImage:(LeapImage *) image {
	// gather some information about image
	int width = image.width;
	int height = image.height;
	
	// this is given in the Leap Motion SDK info
	size_t bitsPerComponent = 8;
	size_t bitsPerPixel = 8;
	size_t bytesPerRow = width;
	
	// create a CGDataProvider
	size_t bufferLength = width * height;
	CGDataProviderRef provider = CGDataProviderCreateWithData(NULL, image.data,
															  bufferLength, NULL);
	CGColorSpaceRef colorSpaceRef = CGColorSpaceCreateDeviceGray();
	CGBitmapInfo bitmapInfo = kCGBitmapByteOrderDefault;
	CGColorRenderingIntent renderingIntent = kCGRenderingIntentDefault;
	
	CGImageRef iref = CGImageCreate(width,
									height,
									bitsPerComponent,
									bitsPerPixel,
									bytesPerRow,
									colorSpaceRef,
									bitmapInfo,
									provider,   // data provider
									NULL,       // decode
									YES,        // should interpolate
									renderingIntent);
	
	return [[NSImage alloc] initWithCGImage:iref size:NSMakeSize(width, height)];
}

/**
 * Extract image data from the frame, then update the GUI with it.
 */
- (void) updateWithFrame:(LeapFrame *) frame {
	[self willChangeValueForKey:@"cameraImageLeft"];
	[self willChangeValueForKey:@"cameraImageRight"];
	
	if(frame.images.count == 2) {
		_cameraImageLeft = [self convertLeapImage:frame.images[0]];
		_cameraImageRight = [self convertLeapImage:frame.images[1]];
	}
		
	[self didChangeValueForKey:@"cameraImageLeft"];
	[self didChangeValueForKey:@"cameraImageRight"];
}

@end
