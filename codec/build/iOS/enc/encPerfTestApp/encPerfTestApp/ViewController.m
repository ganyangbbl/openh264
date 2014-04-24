//
//  ViewController.m
//  encPerfTestApp
//
//  Created by video.mmf on 4/22/14.
//  Copyright (c) 2014 cisco. All rights reserved.
//

extern int EncMain(int argc, char **argv);

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    
    NSBundle * bundle = [NSBundle mainBundle];
    NSArray * lines = [self getCommandSet:bundle];
    [self DoEncTest:bundle commandLineSet:lines];
    
    statusText.text = @"Test completed!";
}

- (NSString*) getPathForWrite {
    NSArray * pathes =  NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString * documentDirectory = [pathes objectAtIndex:0];
    return documentDirectory;
}

- (NSArray *) getCommandSet:(NSBundle *)bundle {
    NSError *error;
    NSString * str = [NSString stringWithContentsOfFile:[bundle pathForResource:@"caselist" ofType:@"cfg"] encoding:NSASCIIStringEncoding error:&error];
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
        NSArray * strArgv = [strLine componentsSeparatedByCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        for (int j=0; j < [strArgv count]; j++) {
            NSString * strTemp = [strArgv objectAtIndex:j];
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
        NSLog(@"Test file: %@\ncfg file: %@\nbs file:%@\n", [strArgv objectAtIndex:1], [strArgv objectAtIndex:3], [strArgv objectAtIndex:5]);
        EncMain([strArgv count], (char**)&argv[0]);
    }
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
