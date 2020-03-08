//
//  OpenCVWrapper.m
//  CleverCamera
//
//  Created by Rufus Vijayaratnam on 28/02/2020.
//  Copyright © 2020 Rufus Vijayaratnam. All rights reserved.
//

#ifdef __cplusplus

#import <opencv2/opencv.hpp>

#import <opencv2/imgcodecs/ios.h>

#import <opencv2/videoio/cap_ios.h>

#endif

#import "OpenCVWrapper.h"
#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <CoreBluetooth/CoreBluetooth.h>
#import "CleverCamera-Swift.h"
#include <vector>
#include <exception>
#include <stdexcept>
#include <typeinfo>

using namespace cv;
using namespace std;

@interface OpenCVWrapper() <CvVideoCameraDelegate>
@end


@implementation OpenCVWrapper

{
    // A member variable holding the wrapped CvVideoCamera
    CvVideoCamera * videoCamera;
    //UIViewController ViewController *swiftController;
}



-(id)initWithImageView:(UIImageView*)iv {
    videoCamera = [[CvVideoCamera alloc] initWithParentView:iv];
    
    videoCamera.defaultAVCaptureDevicePosition = AVCaptureDevicePositionBack;
    videoCamera.defaultAVCaptureSessionPreset = AVCaptureSessionPresetPhoto;
    videoCamera.defaultAVCaptureVideoOrientation = AVCaptureVideoOrientationPortrait;
    videoCamera.defaultFPS = 30;
    videoCamera.grayscaleMode = NO;
    
    videoCamera.delegate = self;
    
    return self;
}

#ifdef __cplusplus
- (void)processImage:(Mat&)image {
    Mat HSVImage, redMask1, redMask2, greenMask;
    cvtColor(image, HSVImage, COLOR_BGRA2BGR);
    cvtColor(HSVImage, HSVImage, COLOR_BGR2HSV);
    
    inRange(HSVImage, Scalar(0, 120, 100), Scalar(5, 255, 255), redMask1);
    inRange(HSVImage, Scalar(175, 120, 100), Scalar(180, 255, 255), redMask2);
    inRange(HSVImage, Scalar(60, 150, 40), Scalar(100, 255, 255), greenMask);
    
    redMask1 = redMask1 + redMask2;
    
    int refinementResolution = 10;
    
    Mat refinedRed, refinedGreen, redBoxes, greenBoxes;
    
    refinedRed = refineColour(redMask1, image, refinementResolution);
    refinedGreen = refineColour(greenMask, image, refinementResolution);
    
    drawBoxes(refinedRed, image);
    drawBoxes(refinedGreen, image);
    UInt16 pixelCoordX = 2231;
    UInt16 pixelCoordY = 993;
    

    try {
        myController *swift =  [[myController alloc]init];
        [swift sendData: pixelCoordX positionY: pixelCoordY];
    } catch(...) {
        cout << "Lost BlueTooth Connection." << endl;
    }
}

Mat refineColour(cv::Mat& mask, const cv::Mat& image, const int refinementResolution) {
    
    Mat refinedImage = Mat(image.rows, image.cols, CV_8U);
    
    
    for (int y = 0; y < mask.rows / refinementResolution; y++) {
        for (int x = 0; x < mask.cols / refinementResolution; x++) {
            cv::Point  pointOne;
            pointOne.x = x*refinementResolution;
            pointOne.y = y*refinementResolution;
            cv::Point pointTwo;
            pointTwo.x = (x+1)*refinementResolution;
            pointTwo.y = (y+1)*refinementResolution;
            cv::Rect blockFrame(pointOne, pointTwo);
            Mat src = mask(blockFrame);
            cv::Scalar avg = mean(src);
            
            
            if (avg[0] >= 125.5) {
                refinedImage(blockFrame).setTo(255);
            }
        }
    }
    
    return refinedImage;
}

void drawBoxes(cv::Mat& refinedImage,  cv::Mat& image) {
    
    Mat labels, stats, centroids;
    Mat rectangles(image.rows, image.cols, CV_8UC3);
    //Mat rectangles(image.rows, image.cols, )
    int label_count = connectedComponentsWithStats(refinedImage, labels, stats, centroids, 8);
    
    try {
        
        for (int i = 1; i < label_count; i++)
        {
            int x = stats.at<int>(i, cv::CC_STAT_LEFT);
            int y = stats.at<int>(i, cv::CC_STAT_TOP);
            int w = stats.at<int>(i, cv::CC_STAT_WIDTH);
            int h = stats.at<int>(i, cv::CC_STAT_HEIGHT);
            //int area = stats.at<int>(i, cv::CC_STAT_AREA);
            double cx = centroids.at<double>(i, 0);
            double cy = centroids.at<double>(i, 1);
            
            cv::Point pointOne;
            pointOne.x = x;
            pointOne.y = y;
            cv::Point pointTwo;
            pointTwo.x = x+w;
            pointTwo.y = y+h;
            cv::Rect rectColour(pointOne, pointTwo);
            Mat theColour = image(rectColour);
            String coords = format("(%d,%d)", (int)round(cx), (int)round(cy));
            
            putText(image, coords, pointOne, FONT_HERSHEY_SIMPLEX, 2, Scalar(255,255,255), 2);
            
            rectangle(image, pointOne, pointTwo, mean(theColour), 9);
        }
    } catch(std::out_of_range& lesError) {
        cout << lesError.what() << endl;
    } catch(...) {
        cout << "some weird error" << endl;
    }
    
    
}
#endif


-(void)startCamera
{
    [videoCamera start];
}

-(void)stopCamera
{
    [videoCamera stop];
}

-(void)doBlueTooth {
    
}


@end
