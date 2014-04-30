//
//  ViewController.h
//  decPerfTestApp
//
//  Created by video.mmf on 4/28/14.
//  Copyright (c) 2014 wme. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController {
    __weak IBOutlet UILabel *statusText;
    __weak IBOutlet UIButton *testButton;
}

-(IBAction) StartTestButtonPressed:(id)sender;

@end
