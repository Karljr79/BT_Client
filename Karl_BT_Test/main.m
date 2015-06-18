//
//  main.m
//  Karl_BT_Test
//
//  Created by Hirschhorn Jr, Karl on 2/18/15.
//  Copyright (c) 2015 PayPal. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <ADEUMInstrumentation/ADEUMInstrumentation.h>
#import "AppDelegate.h"

int main(int argc, char * argv[]) {
    [ADEumInstrumentation initWithKey:@"AD-AAB-AAA-ZNP"];
    @autoreleasepool {
        return UIApplicationMain(argc, argv, nil, NSStringFromClass([AppDelegate class]));
    }
}
