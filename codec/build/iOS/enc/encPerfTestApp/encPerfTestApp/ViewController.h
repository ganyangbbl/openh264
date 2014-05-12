//
//  ViewController.h
//  encPerfTestApp
//
//  Created by video.mmf on 4/22/14.
//  Copyright (c) 2014 cisco. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    __weak IBOutlet UILabel *statusText;
    __weak IBOutlet UIButton *testButton;
    NSTimer * cpuTimer;
}

-(IBAction) StartTestButtonPressed:(id)sender;

@end
