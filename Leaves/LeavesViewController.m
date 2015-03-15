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

#import "LeavesViewController.h"

#define ZOOM_STEP 1.5

@implementation LeavesViewController

@synthesize leavesView;
@synthesize scroller, thumbScroller;

- (void) initialize
{
}

- (id)initWithNibName:(NSString *)nibName bundle:(NSBundle *)nibBundle
{
   if (self = [super initWithNibName:nibName bundle:nibBundle])
   {
		[self initialize];
   }
   return self;
}

- (id)init {
   return [self initWithNibName:nil bundle:nil];
}

- (void) awakeFromNib {
	[super awakeFromNib];
	[self initialize];
}


#pragma mark LeavesViewDataSource methods

- (NSUInteger) numberOfPagesInLeavesView:(LeavesView*)leavesView {
	return 0;
}

- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx whithScale:(CGFloat)scale
{	
}

- (void) renderDoublePageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx whithScale:(CGFloat)scale
{
	
}

#pragma mark  UIViewController methods

- (void)loadView
{
	[super loadView];
}

-(void) initWithFrame:(CGRect)frame
{
    NSLog(@"initWithFrame");
}

- (void) viewDidLoad
{
	[super viewDidLoad];
	
	LeavesCache *cache = [LeavesCache sharedCacheWhithSize:leavesView.frame.size];
	
	leavesView.pageCache = cache;
	numberOfPages = cache.numberOfPages;
    [LeavesView setIsLandscape:isLandscape];
	leavesView.myController = self;
	[leavesView reloadData];
	
	scroller.maximumZoomScale = 3;
	scroller.minimumZoomScale = 1;
	
	thumbScollerHeight = thumbScroller.bounds.size.height;
	
	scroller.delegate = self;
	
	// Aggiungo il duoble tap allo scroller della view sfogliante
	UITapGestureRecognizer *tipTapRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tipTapHandler:)];
	[tipTapRecognizer setNumberOfTapsRequired:2];
	[scroller addGestureRecognizer:tipTapRecognizer];
	
	UITapGestureRecognizer *singleFingerTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(thumbnailTapListener:)];
	
	// Aggiungo listener di spremuta
	[thumbScroller addGestureRecognizer:singleFingerTap];
	
	// Invoco in background, un altro thread è di sicuro più veloce
	thumbsReady = NO;
	[self performSelectorInBackground:@selector(createThumbs) withObject:nil];
}

-(void)viewDidAppear:(BOOL)animated
{
	[leavesView layoutSubviews];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
	if(UIDeviceOrientationIsLandscape(self.interfaceOrientation))
	{
        isLandscape = YES;
	}
	else
	{
        isLandscape = NO;
	}
    
	return YES;
}

-(void)didRotateFromInterfaceOrientation:(UIInterfaceOrientation)fromInterfaceOrientation
{
	if(thumbScroller != nil)
	{
		//thumbScroller.frame = CGRectMake(0, 0, self.view.frame.size.width, thumbScollerHeight);
		if(thumbScroller.hidden == NO)
		{
			thumbScroller.hidden = YES;
		}
	}
}

#pragma mark scroll  view zoom

- (void)tipTapHandler:(UITapGestureRecognizer *)recognizer {
	
	float newScale = [scroller zoomScale] * ZOOM_STEP;
    CGRect zoomRect = [self zoomRectForScale:newScale withCenter:[recognizer locationInView:recognizer.view]];
    [scroller zoomToRect:zoomRect animated:YES];
}

- (UIView *)viewForZoomingInScrollView:(UIScrollView *)scrollView
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	return leavesView;
}

- (void)scrollViewDidEndZooming:(UIScrollView *)scrollView withView:(UIView *)view atScale:(float)scale
{
	NSLog(@"%@",NSStringFromSelector(_cmd));
	if(scale == 1)
	{
		leavesView.isZooming = NO;
		[leavesView performSelectorInBackground:@selector(getZoomImagesWithScale:) withObject:[NSNumber numberWithFloat:scale]];
	}
	else
	{
		leavesView.isZooming = YES;
		[leavesView performSelectorInBackground:@selector(getZoomImagesWithScale:) withObject:[NSNumber numberWithFloat:scale]];
	}
}


- (CGRect)zoomRectForScale:(float)scale withCenter:(CGPoint)center {
    
    CGRect zoomRect;
    
    // the zoom rect is in the content view's coordinates. 
    //    At a zoom scale of 1.0, it would be the size of the imageScrollView's bounds.
    //    As the zoom scale decreases, so more content is visible, the size of the rect grows.
    zoomRect.size.height = [scroller frame].size.height / scale;
    zoomRect.size.width  = [scroller frame].size.width  / scale;
    
    // choose an origin so as to get the right center.
    zoomRect.origin.x    = center.x - (zoomRect.size.width  / 2.0);
    zoomRect.origin.y    = center.y - (zoomRect.size.height / 2.0);
    
    return zoomRect;
}


#pragma mark azioni pulsanti
-(IBAction)showThumbnails:(id)sender
{
	if(thumbsReady == NO)
		return;
	
	if(thumbScroller.hidden == NO)
	{
		thumbScroller.hidden = YES;
		return;
	}
	else 
	{
		[self insertThubsInScroller];
	}
}

-(void)createThumbs
{
	NSLog(@"createThumbs");
	
	LeavesCache *cache = [LeavesCache sharedCache];
	cache.thumbnailSize = CGSizeMake(thumbScroller.bounds.size.height * 0.7, thumbScroller.bounds.size.height);
		
	thumbnailArray = [NSMutableArray arrayWithCapacity:numberOfPages];
	for(int k = 0 ; k < numberOfPages ; k++)
	{
		// Creazione miniatura, utilizzo la proporzione di un A4, poi si aggiusta da sola in fase di creazione
		UIImage *img = [cache thumbnailForPageIndex:k];
		[thumbnailArray addObject:img];
	}
	
	thumbsReady = YES;
	NSLog(@"fine createThumbs");
}

-(void) insertThubsInScroller
{
	[thumbScroller.subviews makeObjectsPerformSelector:@selector(removeFromSuperview)];
	float xPos = 0;

	if(isLandscape == NO)
	{
		for(int k = 0 ; k < thumbnailArray.count ; k++)
		{
			// Creazione miniatura, utilizzo la proporzione di un A4, poi si aggiusta da sola in fase di creazione
			if(isLandscape == NO)
			{
				UIImage *img = [thumbnailArray objectAtIndex:k];
				
				// Creazione vista
				UIImageView *imgView = [[UIImageView alloc] initWithImage:img];
				imgView.backgroundColor = [UIColor whiteColor];
				imgView.frame = CGRectMake(xPos, 0, img.size.width, img.size.height);
				
				[thumbScroller addSubview:imgView];
				
				xPos += img.size.width + 5;
				
				thumbWidth = img.size.width + 5;
			}
		}
	}

	else
	{
		for(int k = 0 ; k < thumbnailArray.count ; k++)
		{
			// La prima pagina è una singola
			UIImage *leftImg = [thumbnailArray objectAtIndex:k];
			UIImageView *leftImgView = [[UIImageView alloc] initWithImage:leftImg];
			
			if((k == 0) || (k + 1 == thumbnailArray.count))
			{
				if(k + 1 == thumbnailArray.count)
				{
					leftImgView.frame = CGRectMake(xPos, 0, leftImgView.frame.size.width, leftImgView.frame.size.height);
				}
				[thumbScroller addSubview:leftImgView];
				xPos += (leftImg.size.width) + 5;
				continue;
			}
	
			UIImage *rightImg = [thumbnailArray objectAtIndex:k + 1];
			UIImageView *rightImgView = [[UIImageView alloc] initWithImage:rightImg];
			rightImgView.frame = CGRectMake(rightImgView.frame.size.width, 0, rightImgView.frame.size.width, rightImgView.frame.size.height);
			
			UIView *totale = [[UIView alloc] initWithFrame:CGRectMake(0, 0, leftImgView.frame.size.width * 2, leftImgView.frame.size.height)];
			totale.frame = CGRectMake(xPos, 0, leftImgView.frame.size.width + rightImgView.frame.size.width, leftImgView.frame.size.height);
			totale.backgroundColor = [UIColor whiteColor];
			
			[totale addSubview:leftImgView];
			[totale addSubview:rightImgView];
			
			[thumbScroller addSubview:totale];
			
			xPos += (leftImg.size.width * 2) + 5;
			
			thumbWidth = (leftImg.size.width * 2) + 5;
			
			k++;
		}
	}

	
	// visualizzo
	thumbScroller.contentSize = CGSizeMake(xPos, thumbScroller.bounds.size.height);
	if(thumbScroller.contentSize.width > self.view.frame.size.width)
	{
		float offset = (isLandscape == YES ? [LeavesView getCurrentPageIndex] / 2 : [LeavesView getCurrentPageIndex]);
		[thumbScroller setContentOffset:CGPointMake(offset * thumbWidth - thumbScroller.frame.size.width / 2, 0) animated:YES];
	}
	else
	{
		[thumbScroller setContentOffset:CGPointMake(0, 0)];
	}
	
	// Bordo rosso non avrai il mio scalpo
	int index = (isLandscape == YES ? [LeavesView getCurrentPageIndex] / 2 : [LeavesView getCurrentPageIndex]);
	UIView *thumbView = [thumbScroller.subviews objectAtIndex:index];
	thumbView.layer.borderColor = [[UIColor redColor] CGColor];
	thumbView.layer.borderWidth = 2.0f;
	
	thumbScroller.hidden = NO;
	thumbScroller.delaysContentTouches = NO;
}

-(void)thumbnailTapListener:(UITapGestureRecognizer *)recognizer
{
	NSLog(@"Immaginetta tappata");
	
	CGPoint location  = [recognizer locationInView:thumbScroller];
	int pagePos = 0;
	if(isLandscape)
	{
		if(location.x > thumbWidth * 0.5)
		{
			pagePos = (location.x - thumbWidth * 0.5) / thumbWidth;
			pagePos++;
			pagePos *= 2;
		}
	}
	else
	{
		pagePos = location.x / thumbWidth;
	}
	
	// Hilight della pagina cliccata
	for(int k = 0 ; k < thumbScroller.subviews.count ; k++)
	{
		UIView *actual = [thumbScroller.subviews objectAtIndex:k];
		if(CGRectContainsPoint(actual.frame, location))
		{
			actual.layer.borderColor = [[UIColor redColor] CGColor];
			actual.layer.borderWidth = 2.0f;
		}
		else {
			actual.layer.borderColor = nil;
			actual.layer.borderWidth = 0.0f;
		}
	}
	
	NSLog(@"location = %@, pagePos = %d", NSStringFromCGPoint(location), pagePos);
	[leavesView goToPage:pagePos];
}

-(void)goToPage:(NSNumber *)destination
{
	NSLog(@"goToPage");
	
	thumbScroller.hidden = YES;
	[leavesView goToPage:[destination intValue] - 1];
}

- (void) viewWillAppear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:YES animated:animated];
    [super viewWillAppear:animated];
}

- (void) viewWillDisappear:(BOOL)animated
{
    [self.navigationController setNavigationBarHidden:NO animated:animated];
    [super viewWillDisappear:animated];
}

-(void) pageHasTurned
{
	NSLog(@"qui mi si diceh che una pagina è stata girata. Agita saggiamente.");
}

- (void)didReceiveMemoryWarning
{
	NSLog(@"Un memory warning!!! AAAARRRGH!! Fai qualcosa!!!");
}
@end