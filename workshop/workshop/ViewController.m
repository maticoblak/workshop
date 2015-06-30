//
//  ViewController.m
//  workshop
//
//  Created by Matic Oblak on 6/30/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

#import "ViewController.h"
#import "MainView.h"

@interface ViewController ()

@property (weak, nonatomic) IBOutlet MainView *openGLView;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:animated];    
    [self.openGLView startAnimating];
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
    [self.openGLView stopAnimating];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
