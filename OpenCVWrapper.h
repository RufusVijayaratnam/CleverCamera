//
//  OpenCVWrapper.h
//  CleverCamera
//
//  Created by Rufus Vijayaratnam on 28/02/2020.
//  Copyright © 2020 Rufus Vijayaratnam. All rights reserved.
//


// Need this ifdef, so the C++ header won't confuse Swift


#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>


@interface OpenCVWrapper : NSObject
-(id)initWithImageView:(UIImageView*)iv;
-(void)resetInitialisation;
-(void)startCamera;
-(void)stopCamera;
-(void)doBlueTooth;
@end

