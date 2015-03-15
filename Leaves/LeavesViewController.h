//
//  LeavesViewController.h
//  Leaves
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

//
// Modificato da: Gigi Villa 2012
//



#import <UIKit/UIKit.h>
#import "LeavesView.h"
#import "LeavesViewControllerProtocol.h"

@interface LeavesViewController : UIViewController <UIScrollViewDelegate, UITextFieldDelegate, LeavesViewControllerProtocol>
{
	LeavesView *leavesView;
    BOOL isLandscape;
	
	UIView *bigImageView;
	
	BOOL isBigImage;
	
	// Larghezza miniature per il calcolo della pagina cliccata
	float thumbWidth;
	
	// Devo tenere in pancia sta cosa altrimenti quando si va in posizione sdraiata 
	// la scrollview delle miniature mi rimane con altezza 0, cazzo.
	float thumbScollerHeight;
	
	// Contenitore per le miniature della pagine, le creo una volta e non ci penso più
	NSMutableArray *thumbnailArray;
	
	// Flag per sapere se ho già creato le miniature
	BOOL thumbsReady;
	
	int numberOfPages;
}

@property (nonatomic, strong) IBOutlet LeavesView *leavesView;
@property (nonatomic, strong) IBOutlet UIScrollView *scroller;
@property (nonatomic, strong) IBOutlet UIScrollView *thumbScroller;

-(IBAction)showThumbnails:(id)sender;

-(void)goToPage:(NSNumber *)destination;

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle;
- (id)init;

- (void)thumbnailTapListener:(UITapGestureRecognizer *)recognizer;

@end