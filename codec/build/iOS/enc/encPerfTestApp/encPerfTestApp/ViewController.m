//
//  ViewController.m
//  encPerfTestApp
//
//  Created by video.mmf on 4/22/14.
//  Copyright (c) 2014 cisco. All rights reserved.
//

extern int EncMain(int argc, char **argv);

#import "ViewController.h"
#import "UIDevice-Hardware.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    statusText.text = @"Test Ready!";
}

- (NSString*) getPathForWrite {
    NSArray * pathes =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentDirectory = [pathes objectAtIndex:0];
    return documentDirectory;
}

- (NSArray *) getCommandSet:(NSBundle *)bundle {
    NSError *error;
    NSString * str = [NSString stringWithContentsOfFile:[bundle pathForResource:@"enc_caselist" ofType:@"cfg"] encoding:NSASCIIStringEncoding error:&error];
    if (error == nil) {
        return [str componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]];
    }
    else{
        return nil;
    }
    
}

- (void) DoEncTest:(NSBundle *)bundle commandLineSet:(NSArray *)lines {
    const char * argv[32];
    for (int i=0; i < [lines count] - 1; i++)
    {
        NSString * strLine = [lines objectAtIndex:i];
        NSArray * encArgv = [strLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (int j=0; j < [encArgv count]; j++) {
            NSString * strTemp = [encArgv objectAtIndex:j];
            if (1 == j || 3== j || 8 == j) {
                argv[j] = [[bundle pathForResource:strTemp ofType:nil] UTF8String];
            }
            else if (5 == j) {
                argv[j] = [[NSString stringWithFormat:@"%@/%@", [self getPathForWrite], strTemp] UTF8String];
            }
            else {
                argv[j] = [strTemp UTF8String];
            }
        }
        NSLog(@"######Encoder Test %d Start########\nTest file: %@\ncfg file: %@\nbs file: %@\n", i+1, [encArgv objectAtIndex:3], [encArgv objectAtIndex:1], [encArgv objectAtIndex:5]);

        EncMain((int)[encArgv count], (char**)&argv[0]);
        [self GetCPUInfo];
        NSLog(@"######Encoder Test %d Completed########\n",i+1);
        
    }
    [self OutputProgress];
}

- (void) GetCPUInfo {
    UIDevice * device = [UIDevice currentDevice];
    NSString * cpuUsage = [device cpuUsage];
    NSLog(@"\nCPU Usage: %@\n",cpuUsage);
}

- (void) OutputProgress {
    NSString * path = [NSString stringWithFormat:@"%@/enc_progress.log", [self getPathForWrite]];
    NSString * data = [NSString stringWithFormat:@"flag"];
    NSMutableData * writer = [[NSMutableData alloc] init];
    [writer appendData:[data dataUsingEncoding:NSUTF8StringEncoding]];
    [writer writeToFile:path atomically:YES];
    //[writer release]
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction) StartTestButtonPressed:(id)sender
{
    NSBundle * bundle = [NSBundle mainBundle];
    NSArray * lines = [self getCommandSet:bundle];
    [self DoEncTest:bundle commandLineSet:lines];
    
    statusText.text = @"Test Completed!";
}

@end
