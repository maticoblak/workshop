//
//  MainView.h
//  workshop
//
//  Created by Matic Oblak on 6/30/15.
//  Copyright (c) 2015 D·Labs. All rights reserved.
//

@import UIKit;

@interface MainView : UIView

- (void)initializeOpenGL;

/*! Will start the animation
 @discussion openGL will be initialized if not yet
 */
- (void)startAnimating;
- (void)stopAnimating;

@end
