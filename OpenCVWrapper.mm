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
    
    CvVideoCamera * videoCamera;
    myController * swift;
    
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

bool isInitialised = false;
bool robotLocated = false;
double cxInitial;
double cyInitial;
int areaInitial;
int runCount = 0;
vector<cv::Point>initialCentroids;

- (void)processImage:(Mat&)image {
    Mat HSVImage, redMask1, redMask2, greenMask, blueMask, grayImage;
    cvtColor(image, HSVImage, COLOR_BGRA2BGR);
    cvtColor(HSVImage, HSVImage, COLOR_BGR2HSV);
    cvtColor(image, grayImage, COLOR_BGRA2GRAY);
    
    threshold(grayImage, grayImage, 250, 255, THRESH_BINARY);
    
    
    inRange(HSVImage, Scalar(0, 140, 120), Scalar(5, 255, 255), redMask1);
    inRange(HSVImage, Scalar(175, 140, 120), Scalar(180, 255, 255), redMask2);
    inRange(HSVImage, Scalar(60, 150, 40), Scalar(100, 255, 255), greenMask);
    //inRange(HSVImage, Scalar(100, 100, 250), Scalar(1000, 1000, 1000), blueMask);
    redMask1 = redMask1 + redMask2;
    int refinementResolution = 20;
    
    Mat refinedRed, refinedGreen, redBoxes, greenBoxes, refinedBlue, brightBlue, refinedGray;
    
    refinedRed = refineColour(redMask1, image, refinementResolution);
    refinedGreen = refineColour(greenMask, image, refinementResolution);
    
    if (!isInitialised) initialiseLocation(refinedRed);
    if (isInitialised && !robotLocated) findRobotWithMovement(refinedRed);
    
    drawBoxes(refinedRed, image);
    drawBoxes(refinedGreen, image);
    
    
    Mat pixelTransformMatrix = findPixelMap();
    
    if(robotLocated) robotTracking(refinedRed, image, pixelTransformMatrix);
    runCount++;
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
    int label_count = connectedComponentsWithStats(refinedImage, labels, stats, centroids, 8);
    
    try {
        
        for (int i = 1; i < label_count; i++) {
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
            
            // putText(image, coords, pointOne, FONT_HERSHEY_SIMPLEX, 2, Scalar(255,255,255), 2);
            
            rectangle(image, pointOne, pointTwo, mean(theColour), 9);
        }
    } catch(std::out_of_range& lesError) {
        cout << lesError.what() << endl;
    } catch(...) {
        cout << "some weird error" << endl;
    }
    
}

cv::Mat findPixelMap() {
    Mat pixelMapMatrix;
    vector<Point2f>pixelPoints;
    vector<Point2f>boardPoints;
    
    pixelPoints.push_back(Point2f(480, 450));
    pixelPoints.push_back(Point2f(621, 374));
    pixelPoints.push_back(Point2f(782, 569));
    pixelPoints.push_back(Point2f(848, 483));
    pixelPoints.push_back(Point2f(135, 445));
    pixelPoints.push_back(Point2f(485, 334));
    pixelPoints.push_back(Point2f(315, 295));
    pixelPoints.push_back(Point2f(282, 266));
    pixelPoints.push_back(Point2f(490, 260));
    pixelPoints.push_back(Point2f(475, 250));
    pixelPoints.push_back(Point2f(730, 270));
    pixelPoints.push_back(Point2f(800, 270));
    pixelPoints.push_back(Point2f(410, 220));
    
    boardPoints.push_back(Point2f(1200, 1270));
    boardPoints.push_back(Point2f(1200, 1730));
    boardPoints.push_back(Point2f(1650, 1065));
    boardPoints.push_back(Point2f(1650, 1335));
    boardPoints.push_back(Point2f(800, 1100));
    boardPoints.push_back(Point2f(800, 1900));
    boardPoints.push_back(Point2f(400, 2050));
    boardPoints.push_back(Point2f(100, 2330));
    boardPoints.push_back(Point2f(510, 2550));
    boardPoints.push_back(Point2f(400, 2700));
    boardPoints.push_back(Point2f(1080, 2700));
    boardPoints.push_back(Point2f(1200, 2700));
    boardPoints.push_back(Point2f(36, 2964));
    
    pixelMapMatrix = findHomography(pixelPoints, boardPoints, FM_RANSAC);
    
    return pixelMapMatrix;
}

//MARK: Actually find real coordinates

void robotTracking(cv::Mat& refinedImage,  cv::Mat& image, cv::Mat& pixelTransformMatix) {
    cout << "attempting to recognise in this frame and track" << endl;
    Mat labels, stats, centroids;
    int label_count = connectedComponentsWithStats(refinedImage, labels, stats, centroids, 8);
    cout << "label_count is: ";
    cout << label_count << endl;
    try {
        for (int i = 1; i < label_count; ++i) {
            double cx = centroids.at<double>(i, 0);
            double cy = centroids.at<double>(i, 1);
            int area = stats.at<int>(i, cv::CC_STAT_AREA);
            
            double deltaX = abs(cx - cxInitial);
            double deltaY = abs(cy - cyInitial);
            
            double deltaLocation = sqrt((pow(deltaX, 2) + pow(deltaY, 2)));
            double areaChange = (((double)area - areaInitial) / areaInitial) * 100;
            
            cout << "deltaLocation is: ";
            cout << deltaLocation << endl;
            cout << "area change is: ";
            cout << areaChange << endl;
            
            if (deltaLocation < 100 && areaChange < 10) {
                cout << "found robot in this frame" << endl;
                int x = stats.at<int>(i, cv::CC_STAT_LEFT);
                int y = stats.at<int>(i, cv::CC_STAT_TOP);
                int w = stats.at<int>(i, cv::CC_STAT_WIDTH);
                int h = stats.at<int>(i, cv::CC_STAT_HEIGHT);
                
                cv::Point pointOne;
                pointOne.x = x;
                pointOne.y = y;
                cv::Point pointTwo;
                pointTwo.x = x+w;
                pointTwo.y = y+h;
                
                rectangle(image, pointOne, pointTwo, Scalar(142, 255, 255), 9);
                
                String coords = format("(%d,%d)", (int)round(cx), (int)round(cy));
                
                putText(image, coords, pointOne, FONT_HERSHEY_SIMPLEX, 2, Scalar(255,255,255), 2);
                
                cxInitial = cx;
                cyInitial = cy;
                areaInitial = area;
                return;
            }
        }
    } catch(...) {
        cout << "some crash is happening" << endl;
    }
}

void findRobotWithMovement(const cv::Mat& image) {

    Mat labels, stats, centroids;
    int label_count = connectedComponentsWithStats(image, labels, stats, centroids, 8);
    
    
    for (int i = 0; i < label_count; ++i) {
        double cx = centroids.at<double>(i, 0);
        double cy = centroids.at<double>(i, 1);
        int area = stats.at<int>(i, cv::CC_STAT_AREA);
        double cx0 = initialCentroids.at(i).x;
        double cy0 = initialCentroids.at(i).y;
        
        double deltaX = abs(cx - cx0);
        double deltaY = abs(cy - cy0);
        
        double deltaLocation = sqrt((pow(deltaX, 2) + pow(deltaY, 2)));
        
        if (deltaLocation > 50) {
            cout << "Found moving object to track" << endl;
            cxInitial = cx;
            cyInitial = cy;
            areaInitial = area;
            robotLocated = true;
            return;
        }
        
    }
    
}

void initialiseLocation(const cv::Mat& refinedImage) {
    
    Mat labels, stats, centroids;
    int label_count = connectedComponentsWithStats(refinedImage, labels, stats, centroids, 8);
    try {
        for (int i = 1; i < label_count; ++i) {
            double cx = centroids.at<double>(i, 0);
            double cy = centroids.at<double>(i, 1);
            if (runCount < 20)  return;
            cv::Point anElementCentroid;
            anElementCentroid.x = cx;
            anElementCentroid.y = cy;
            initialCentroids.push_back(anElementCentroid);
            isInitialised = true;
            cout << "now isInitialised is: ";
            cout << isInitialised << endl;
        }
    } catch (std::out_of_range& lesError) {
        cout << "out of range error" << endl;
    } catch(cv::Exception& lesError) {
        cout << lesError.what() << endl;
    } catch (...) {
        cout << "not a cv or out of range error. What the fuck?" << endl;
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
