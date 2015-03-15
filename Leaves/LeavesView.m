//
//  LeavesView.m
//  Leaves
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

//
// Modificato da: Gigi Villa 2012
//


#import "LeavesView.h"

#define FOLLOW_LIMIT 1.0f

CGFloat distance(CGPoint a, CGPoint b);
CGFloat gradiToRad(CGFloat gradi);

@implementation LeavesView

static int currentPageIndex;
static BOOL isLandscape;

@synthesize leafEdge, pageCache, pageWidth, pageHeight, myController;

#pragma mark creazione layers
- (void) createLayers
{
	// Pagine a destra
	topRightPage = [CALayer layer];
	topRightPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	// Questo serve solo quando sono in verticale
	bottomRightPageContainer = [CALayer layer];
	
    topRightPageMask = [CAShapeLayer layer];
	
	topRightPageReverse = [CALayer layer];
	topRightPageReverse.backgroundColor = [[UIColor whiteColor] CGColor];
    
    topRightPageReverseContainer = [CALayer layer];
	
	topRightPageReverseShadow = [CAGradientLayer layer];
    
    topRightPageReverseMask = [CAShapeLayer layer];
	
	bottomRightPage = [CALayer layer];
	bottomRightPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	bottomRightPageShadow = [CAGradientLayer layer];
	
	//********************
	// Pagine a sinistra
	//********************
	topLeftPage = [CALayer layer];
	topLeftPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	topLeftPageMask = [CAShapeLayer layer];
	
	topLeftPageReverse = [CALayer layer];
	topLeftPageReverse.backgroundColor = [[UIColor whiteColor] CGColor];
	
	topLeftPageReverseContainer = [CALayer layer];
	
	topLeftPageReverseShadow = [CAGradientLayer layer];
	
	topLeftPageReverseMask = [CAShapeLayer layer];
	
	bottomLeftPage = [CALayer layer];
	bottomLeftPage.backgroundColor = [[UIColor whiteColor] CGColor];
	
	bottomLeftPageShadow = [CAGradientLayer layer];
	
	self.leafEdge = CGPointMake(1.0, 1.0);
}

// Posizionamento iniziale pagine, poi non viene richiamato dal ricalcolo che invece chiama redraw
// Dopo che ho girato una pagina viene richiamata per risistemare i layers
- (void) setLayerFrames
{		
	for(int k = 0 ; k < self.layer.sublayers.count ; k++)
	{
		CALayer *actual = [self.layer.sublayers objectAtIndex:k];
		[actual.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	}
	[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
	// Questa serve per far vedere i livelli dritti che altrimenti me li presenta a capa sotta
	CATransform3D invertY = CATransform3DMakeScale(1, -1, 1);
	
	// Traslazione assi context vista principale
	CATransform3D trasfo = CATransform3DMakeTranslation(pageWidth, 0, 0);
	trasfo = CATransform3DScale(trasfo, 1, -1, 1);
	self.layer.sublayerTransform = CATransform3DIdentity;
	self.layer.sublayerTransform = trasfo;
	
	// Pagine a destra
	topRightPage.frame = CGRectMake(self.layer.bounds.origin.x, 
									self.layer.bounds.origin.y,
									pageWidth,
									pageHeight);
	topRightPage.transform = invertY;
	topRightPage.backgroundColor = [[UIColor whiteColor] CGColor];
	topRightPage.mask = nil;
	
	topRightPageMask.frame = CGRectMake(self.layer.bounds.origin.x, 
                                        self.layer.bounds.origin.y,
                                        pageWidth,
                                        pageHeight);
	
	topRightPageReverse.frame = CGRectMake(pageWidth, 
										   self.layer.bounds.origin.y,
										   pageWidth, 
										   pageHeight);
	topRightPageReverse.transform = invertY;
	topRightPageReverse.anchorPoint = CGPointMake(0, 0);
	
    topRightPageReverseMask.frame = CGRectMake(self.layer.bounds.origin.x, 
                                               self.layer.bounds.origin.y,
                                               pageWidth,
                                               pageHeight);
	
	topRightPageReverseContainer.frame = CGRectMake(self.layer.bounds.origin.x, 
                                                    self.layer.bounds.origin.y,
                                                    pageWidth,
                                                    pageHeight);
	topRightPageReverseContainer.backgroundColor = [[UIColor clearColor] CGColor];
	
	
	bottomRightPage.frame = CGRectMake(self.layer.bounds.origin.x,
									   self.layer.bounds.origin.y,
									   pageWidth, 
									   pageHeight);
	bottomRightPage.transform = invertY;
	
	//*************************
	// Pagine a sinistra	
	//*************************/
	topLeftPage.frame = CGRectMake(-pageWidth, 
								   0,
								   pageWidth,
								   pageHeight);
	topLeftPage.transform = invertY;
	topLeftPage.backgroundColor = [[UIColor whiteColor] CGColor];
	topLeftPage.mask = nil;
	
	topLeftPageMask.frame = CGRectMake(0, 
									   0,
									   pageWidth,
									   pageHeight);
	
	topLeftPageReverse.frame = CGRectMake(-pageWidth,
										  0,
										  pageWidth,
										  pageHeight);
	
	topLeftPageReverseMask.frame = CGRectMake(0,
											  0,
											  pageWidth,
											  pageHeight);

	
	topLeftPageReverseContainer.frame = CGRectMake(-pageWidth,
												   0,
												   pageWidth,
												   pageHeight);
	
	bottomLeftPage.frame = CGRectMake(-pageWidth, 0, pageWidth, pageHeight);
	bottomLeftPage.transform = invertY;
	
	// Quadranti
    // 1 = Basso a destra
    quadrante1 = CGRectMake(0, 0, pageWidth, pageHeight / 2);
    // 2 = basso a sinistra
    quadrante2 = CGRectMake(-pageWidth, 0, pageWidth, pageHeight / 2);
    // 3 = angolo destro alto
    quadrante3 = CGRectMake(0, pageHeight / 2, pageWidth, pageHeight / 2);
    // 4 = angolo sinistro alto
    quadrante4 = CGRectMake(-pageWidth, pageHeight / 2, pageWidth, pageHeight / 2);
	
	//**************************************
	// Impilo i layers, il retro delle pagine va davanti poi si maschera
	// Inizio dalle pagine a sinistra
	//**************************************
	[self.layer addSublayer:bottomLeftPage];
	[self.layer addSublayer:topLeftPage];
	
	[self.layer addSublayer:bottomRightPage];
    [self.layer addSublayer:topRightPage];
    
    // Le pagine volanti vanno sempre davanti a tutto, altrimenti vengono coperte
	[topLeftPageReverseContainer addSublayer:topLeftPageReverse];
	[self.layer addSublayer:topLeftPageReverseContainer];
	
    [topRightPageReverseContainer addSublayer:topRightPageReverse];
	[self.layer addSublayer:topRightPageReverseContainer];
	
	[self resetShadowLayers];
//	[self setupDebugBullets];
}

// Imposta i livelli per la visualizzazione verticale
- (void) createLayersVertical
{
	currentPageLayer = [CALayer layer];
	currentPageLayer.backgroundColor = [[UIColor whiteColor] CGColor];
	currentPageMask = [CAShapeLayer layer];
	nextPageLayer = [CALayer layer];
	nextPageLayer.backgroundColor = [[UIColor whiteColor] CGColor];
	prevPageLayer = [CALayer layer];
	prevPageLayer.backgroundColor = [[UIColor whiteColor] CGColor];
	
	// Siccome ruota e mi ruoterebbe pure l'ombra devo metterla in un container
	farlokPageLayer = [CALayer layer];
	farlokPageLayer.backgroundColor = [[UIColor whiteColor] CGColor];
	farlokPageLayerContainer = [CALayer layer];
	farlokPageMask = [CAShapeLayer layer];
	
	currentPageShadow = [CAGradientLayer layer];
	farlokShadow = [CAGradientLayer layer];
}

- (void) setLayerFramesVertical
{
	// Servono quattro pagine:
	// La pagina corrente (mascherata) = topRightPage + topRightPageContainer
	// La pagina successiva = bottomRightPage
	// E' quella precedente = topLeftPage
	// E' la pagina farlocca col retro della pagina principale, è sempre quella che ruota (mascherata) = bottomLeftPage + topLeftPageReverseContainer
	
//	NSLog(@"in setLayerFramesVertical cura self.frame = %f  %f",self.frame.size.width, self.frame.size.height);
	
	// Rimuovo tutte le pagine
	[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
	// Rimuovo le pagine dai contenitori che devo riciclare, in uno ci metto la pagina di destra, nell'altro quello di sinistra (precedente - successiva)	
	// E li resetto che non si sa mai
	currentPageLayer.transform = CATransform3DIdentity;
	currentPageLayer.frame = self.layer.bounds; 
	currentPageMask.frame = self.layer.bounds;
	nextPageLayer.frame = self.layer.bounds;
	prevPageLayer.frame = self.layer.bounds;
	
	farlokPageLayer.frame = CGRectMake(pageWidth, 0, pageWidth, pageHeight);
	farlokPageLayerContainer.frame = self.layer.bounds;
	farlokPageMask.frame = self.layer.bounds;
	
	// Reimposto le coordinate del layer principale
	self.layer.sublayerTransform = CATransform3DIdentity;
	
	// Sistemo i quadranti : in questo sistema di riferimento l'origine è in alto a sinistra
    // 1 = Basso a destra
    quadrante1 = CGRectMake(pageWidth / 2, pageHeight / 2, pageWidth / 2, pageHeight / 2);
    // 2 = basso a sinistra
    quadrante2 = CGRectMake(0, pageHeight / 2, pageWidth / 2, pageHeight / 2);
    // 3 = angolo destro alto
    quadrante3 = CGRectMake(pageWidth / 2, 0, pageWidth, pageHeight / 2);
    // 4 = angolo sinistro alto
    quadrante4 = CGRectMake(0, 0, pageWidth, pageHeight / 2);
	
	
	// Impilo i livelli
	// precedente
	[self.layer addSublayer:prevPageLayer];
	
	// Successiva
	[self.layer addSublayer:nextPageLayer];
	
	// Corrente
	currentPageLayer.mask = nil;
	[self.layer addSublayer:currentPageLayer]; // Corrente
	
	// Pagina volante farlocca
	farlokPageLayerContainer.mask = nil;
	[farlokPageLayer removeFromSuperlayer];
	[farlokPageLayerContainer addSublayer:farlokPageLayer];
	[self.layer addSublayer:farlokPageLayerContainer];
	
	[self resetShadowLayers];
//	[self setupDebugBullets];
}

// Libera i livelli
-(void)freeLayers
{
	[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
	
	topRightPage = nil;
	bottomRightPageContainer = nil;
    topRightPageMask = nil;
	topRightPageReverse = nil;    
    topRightPageReverseContainer = nil;
	topRightPageReverseShadow = nil;
    topRightPageReverseMask = nil;
	bottomRightPage = nil;
	bottomRightPageShadow = nil;
	
	//********************
	// Pagine a sinistra
	//********************
	topLeftPage = nil;
	topLeftPageMask = nil;
	topLeftPageReverse = nil;
	topLeftPageReverseContainer = nil;
	topLeftPageReverseShadow = nil;
	topLeftPageReverseMask = nil;
	bottomLeftPage = nil;
	bottomLeftPageShadow = nil;
	
	//*********************
	//pagine verticali
	//*********************
	currentPageLayer = nil;
	currentPageMask = nil;
	prevPageLayer = nil;
	farlokPageLayer = nil;
	farlokPageMask = nil;
}


-(void) setupDebugBullets
{
	// Pallette di debug
	CATransform3D invertY;
	if(isLandscape)
	{
		invertY = CATransform3DMakeScale(1, -1, 1);
	}
	else
	{
		invertY = CATransform3DIdentity;
	}
	M = [CALayer layer];
	M.transform = invertY;
	M.frame = CGRectMake(0, 0, 20, 20);
	
	F = [CALayer layer];
	F.transform = invertY;
	F.frame = CGRectMake(0, 0, 20, 20);
	
    R1 = [CALayer layer];
	R1.transform = invertY;
    R1.frame = CGRectMake(fixedRadius, 0, 20, 20);
	
    R2 = [CALayer layer];
	R2.transform = invertY;
    R2.frame = CGRectMake(0, 0, 20, 20);
	
	T0 = [CALayer layer];
	T0.frame = CGRectMake(0, 0, 20, 20);
	T0.transform = invertY;
	
	T1 = [CALayer layer];
	T1.frame = CGRectMake(0, 0, 20, 20);
	T1.transform = invertY;
	
	T2 = [CALayer layer];
	T2.frame = CGRectMake(0, 0, 20, 20);
	T2.transform = invertY;
	
	T3 = [CALayer layer];
	T3.frame = CGRectMake(0, 0, 20, 20);
	T3.transform = invertY;
    
	M.contents = (id) [UIImage imageNamed:@"m.png"].CGImage;
	F.contents = (id) [UIImage imageNamed:@"f.png"].CGImage;
    R1.contents = (id) [UIImage imageNamed:@"r1.png"].CGImage;
    R2.contents = (id) [UIImage imageNamed:@"r2.png"].CGImage;
	T0.contents = (id) [UIImage imageNamed:@"t0.png"].CGImage;
	T1.contents = (id) [UIImage imageNamed:@"t1.png"].CGImage;
	T2.contents = (id) [UIImage imageNamed:@"t2.png"].CGImage;
	T3.contents = (id) [UIImage imageNamed:@"t3.png"].CGImage;
    
    [self.layer addSublayer:R1];
    [self.layer addSublayer:R2];
	[self.layer addSublayer:F];
	[self.layer addSublayer:M];
	[self.layer addSublayer:T0];
	[self.layer addSublayer:T1];
	[self.layer addSublayer:T2];
	[self.layer addSublayer:T3];

}

-(void) resetShadowLayers
{
//	NSLog(@"resetShadowLayers");
	topRightPageReverseShadow.transform = CATransform3DIdentity;
	topRightPageReverseShadow.frame = CGRectMake(pageWidth, 0, 40, pageHeight * 2);
	topRightPageReverseShadow.anchorPoint = CGPointMake(0,0);
	topRightPageReverseShadow.colors = [NSArray arrayWithObjects:
										(id)[[[UIColor whiteColor] colorWithAlphaComponent:0] CGColor],
										(id)[[[UIColor blackColor] colorWithAlphaComponent:0.5] CGColor],
										nil];
	topRightPageReverseShadow.startPoint = CGPointMake(0, 0);
	topRightPageReverseShadow.endPoint = CGPointMake(1, 0);
	
	bottomRightPageShadow.transform = CATransform3DIdentity;
	bottomRightPageShadow.frame = CGRectMake(0, 0, 40, pageHeight * 2);
	bottomRightPageShadow.anchorPoint = CGPointMake(0, 1);
	bottomRightPageShadow.colors = [NSArray arrayWithObjects:
									(id)[[[UIColor blackColor] colorWithAlphaComponent:0.5] CGColor],
									(id)[[[UIColor whiteColor] colorWithAlphaComponent:0] CGColor],
									nil];
	bottomRightPageShadow.startPoint = CGPointMake(0, 0);
	bottomRightPageShadow.endPoint = CGPointMake(1, 0);
	
	topLeftPageReverseShadow.transform = CATransform3DIdentity;
	topLeftPageReverseShadow.frame = CGRectMake(0, 0, 40, pageHeight * 2);
	topLeftPageReverseShadow.anchorPoint = CGPointMake(0, 0);
	topLeftPageReverseShadow.colors = [NSArray arrayWithObjects:
									   (id)[[[UIColor blackColor] colorWithAlphaComponent:0.6] CGColor],
									   (id)[[[UIColor whiteColor]colorWithAlphaComponent:0] CGColor],
									   nil];
	topLeftPageReverseShadow.startPoint = CGPointMake(0,0);
	topLeftPageReverseShadow.endPoint = CGPointMake(1,0);
	
	bottomLeftPageShadow.transform = CATransform3DIdentity;
	bottomLeftPageShadow.frame = CGRectMake(0, 0, 40, pageHeight * 2);
	bottomLeftPageShadow.anchorPoint = CGPointMake(1, 1);
	bottomLeftPageShadow.colors = [NSArray arrayWithObjects:
								   (id)[[[UIColor whiteColor] colorWithAlphaComponent:0] CGColor],
								   (id)[[[UIColor blackColor] colorWithAlphaComponent:0.5] CGColor],
								   nil];
	bottomLeftPageShadow.startPoint = CGPointMake(0,0);
	bottomLeftPageShadow.endPoint = CGPointMake(1,0);
	
	// Presuppongo di partire sempre con l'ombra in basso a destra
	currentPageShadow.transform = CATransform3DIdentity;
	currentPageShadow.frame = CGRectMake(0, 0, 40, pageHeight * 2);
	currentPageShadow.anchorPoint = CGPointMake(0, 1);
	currentPageShadow.colors = [NSArray arrayWithObjects:
								   (id)[[[UIColor blackColor] colorWithAlphaComponent:0.5] CGColor],
								   (id)[[[UIColor whiteColor] colorWithAlphaComponent:0] CGColor],
								   nil];
	currentPageShadow.startPoint = CGPointMake(0,0);
	currentPageShadow.endPoint = CGPointMake(1,0);
	
	farlokShadow.transform = CATransform3DIdentity;
	farlokShadow.frame = CGRectMake(0, 0, 40, pageHeight * 2);
	farlokShadow.anchorPoint = CGPointMake(1, 1);
	farlokShadow.colors = [NSArray arrayWithObjects:
								(id)[[[UIColor whiteColor] colorWithAlphaComponent:0] CGColor],
								(id)[[[UIColor blackColor] colorWithAlphaComponent:0.5] CGColor],
								nil];
	farlokShadow.startPoint = CGPointMake(0,0);
	farlokShadow.endPoint = CGPointMake(1,0);
}

-(void) setupInitValues
{	
	pageWidth = isLandscape ? self.frame.size.width / 2 : self.frame.size.width;
	pageHeight = self.frame.size.height;
	pageHalfHeight = pageHeight / 2;
	pageDiagonal = sqrt(pageWidth * pageWidth + pageHeight * pageHeight);
	
	bisectorTangent = 0;
	
	spineTop = CGPointMake(0, pageHeight);
	spineBottom = CGPointMake(0, 0);
	
	dx = 0;
    dy = 0;
    a2f = 0;
    fixedRadius = pageWidth;
	
	tangentBottom = CGPointMake(0, 0);
	
	mouse = CGPointMake(pageWidth,0);
	follow = CGPointMake(pageWidth,0);
	
	radius1 = CGPointMake(0, 0);
	radius2 = CGPointMake(0, 0);
	bisector = CGPointMake(0, 0);
	
	self.clipsToBounds = YES;
	
	goingToPage = NO;
}

- (void) initialize
{
	isFolding = NO;
	backgroundRendering = NO;
	autoTurn = NO;
}

- (id)initWithFrame:(CGRect)frame
{
    if ((self = [super initWithFrame:frame]))
	{
		[self createLayers];
		[self initialize];
    }
    return self;
}

- (void) awakeFromNib
{
	[super awakeFromNib];
}


- (void) reloadData
{
	[pageCache flush];
	numberOfPages = [pageCache numberOfPages];
	currentPageIndex = 0;
    
	[self freeLayers];
	if(isLandscape == YES)
	{
		[self createLayers];
	}
	else
	{
		[self createLayersVertical];
	}
}

- (void) getImages
{
	int intIndex = currentPageIndex;
	int intNumPages = numberOfPages;
	
	if(isLandscape)
	{
		// Sto zoomando devo prendere solo il contenuto delle dua pagine visibili altrimenti ci mette un mese
		if(isZooming == NO)
		{
			// Acchiappo le immagini per pagine doppie, al massimo sono 6 e la pagine corrente è sempre pari (base index 0) quando siamo in doppia pagina (0, 2, 4, ...)
			for(int k = intIndex - 3 ; k <= intIndex + 2 ; k++)
			{
				// Se la pagina è negativa o eccede il numero di pagine totale
				if(k < 0)
				{
					continue;
				}
				else if(k > intNumPages)
				{
					break;
				}
				
				[pageCache precacheImageForPageIndex:k];
			}
			
			bottomLeftPage.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex - 3];
			topLeftPageReverse.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex -2];
			topRightPageReverse.contents = (id) [pageCache cachedImageForPageIndex:currentPageIndex +1];
			bottomRightPage.contents = (id) [pageCache cachedImageForPageIndex:currentPageIndex +2];
			
			// Sinistra
			topLeftPage.contents = (id) [pageCache cachedImageForPageIndex:currentPageIndex -1];
			// Destra
			topRightPage.contents = (id) [pageCache cachedImageForPageIndex:currentPageIndex];
		}
		else
		{
			topLeftPage.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex - 1];
			topRightPage.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex];
		}
		
	}
	else
	{
		// Se sono in piedi carico solo tre pagine, tanto la pagina davanti non ha il retro
		// Sono la pagina corrente, corrente - 1 e corrente + 1
		for(int k = (intIndex - 1) ; k <= (intIndex + 2) ; k++)
		{
			// Se la pagina è negativa o eccede il numero di pagine totale
			if(k < 0)
			{
				continue;
			}
			else if(k > intNumPages)
			{
				break;
			}
			
			[pageCache precacheImageForPageIndex:k];
		}
		
		CIFilter *filter = [CIFilter filterWithName:@"CIColorMatrix"];
		CIImage *toProcess = [CIImage imageWithCGImage:[pageCache cachedImageForPageIndex:currentPageIndex]];
		[filter setDefaults];
		[filter setValue:toProcess forKey:kCIInputImageKey];
		[filter setValue:[CIVector vectorWithX:0 Y:0 Z:0 W:0.1f] forKey:@"inputAVector"]; // 8
		CIImage *displayImage = filter.outputImage;
		
		CIContext *context = [CIContext contextWithOptions:nil];
		
		UIImage *img = [UIImage imageWithCGImage:[context createCGImage:displayImage fromRect:displayImage.extent]];
		
		farlokPageLayer.contents = (id)img;
		currentPageLayer.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex];
		nextPageLayer.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex + 1];
		prevPageLayer.contents = (id)[pageCache cachedImageForPageIndex:currentPageIndex - 1];	
	}
	
	// Ottimizzo la cache 
	[pageCache minimizeToPageIndex:currentPageIndex vertical:!isLandscape];
}

- (void) getZoomImagesWithScale:(NSNumber *)theScale
{
	// Imposto la misura della cache
	pageCache.pageSize = CGSizeMake(pageWidth * [theScale floatValue], pageHeight * [theScale floatValue]);
	
	// Verticale e orizzontale
	if(isLandscape == NO)
	{
		UIImage* img = [pageCache imageForPageIndex:currentPageIndex];
		currentPageLayer.contents = (id)img.CGImage;
	}
	else
	{
		if(currentPageIndex > 0)
		{
			UIImage* leftImg = [pageCache imageForPageIndex:currentPageIndex - 1];
			topLeftPage.contents = (id) leftImg.CGImage;
		}
		
		UIImage *rightImage = [pageCache imageForPageIndex:currentPageIndex];
		topRightPage.contents = (id)rightImage.CGImage;
	}
	
	pageCache.pageSize = CGSizeMake(pageWidth, pageHeight);
}

#pragma mark Calcolo Tutto
//******************************
// Qui succede tutto il casino (solo per orientamento orizzontale, per il verticale tutt'altra storia, vedi sotto)
// NOTA: Siccome le CPU degli iPhone non supportano le divisioni tutte le divisioni per due sono diventate moltiplicazioni per 0.5f
//******************************
-(void) recalc
{
	// Se sono più vicini di .1 li armonizzo
	[self harmonizeFollower];
	
	// Se sono in alto o in basso la storia cambia (questi sono tutti una manica di imbecilli)
	basso = (startCorner == BASSO_DESTRA) || (startCorner == BASSO_SINISTRA);
	
    // Limito il follower altrimenti mi va in vacca il triangolo critico
    if(follow.y < FOLLOW_LIMIT)
    {
        follow.y = FOLLOW_LIMIT;
    }
	else if(follow.y > pageHeight - FOLLOW_LIMIT)
	{
		follow.y  = pageHeight - FOLLOW_LIMIT;
	}
	
	// Coordinate tra il punto più basso della costa del libro e il segui mouse
	if(basso)
	{
		dx = follow.x;
		dy = follow.y;
	}
	else
	{
		dx = follow.x;
		dy = pageHeight - follow.y;
	}
	
	// angolo tra il punto più basso della costa del libro e il segui mouse
	a2f = atan2(dy, dx);
	
	// Coordinate di R1
	radius1.x = cos(a2f) * fixedRadius;
	radius1.y = sin(a2f) * fixedRadius;
	
	float distToFollow1 = 0;
	float distToRadius1 = 0;
	if(basso == NO)
	{
		radius1.y = pageHeight - radius1.y;
		
		// Vincolo di distanza per rotazione in alto
		distToFollow1 = sqrt(pow(spineTop.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow1 = ceil(distToFollow1);
		distToRadius1 = sqrt(pow(spineTop.y - radius1.y, 2) + pow(radius1.x * radius1.x, 2));
		distToRadius1 = ceil(distToRadius1);
	}
	else
	{
		// Vincolo di distanza per rotazione in basso
		distToFollow1 = sqrt(pow(spineBottom.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow1 = ceil(distToFollow1);
		distToRadius1 = sqrt(pow(spineBottom.y - radius1.y, 2) + pow(radius1.x * radius1.x, 2));
		distToRadius1 = ceil(distToRadius1);
	}
	
	if(distToFollow1 > distToRadius1)
	{
		follow.x = radius1.x;
		follow.y = radius1.y;
	}
	
	// Calcolo R2, l'angolo da seguire è quello tra il top della costa a il segui mouse
	// Il top della costa si trova a coordinate (0, pageHeight)
	dx = follow.x;
	dy = spineTop.y - follow.y;
	
	// Angolo
	a2f = atan2(dy, dx);
	////console.log("a2f per R2 = "+a2f);
	
	radius2.x = round((pageDiagonal * cos(a2f)));
	radius2.y = -(pageDiagonal * sin(a2f)- pageHeight);
	
	float distToFollow2 = 0;
	float distToRadius2 = 0;
	if(basso == NO)
	{
		radius2.y = pageHeight - radius2.y;
		
		distToFollow2 = sqrt(pow(spineBottom.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow2 = ceil(distToFollow2);
		distToRadius2 = sqrt(pow(spineBottom.y - radius2.y, 2) + pow(radius2.x * radius2.x, 2));
		distToRadius2 = ceil(distToRadius2);
	}
	else
	{
		distToFollow2 = sqrt(pow(spineTop.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow2 = ceil(distToFollow2);
		distToRadius2 = sqrt(pow(spineTop.y - radius2.y, 2) + pow(radius2.x * radius2.x, 2));
		distToRadius2 = ceil(distToRadius2);
	}
	
	if(distToFollow2 > distToRadius2)
	{
		follow.x = radius2.x;
		follow.y = radius2.y;
	}
	
	// Calcolo la bisettrice T1 tra F e EB
	bisector.x = (follow.x + pageWidth) / 2;
	if(bisector.x == NAN)
	{
		NSLog(@"bisector 1 : follow.x = %f  pageWidth = %f  result = %f",follow.x,pageWidth,(follow.x + pageWidth) / 2);
	}
	
	if(basso == NO)
	{
		bisector.y = (pageHeight  * 0.5f) + (follow.y * 0.5f);
	}
	else
	{
		bisector.y = follow.y * 0.5f;
	}
	
	BOOL invertX = NO;
	if(startCorner % 2 == 0)
	{
		bisector.x = -(pageWidth - bisector.x);
		invertX = YES;
	}
	
	// Calcolo la bisettrice e determino il triangolo critico
	float bisectorAngle = 0;
	if(basso == YES)
	{
		bisectorAngle = invertX ? -atan2(bisector.y, pageWidth + bisector.x) : atan2(bisector.y, pageWidth - bisector.x);
		bisectorTangent = bisector.x - tan(bisectorAngle) * bisector.y;
	}
	else
	{
		bisectorAngle = invertX ? -atan2(pageHeight - bisector.y, pageWidth + bisector.x) : atan2(pageHeight - bisector.y, pageWidth - bisector.x);
		bisectorTangent = bisector.x - tan(bisectorAngle) * (pageHeight - bisector.y);
	}
	
	//NSLog(@"bisector.x = % f bisector.y = %f bisectorAngle = %f",bisector.x, bisector.y, bisectorAngle);
	
	
	tangentBottom.x = bisectorTangent;
	tangentBottom.y = (basso == YES ? 0 : pageHeight);
	
	// il punto zero dell'angolo della pagina è il follower, mi nanca solo l'angolo di rotazione
	// Che è quello del vettore T2	F
	dx = follow.x - tangentBottom.x;
	dy = follow.y;
	// Trusco per l'angolo in basso a destra
	if(tangentBottom.x == pageWidth)
	{
		pageAngle = gradiToRad(-90);
	}
	else
	{	
		if(basso == YES)
		{
			pageAngle = atan2(tangentBottom.y - follow.y, tangentBottom.x - follow.x);
		}
		else
		{
			//NSLog(@"tangentBottom.x = %f tangentBottom.y = %f follow.x = %f follow.y = %f", tangentBottom.x, tangentBottom.y, follow.x, follow.y);
			pageAngle =  atan2(pageHeight - follow.y, tangentBottom.x - follow.x);;
		}
	}
	
	pageAngle = invertX ? pageAngle - M_PI : pageAngle;
	pageAngle = -pageAngle;
	
//	NSLog(@"page angle = %f", pageAngle);
	 
    // Dall'angolo della maschera, avendo la distanza T2 - EB calcolo l'altro cateto del triangolo dove va T3
    float triAngle = 0;
	if(basso == YES)
	{
		triAngle = atan2(bisector.y, bisector.x - tangentBottom.x);
	}
	else
	{
		triAngle = atan2(pageHeight - bisector.y, bisector.x - tangentBottom.x);
	}
//	NSLog(@"bisector.x = %f bisector.y = %f tangentBottom.x = %f triAngle = %f", bisector.x, bisector.y, tangentBottom.x, triAngle);
	triAngle = invertX ? M_PI - triAngle : triAngle;
	if(invertX)
	{
		T3Point = CGPointMake(-pageWidth, (pageWidth + tangentBottom.x) * tan(triAngle));
	}
	else
	{
		T3Point = CGPointMake(pageWidth, (pageWidth - tangentBottom.x) * tan(triAngle));
	}
	
	if(basso == NO)
	{
		T3Point.y = pageHeight - T3Point.y;
	}
	
//	NSLog(@"T3Point.x = %f T3Point.y = %f", T3Point.x, T3Point.y);
	
	// Angolo dell'ombra
//	NSLog(@"bisector.x = %f bisector.y = %f tangentBottom.x = %f tangentBottom.y = %f",bisector.x, bisector.y,tangentBottom.x, tangentBottom.y);
	CGPoint shPoint = CGPointMake(bisector.x - tangentBottom.x, bisector.y - tangentBottom.y);
	shadowAngle = atan2(shPoint.x, shPoint.y);
	
	// Trusco altrimenti non funge l'angolo in alto a sinisttra
	if(startCorner == ALTO_SINISTRA)
	{
		shadowAngle = -(M_PI - shadowAngle);
	}
	
	// Controlo se ho finito di piegare
    // Se abbiamo finito la piega stoppo il timer
	BOOL complete = NO;
	BOOL girato = NO;
    if((foldingTimer != nil) || (isFolding == YES))
    {
		complete = (follow.y <= FOLLOW_LIMIT) || (follow.y  >= (pageHeight - FOLLOW_LIMIT));
        complete &= (fabs(follow.x) >= pageWidth - 3);
        
        if(complete)
        {
            [foldingTimer invalidate];
            foldingTimer = nil;
						
			// Controllo se sono andato avanti o indietro
			if(startCorner % 2 != 0)
			{
				// Sono partito da destra
				if (endCorner % 2 == 0)
				{
					// Ho girato la pagina, se endCorner % 2 != 0
					// ho fatto una finta e non sistemo nulla
					if(autoTurn == NO)
						currentPageIndex += 2;
					girato = YES;
				}
			}
			else
			{
				// Sono partito da sinistra, come sopra
				if(endCorner % 2 != 0)
				{
					if(autoTurn == NO)
						currentPageIndex -= 2; 
					girato = YES;
				}
			}
        }
    }

    
	if(complete == YES)
	{
		// Rimetto a posto le pagine
		[CATransaction begin];
		[CATransaction setDisableActions:YES];
		
		// Via anche le ombre
		[bottomRightPageShadow removeFromSuperlayer];
		[topRightPageReverseShadow removeFromSuperlayer];
		[bottomLeftPageShadow removeFromSuperlayer];
		[topLeftPageReverseShadow removeFromSuperlayer];
		
		// Sistemazione livelli e riacchiappamento immagini
		if(girato)
		{
			[self setLayerFrames];
			[self getImages];
		}
		
		[CATransaction commit];
		
		isFolding = NO;
		autoTurn = NO;
		[myController pageHasTurned];
	}
	else
	{
		[self redraw];
//		NSLog(@"Stikrazzi");
	}
}

#pragma mark ricalcolo verticale
//*************************************
// Dopo avere fatto a schiaffoni col codice (e averle prese) per adattare il modello di calcolo orizzontale alle pagine singole
// ho deciso che scrivevo un altro metodo e boom alek
//*************************************
-(void) recalcVertical
{
//	NSLog(@"recalcVertical");
	// Se sono più vicini di .1 li armonizzo
	[self harmonizeFollower];
	
    // Limito il follower altrimenti mi va in vacca il triangolo critico
    if(follow.y < FOLLOW_LIMIT)
    {
        follow.y = FOLLOW_LIMIT;
    }
	else if(follow.y > pageHeight - FOLLOW_LIMIT)
	{
		follow.y  = pageHeight - FOLLOW_LIMIT;
	}
	
	// Se sono in alto o in basso la storia cambia (questi sono tutti una manica di imbecilli)
	basso = (startCorner == BASSO_DESTRA) || (startCorner == BASSO_SINISTRA);
	basso = !basso;

	// Coordinate tra il punto più basso della costa del libro e il segui mouse
	// Qui lo faccio per ogni angolo della pagina
	// sono tutti diversi
	switch (startCorner)
	{
		case ALTO_DESTRA:
			dx = follow.x;
			dy = follow.y;
			a2f = atan2(dy, dx);
			// Coordinate di R1
			radius1.x = cos(a2f) * fixedRadius;
			radius1.y = sin(a2f) * fixedRadius;
			break;
		case ALTO_SINISTRA:
			dx = pageWidth - follow.x;
			dy = follow.y;
			a2f = atan2(dy, dx);
			// Coordinate di R1
			radius1.x = pageWidth - cos(a2f) * fixedRadius;
			radius1.y = sin(a2f) * fixedRadius;
			break;
		case BASSO_DESTRA:
			dx = follow.x;
			dy = pageHeight - follow.y;
			a2f = atan2(dy, dx);
			// Coordinate di R1
			radius1.x = cos(a2f) * fixedRadius;
			radius1.y = pageHeight - sin(a2f) * fixedRadius;
			break;
		case BASSO_SINISTRA:
			dx = pageWidth - follow.x;
			dy = pageHeight - follow.y;
			a2f = atan2(dy, dx);
			// Coordinate di R1
			radius1.x = pageWidth - cos(a2f) * fixedRadius;
			radius1.y = pageHeight - sin(a2f) * fixedRadius;
			break;
	}
	
//	NSLog(@"follow.x = %f follow.y = %f dx = %f dy = %f a2f = %f radius1.x = %f radius1.y = %f",follow.x, follow.y, dx,dy, a2f, radius1.x, radius1.y);
	
	float distToFollow1 = 0;
	float distToRadius1 = 0;
	if(basso == YES)
	{
		// Vincolo di distanza per rotazione in alto
		distToFollow1 = sqrt(pow(spineTop.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow1 = ceil(distToFollow1);
		distToRadius1 = sqrt(pow(spineTop.y - radius1.y, 2) + pow(radius1.x * radius1.x, 2));
		distToRadius1 = ceil(distToRadius1);
	}
	else
	{
		// Vincolo di distanza per rotazione in basso
		distToFollow1 = sqrt(pow(spineBottom.y - follow.y,2)+ pow(follow.x * follow.x, 2));
		distToFollow1 = ceil(distToFollow1);
		distToRadius1 = sqrt(pow(spineBottom.y - radius1.y, 2) + pow(radius1.x * radius1.x, 2));
		distToRadius1 = ceil(distToRadius1);
	}
	
	// Adesso faccio un trusco altrimenti F va dove gli pare
	if((startCorner == BASSO_SINISTRA) || (startCorner == ALTO_SINISTRA))
	{
		if(distToFollow1 < distToRadius1)
		{
			follow.x = radius1.x;
			follow.y = radius1.y;
		}
	}
	else
	{
		if(distToFollow1 > distToRadius1)
		{
			follow.x = radius1.x;
			follow.y = radius1.y;
		}
	}
	
	// Calcolo il punto medio T2 tra F e EB
	// bisector è T0
	// T2 è il punto medio tra l'angolo della pagina e F.x
	// Calcolo la bisettrice e determino il triangolo critico
	float bisectorAngle = 0;
	switch (startCorner)
	{
		case BASSO_DESTRA:
		{
			bisector.x = (follow.x + pageWidth) * 0.5f;
			bisector.y = (pageHeight  * 0.5f) + (follow.y * 0.5f);
			bisectorAngle = atan2(pageHeight - bisector.y, pageWidth - bisector.x);
			bisectorTangent = bisector.x - tan(bisectorAngle) * (pageHeight - bisector.y);
			break;
		}
		case BASSO_SINISTRA:
		{
			bisector.x = follow.x * 0.5f;
			bisector.y = (pageHeight + follow.y) * 0.5f;
			bisectorAngle = atan2(pageHeight - bisector.y, bisector.x);
			bisectorTangent = bisector.x - tan(-bisectorAngle) * (pageHeight - bisector.y);
			break;
		}
		case ALTO_DESTRA:
		{
			bisector.x = (follow.x + pageWidth) * 0.5f;
			bisector.y = follow.y * 0.5;
			bisectorAngle = atan2(bisector.y, pageWidth - bisector.x);
			bisectorTangent = bisector.x - tan(bisectorAngle) * bisector.y;
			break;
		}
		case ALTO_SINISTRA:
		{
			bisector.x = follow.x * 0.5f;
			bisector.y = follow.y * 0.5f;
			bisectorAngle = atan2(bisector.y, bisector.x);
			bisectorTangent = bisector.x - tan(-bisectorAngle) * bisector.y;
			break;
		}
		default:
			break;
	}

//	NSLog(@"bisectorAngle =  %f", bisectorAngle);
	
	tangentBottom.x = bisectorTangent;
	tangentBottom.y = (basso == YES ? 0 : pageHeight);
	
	// il punto zero dell'angolo della pagina è il follower, mi nanca solo l'angolo di rotazione
	// Che è quello del vettore T1	F
	// Trusco per l'angolo in basso a destra
	if(basso == YES)
	{
		pageAngle = atan2(tangentBottom.y - follow.y, tangentBottom.x - follow.x);
	}
	else
	{
		//NSLog(@"tangentBottom.x = %f tangentBottom.y = %f follow.x = %f follow.y = %f", tangentBottom.x, tangentBottom.y, follow.x, follow.y);
		pageAngle =  atan2(pageHeight - follow.y, tangentBottom.x - follow.x);;
	}
	
	if((startCorner ==  BASSO_SINISTRA) || (startCorner == ALTO_SINISTRA))
	{
		pageAngle = pageAngle - M_PI;
	}

//	NSLog(@"page angle = %f", pageAngle);
	
    // Dall'angolo della maschera, avendo la distanza T2 - EB calcolo l'altro cateto del triangolo dove va T3
    float triAngle = 0;
	if(basso == YES)
	{
		triAngle = atan2(bisector.y, bisector.x - tangentBottom.x);
	}
	else
	{
		triAngle = atan2(pageHeight - bisector.y, bisector.x - tangentBottom.x);
	}
	
	//	NSLog(@"bisector.x = %f bisector.y = %f tangentBottom.x = %f triAngle = %f", bisector.x, bisector.y, tangentBottom.x, triAngle);
	if((startCorner ==  BASSO_SINISTRA) || (startCorner == ALTO_SINISTRA))
	{
		triAngle = M_PI - triAngle;
		T3Point = CGPointMake(0, tangentBottom.x * tan(triAngle));
	}
	else
	{
		T3Point = CGPointMake(pageWidth, (pageWidth - tangentBottom.x) * tan(triAngle));
	}
	
	if(basso == NO)
	{
		T3Point.y = pageHeight - T3Point.y;
	}

	// Angolo dell'ombra
	CGPoint shPoint = CGPointMake(bisector.x - tangentBottom.x, bisector.y - tangentBottom.y);
	shadowAngle = atan2(shPoint.y, shPoint.x);
	
	// Controlo se ho finito di piegare
    // Se abbiamo finito la piega stoppo il timer
	BOOL complete = NO;
	BOOL girato = NO;
    if((foldingTimer != nil) || (isFolding == YES))
    {
		complete = ((int)follow.y == (int)FOLLOW_LIMIT) || (follow.y  == (int)pageHeight - FOLLOW_LIMIT);
        complete &= (fabs(follow.x) >= (float)pageWidth - 3);

        if(complete)
        {
            [foldingTimer invalidate];
            foldingTimer = nil;
			
			// Controllo se sono andato avanti o indietro
			if(startCorner % 2 != 0)
			{
				// Sono partito da destra
				if (endCorner % 2 == 0)
				{
					// Ho girato la pagina, se endCorner % 2 != 0
					// ho fatto una finta e non sistemo nulla
					if(autoTurn == NO)
					{
//						NSLog(@"Incremento pagina di 1");
						currentPageIndex += 1;
					}
					girato = YES;
				}
			}
			else
			{
				// Sono partito da sinistra, come sopra
				if(endCorner % 2 != 0)
				{
					if(autoTurn == NO)
					{
//						NSLog(@"decremento pagina di 1");
						currentPageIndex -= 1;
					}
						
					girato = YES;
				}
			}
        }
    }
    
	if(complete == YES)
	{
		// Rimetto a posto le pagine
		[CATransaction begin];
		[CATransaction setDisableActions:YES];

		// Sistemazione livelli e riacchiappamento immagini
		// Sistemazione livelli e riacchiappamento immagini
		if(girato)
		{
			[self setLayerFramesVertical];
			[self getImages];
		}
		
		currentPageLayer.mask = nil;
		currentPageLayer.frame = CGRectMake(0, 0, currentPageLayer.frame.size.width, currentPageLayer.frame.size.height);
		farlokPageLayer.mask = nil;
		
		// Via anche le ombre
		[farlokShadow removeFromSuperlayer];
		[currentPageShadow removeFromSuperlayer];
		
		[CATransaction commit];
		
		[myController pageHasTurned];
		isFolding = NO;
		autoTurn = NO;
	}
	else
	{
//		NSLog(@"invoco redrawVertical");
		[self redrawVertical];
	}
}

#pragma mark disegno orizzontale
-(void) redraw
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES]; // Questa roba serve per far andare i path e le pagine all'unisono
	switch (startCorner)
	{
		case BASSO_DESTRA:
		case ALTO_DESTRA:
			[self drawRightFlyngPage];
			[self drawRightFlyngMask];
			[self drawRightShadow];
			break;
		case BASSO_SINISTRA:
		case ALTO_SINISTRA:
			[self drawLeftFlyngPage];
			[self drawLeftFlyngMask];
			[self drawLeftShadow];
			break;
	}
	
//    [self drawBullets];
    [CATransaction commit];
}

// ***************************************************
//	disegno pagine
// ***************************************************
-(void) drawRightFlyngPage
{
	topRightPageReverse.position = CGPointMake(follow.x, (follow.y < 0 ? 0 : follow.y));
	topRightPageReverse.transform = CATransform3DIdentity;
	topRightPageReverse.transform =  CATransform3DScale(topRightPageReverse.transform, 1, -1, 1);
	topRightPageReverse.transform = CATransform3DRotate(topRightPageReverse.transform, pageAngle, 0, 0, 1);
}

-(void) drawRightFlyngMask
{
    // Maschera per la pagina volante
    // E un triangolo
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, tangentBottom.x, tangentBottom.y);
    CGPathAddLineToPoint(path, nil, follow.x, follow.y);
    CGPathAddLineToPoint(path, nil, pageWidth, T3Point.y);
    CGPathCloseSubpath(path);
	
	topRightPageReverseMask.path =  path;
    
    // Adesso quella per la pagina davanti, è inversa a quella della pagina volante
    // Quindi è un pentagono irregolare
    CGMutablePathRef path2 = CGPathCreateMutable();
	
	if(basso == YES)
	{
		// parto sempre da tangentBottom (T2)
		CGPathMoveToPoint(path2, nil, tangentBottom.x, pageHeight);
		CGPathAddLineToPoint(path2, nil, T3Point.x, pageHeight - T3Point.y);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathAddLineToPoint(path2, nil, 0, 0);
		CGPathAddLineToPoint(path2, nil, 0, pageHeight);
		CGPathCloseSubpath(path2);
	}
	else
	{
		CGPathMoveToPoint(path2, nil, tangentBottom.x, 0);
		CGPathAddLineToPoint(path2, nil, T3Point.x, pageHeight - T3Point.y);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, 0, pageHeight);
		CGPathAddLineToPoint(path2, nil, 0, 0);
		CGPathCloseSubpath(path2);
	}
	
	topRightPageMask.path = path2;
    
    // applico la maschera
    topRightPage.mask = topRightPageMask;
	topRightPageReverseContainer.mask = topRightPageReverseMask;
}

-(void) drawRightShadow
{
	topRightPageReverseShadow.position = CGPointMake(tangentBottom.x - 40, (basso == YES ? 0 : pageHeight));
	topRightPageReverseShadow.transform = CATransform3DMakeRotation(-shadowAngle, 0, 0, 1);
	
	bottomRightPageShadow.position = CGPointMake(tangentBottom.x, (basso == YES ? pageHeight : 0));//CGPointMake(tangentBottom.x , pageHeight);
	bottomRightPageShadow.transform = CATransform3DMakeRotation(shadowAngle, 0, 0, 1);
}

-(void) drawLeftFlyngPage
{
	// devo trasformare le coordinate nello spazio del container altrimenti fa il cazzo che gli pare
	CGPoint appoPoint = CGPointMake((self.bounds.size.width / 2 + follow.x), (follow.y));
	topLeftPageReverse.position = CGPointMake(appoPoint.x, appoPoint.y);
	topLeftPageReverse.transform =  CATransform3DMakeScale(1, -1, 1);
	topLeftPageReverse.transform = CATransform3DRotate(topLeftPageReverse.transform, pageAngle, 0, 0, 1);
}

-(void) drawLeftFlyngMask
{
    // Maschera per la pagina volante
    // E un triangolo
	CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, pageWidth + tangentBottom.x, tangentBottom.y);
    CGPathAddLineToPoint(path, nil, pageWidth + follow.x, follow.y);
    CGPathAddLineToPoint(path, nil, pageWidth + T3Point.x, T3Point.y);
    CGPathCloseSubpath(path);
	
	topLeftPageReverseMask.path = path;
    
    // Adesso quella per la pagina davanti, è inversa a quella della pagina volante
    // Quindi è un pentagono irregolare
    CGMutablePathRef path2 = CGPathCreateMutable();
	if(basso == YES)
	{
		// parto sempre da tangentBottom (T2)

		CGPathMoveToPoint(path2, nil, pageWidth + tangentBottom.x, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth + T3Point.x, pageHeight - T3Point.y);
		CGPathAddLineToPoint(path2, nil, 0, 0);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathCloseSubpath(path2);
	}
	else
	{
		CGPathMoveToPoint(path2, nil, pageWidth + tangentBottom.x, 0);
		CGPathAddLineToPoint(path2, nil, pageWidth + T3Point.x, pageHeight - T3Point.y);
		CGPathAddLineToPoint(path2, nil, 0, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathCloseSubpath(path2);
	}
	
	topLeftPageMask.path = path2;
    
    // applico la maschera
    topLeftPage.mask = topLeftPageMask;
	topLeftPageReverseContainer.mask = topLeftPageReverseMask;
}

-(void) drawLeftShadow
{
	topLeftPageReverseShadow.position = CGPointMake(pageWidth + tangentBottom.x, (basso == YES ? 0 : pageHeight));//CGPointMake(250, 250);
	topLeftPageReverseShadow.transform = CATransform3DMakeRotation(-shadowAngle, 0, 0, 1);
	
	bottomLeftPageShadow.position = CGPointMake(pageWidth + tangentBottom.x, (startCorner == ALTO_SINISTRA ? 0 : pageHeight));//CGPointMake(pageWidth + tangentBottom.x, pageHeight);//CGPointMake(100,0);
	bottomLeftPageShadow.transform = CATransform3DMakeRotation(shadowAngle, 0, 0, 1);
}

#pragma mark disegno verticale
-(void) redrawVertical
{
    [CATransaction begin];
    [CATransaction setDisableActions:YES]; // Questa roba serve per far andare i path e le pagine all'unisono
	switch (startCorner)
	{
		case BASSO_DESTRA:
		case ALTO_DESTRA:
			[self drawRightFlyngPageVert];
			[self drawRightFlyngMaskVert];
			[self drawRightShadowVertical];
			break;
		case BASSO_SINISTRA:
		case ALTO_SINISTRA:
			[self drawLeftFlyngPageVert];
			[self drawLeftFlyngMaskVertical];
			[self drawLeftShadowVertical];
			break;
	}
	
//    [self drawBullets];
    [CATransaction commit];
}

-(void)drawRightFlyngPageVert
{
	farlokPageLayer.position = CGPointMake(follow.x, (follow.y < 0 ? 0 : follow.y));
	farlokPageLayer.transform = CATransform3DIdentity;
	farlokPageLayer.transform = CATransform3DRotate(farlokPageLayer.transform, pageAngle, 0, 0, 1);
}

-(void)drawRightFlyngMaskVert
{
	// Maschera per la pagina volante
	// è un triangolo
    CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, tangentBottom.x, tangentBottom.y);
    CGPathAddLineToPoint(path, nil, T3Point.x, T3Point.y);
    CGPathAddLineToPoint(path, nil, follow.x, follow.y);
    CGPathCloseSubpath(path);
	
	farlokPageMask.path =  path;
    
    // Adesso quella per la pagina volante
    // Quindi è un pentagono irregolare
    CGMutablePathRef path2 = CGPathCreateMutable();
	
	// Ricordarsi che alto e basso qui sono invertiti
	if(basso == YES)
	{
		// parto sempre da tangentBottom (T2)
		CGPathMoveToPoint(path2, nil, tangentBottom.x, tangentBottom.y);
		CGPathAddLineToPoint(path2, nil, -pageWidth, 0);
		CGPathAddLineToPoint(path2, nil, -pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, T3Point.x, T3Point.y);
		CGPathCloseSubpath(path2);
	}
	else
	{
		CGPathMoveToPoint(path2, nil, tangentBottom.x, tangentBottom.y);
		CGPathAddLineToPoint(path2, nil, T3Point.x, T3Point.y);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathAddLineToPoint(path2, nil, 0, 0);
		CGPathAddLineToPoint(path2, nil, 0, pageHeight);
		CGPathCloseSubpath(path2);
	}
	
	currentPageMask.path = path2;
    
    // applico la maschera
    farlokPageLayerContainer.mask = farlokPageMask;
	currentPageLayer.mask = currentPageMask;
}

-(void) drawRightShadowVertical
{
	float angle = 0;
	if (startCorner == BASSO_DESTRA)
	{
		angle = M_PI_2 + shadowAngle;
	}
	else if(startCorner == ALTO_DESTRA)
	{
		angle = -(M_PI_2 - shadowAngle);
	}
	
	farlokShadow.position = CGPointMake(tangentBottom.x, (basso == YES ? 0 : pageHeight));
	farlokShadow.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
	
	currentPageShadow.position = CGPointMake(tangentBottom.x, tangentBottom.y);
	currentPageShadow.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
}

-(void)drawLeftFlyngPageVert
{
	farlokPageLayer.position = CGPointMake(follow.x, (follow.y < 0 ? 0 : follow.y));
	farlokPageLayer.transform = CATransform3DIdentity;
	farlokPageLayer.transform = CATransform3DRotate(farlokPageLayer.transform, pageAngle, 0, 0, 1);
}

-(void) drawLeftFlyngMaskVertical
{
    // Maschera per la pagina volante
    // E un triangolo
	CGMutablePathRef path = CGPathCreateMutable();
    CGPathMoveToPoint(path, nil, tangentBottom.x, tangentBottom.y);
    CGPathAddLineToPoint(path, nil, follow.x, follow.y);
    CGPathAddLineToPoint(path, nil, T3Point.x, T3Point.y);
    CGPathCloseSubpath(path);
	
	farlokPageMask.path = path;
    
    // Adesso quella per la pagina davanti, è inversa a quella della pagina volante
    // Quindi è un pentagono irregolare
    CGMutablePathRef path2 = CGPathCreateMutable();
	if(basso == YES)
	{
		// parto sempre da tangentBottom (T2)
		CGPathMoveToPoint(path2, nil, tangentBottom.x, tangentBottom.y);
		CGPathAddLineToPoint(path2, nil, T3Point.x, T3Point.y);
		CGPathAddLineToPoint(path2, nil, 0, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathCloseSubpath(path2);
	}
	else
	{
		CGPathMoveToPoint(path2, nil, tangentBottom.x, tangentBottom.y);
		CGPathAddLineToPoint(path2, nil, pageWidth, pageHeight);
		CGPathAddLineToPoint(path2, nil, pageWidth, 0);
		CGPathAddLineToPoint(path2, nil, 0, 0);
		CGPathAddLineToPoint(path2, nil, T3Point.x, T3Point.y);
		CGPathCloseSubpath(path2);
	}
	
	currentPageMask.path = path2;
    
    // applico la maschera
    farlokPageLayerContainer.mask = farlokPageMask;
	currentPageLayer.mask = currentPageMask;
}

-(void) drawLeftShadowVertical
{
	float angle = 0;
	if (startCorner == BASSO_SINISTRA)
	{
		angle = M_PI_2 + shadowAngle;
	}
	else if(startCorner == ALTO_SINISTRA)
	{
		angle = -(M_PI_2 - shadowAngle);
	}
	
	farlokShadow.position = CGPointMake(tangentBottom.x, (basso == YES ? 0 : pageHeight));
	farlokShadow.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
	
	currentPageShadow.position = CGPointMake(tangentBottom.x, tangentBottom.y);
	currentPageShadow.transform = CATransform3DMakeRotation(angle, 0, 0, 1);
}

#pragma mark disegno pallette
-(void) drawBullets
{	
	F.position = follow;
    R1.position = CGPointMake(radius1.x, radius1.y);
    R2.position = radius2;
	
	T0.position = bisector;
	T1.position = tangentBottom;
	T2.position = CGPointMake(bisector.x, basso == YES ? 0 : pageHeight);
	T3.position = T3Point;
}


//- (void)drawRect:(CGRect)rect
//{
//    CGContextRef myContext = UIGraphicsGetCurrentContext();
//
//    CGContextSetRGBFillColor (myContext, 0, 1, 0, 1);
//    CGContextFillRect (myContext, quadrante4);// 4
//}

#pragma mark risponditori
-(BOOL) handleTouchBegan:(CGPoint)touchBeganPoint
{
//	NSLog(@"handleTouchBegan");
	if(isLandscape)
	{
		touchBeganPoint = CGPointMake(touchBeganPoint.x - self.frame.size.width / 2, self.frame.size.height - touchBeganPoint.y);
        
        // Controllo in quale quadrante il tocco è stato effettuato
        if(CGRectContainsPoint(quadrante1, touchBeganPoint))
        {
			// Se sono all'ultima pagina non giro un cazzo
			if(currentPageIndex >= numberOfPages - 1)
			{
				return NO;
			}
            startCorner = BASSO_DESTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			bottomRightPageShadow.startPoint = CGPointMake(0, 0);
			bottomRightPageShadow.endPoint = CGPointMake(1, 0);
			
			topRightPageReverseShadow.startPoint = CGPointMake(0, 0);
			topRightPageReverseShadow.endPoint = CGPointMake(1, 0);
			
			[bottomRightPage addSublayer:bottomRightPageShadow];
			[topRightPageReverseContainer addSublayer:topRightPageReverseShadow];
			
			topRightPageReverse.anchorPoint = CGPointMake(0, 1);
			
			[CATransaction commit];
			
        }
        else if(CGRectContainsPoint(quadrante2, touchBeganPoint))
        {
			// Stessa cosa se sono all'ultima e il tipo vuole girare ancora e me le fa girare
			if(currentPageIndex == 0)
			{
				return NO;
			}
            startCorner = BASSO_SINISTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			[bottomLeftPage addSublayer:bottomLeftPageShadow];
			[topLeftPageReverseContainer addSublayer:topLeftPageReverseShadow];
			
			topLeftPageReverse.anchorPoint = CGPointMake(1, 1);
			bottomLeftPageShadow.anchorPoint = CGPointMake(1, 1);
			
			[CATransaction commit];
        }
        else if(CGRectContainsPoint(quadrante3, touchBeganPoint))
        {
			if(currentPageIndex >= numberOfPages - 1)
			{
				return NO;
			}
			startCorner = ALTO_DESTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			bottomRightPageShadow.startPoint = CGPointMake(1, 0);
			bottomRightPageShadow.endPoint = CGPointMake(0, 0);
			
			topRightPageReverseShadow.startPoint = CGPointMake(1, 0);
			topRightPageReverseShadow.endPoint = CGPointMake(0, 0);
			
			[bottomRightPage addSublayer:bottomRightPageShadow];
			[topRightPageReverseContainer addSublayer:topRightPageReverseShadow];
			
			topRightPageReverseShadow.anchorPoint = CGPointMake(1, 0);
			bottomRightPageShadow.anchorPoint = CGPointMake(1, 1);
			topRightPageReverse.anchorPoint = CGPointMake(0, 0);
			
			[CATransaction commit];
			
        }
        else if(CGRectContainsPoint(quadrante4, touchBeganPoint))
        {
			if(currentPageIndex == 0)
			{
				return NO;
			}
            startCorner = ALTO_SINISTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			[bottomLeftPage addSublayer:bottomLeftPageShadow];
			[topLeftPageReverseContainer addSublayer:topLeftPageReverseShadow];
			
			topLeftPageReverseShadow.anchorPoint = CGPointMake(0, 1);
			topLeftPageReverse.anchorPoint = CGPointMake(1, 0);
			bottomLeftPageShadow.anchorPoint = CGPointMake(1, 0);
			
			[CATransaction commit];
        }
	}
    else // In piedi
    {
        // Robe per quando sono in verticale
		// Controllo in quale quadrante il tocco è stato effettuato
        if(CGRectContainsPoint(quadrante1, touchBeganPoint))
        {
			// Se sono all'ultima pagina non giro un cazzo
			if(currentPageIndex >= numberOfPages - 1)
			{
				return NO;
			}
			[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
			
            startCorner = BASSO_DESTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			currentPageShadow.anchorPoint = CGPointMake(0, 1);
			currentPageShadow.position = CGPointMake(0, pageHeight);
			
			farlokShadow.anchorPoint = CGPointMake(1, 1);
			
			[farlokPageLayerContainer addSublayer:farlokShadow];
			farlokPageLayer.anchorPoint = CGPointMake(0, 1);
			
			[self.layer addSublayer:nextPageLayer];
			[self.layer addSublayer:currentPageLayer];
			[self.layer addSublayer:farlokPageLayerContainer];
			
			currentPageShadow.startPoint = CGPointMake(0,0);
			currentPageShadow.endPoint = CGPointMake(1,0);
			
			farlokShadow.startPoint = CGPointMake(0,0);
			farlokShadow.endPoint = CGPointMake(1,0);
			
			dummyPage = nextPageLayer;
			[dummyPage addSublayer:currentPageShadow];
			[CATransaction commit];
			
        }
        else if(CGRectContainsPoint(quadrante2, touchBeganPoint))
        {
			// Stessa cosa se sono all'ultima e il tipo vuole girare ancora e me le fa girare
			if(currentPageIndex == 0)
			{
				return NO;
			}
			[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
            startCorner = BASSO_SINISTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			currentPageShadow.anchorPoint = CGPointMake(1, 1);
			currentPageShadow.position = CGPointMake(0, 0);
			[farlokPageLayerContainer addSublayer:farlokShadow];
			farlokShadow.anchorPoint = CGPointMake(0, 1);
			
			spineTop = CGPointMake(pageWidth, 0);
			spineBottom = CGPointMake(pageWidth, pageHeight);
			
			currentPageShadow.startPoint = CGPointMake(1,0);
			currentPageShadow.endPoint = CGPointMake(0,0);
			
			farlokShadow.startPoint = CGPointMake(1,0);
			farlokShadow.endPoint = CGPointMake(0,0);
			
			[self.layer addSublayer:prevPageLayer];
			[self.layer addSublayer:currentPageLayer];
			[self.layer addSublayer:farlokPageLayerContainer];
			
			farlokPageLayer.anchorPoint = CGPointMake(1, 1);
			
			dummyPage = prevPageLayer;
			[dummyPage addSublayer:currentPageShadow];
			
			[CATransaction commit];
        }
        else if(CGRectContainsPoint(quadrante3, touchBeganPoint))
        {
			if(currentPageIndex >= numberOfPages - 1)
			{
				return NO;
			}
			[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
			startCorner = ALTO_DESTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			currentPageShadow.anchorPoint = CGPointMake(0, 0);
			currentPageShadow.position = CGPointMake(0, 0);
			farlokPageLayer.anchorPoint = CGPointMake(0, 0);
			[farlokPageLayerContainer addSublayer:farlokShadow];
			farlokPageLayerContainer.mask = farlokPageMask;
			farlokShadow.anchorPoint = CGPointMake(1, 0);
			
			[self.layer addSublayer:nextPageLayer];
			[self.layer addSublayer:currentPageLayer];
			[self.layer addSublayer:farlokPageLayerContainer];
			
			currentPageShadow.startPoint = CGPointMake(0,0);
			currentPageShadow.endPoint = CGPointMake(1,0);
			
			farlokShadow.startPoint = CGPointMake(0,0);
			farlokShadow.endPoint = CGPointMake(1,0);
			
			dummyPage = nextPageLayer;
			[dummyPage addSublayer:currentPageShadow];
			
			[CATransaction commit];
			
        }
        else if(CGRectContainsPoint(quadrante4, touchBeganPoint))
        {
			if(currentPageIndex == 0)
			{
				return NO;
			}
			[self.layer.sublayers makeObjectsPerformSelector:@selector(removeFromSuperlayer)];
			startCorner = ALTO_SINISTRA;
			[CATransaction begin];
			[CATransaction setDisableActions:YES];
			[CATransaction setAnimationDuration:0];
			
			farlokShadow.startPoint = CGPointMake(1,0);
			farlokShadow.endPoint = CGPointMake(0,0);
			farlokPageLayer.anchorPoint = CGPointMake(1, 0);
			farlokShadow.anchorPoint = CGPointMake(0, 0);
			[farlokPageLayerContainer addSublayer:farlokShadow];
			
			[self.layer addSublayer:prevPageLayer];
			[self.layer addSublayer:currentPageLayer];
			[self.layer addSublayer:farlokPageLayerContainer];
			
			currentPageShadow.anchorPoint = CGPointMake(1,0);
			currentPageShadow.startPoint = CGPointMake(1,0);
			currentPageShadow.endPoint = CGPointMake(0,0);
			[currentPageLayer addSublayer:currentPageShadow];
			
			dummyPage = prevPageLayer;
			[dummyPage addSublayer:currentPageShadow];
			
			[CATransaction commit];
        }
		
    }
	
	isFolding = YES;
	mouse = touchBeganPoint;
	follow = touchBeganPoint;
	return YES;
}

- (void)handleTouchEnd:(CGPoint)touchPoint
{
//	NSLog(@"handleTouchEnd");
    if(isLandscape)
	{
		touchPoint = CGPointMake(touchPoint.x - self.frame.size.width / 2, self.frame.size.height - touchPoint.y);
		
		// Controllo in quale quadrante ho mollato il dito
		// Mi serve quando ho finito il giramento e devo risistemare le pagine
		// per sapere se sono andato avanti o indietro
        if(CGRectContainsPoint(quadrante1, touchPoint))
        {
            endCorner = BASSO_DESTRA;  
        }
        else if(CGRectContainsPoint(quadrante2, touchPoint))
        {
            endCorner = BASSO_SINISTRA;
        }
        else if(CGRectContainsPoint(quadrante3, touchPoint))
        {
            endCorner = ALTO_DESTRA;
        }
        else if(CGRectContainsPoint(quadrante4, touchPoint))
        {
            endCorner = ALTO_SINISTRA;
        }
        
        // Controllo in quale quadrante il tocco è stato effettuato
        switch (startCorner)
        {
            case BASSO_DESTRA: // Parte bassa
            case BASSO_SINISTRA:
                if(touchPoint.x > 0)
                {
                    mouse.x = pageWidth;
                    mouse.y = 0;
                }
                else
                {
                    mouse.x = -pageWidth;
                    mouse.y = 0;
                }
                break;
            case ALTO_DESTRA://  Parte alta
            case ALTO_SINISTRA:
                if(touchPoint.x > 0)
                {
                    mouse.x = pageWidth;
                    mouse.y = pageHeight;
                }
                else
                {
                    mouse.x = -pageWidth;
                    mouse.y = pageHeight;
                }
                break;
        }
    }
	else
	{
		// Controllo in quale quadrante ho mollato il dito
		// Mi serve quando ho finito il giramento e devo risistemare le pagine
		// per sapere se sono andato avanti o indietro
        if(CGRectContainsPoint(quadrante1, touchPoint))
        {
            endCorner = BASSO_DESTRA;  
        }
        else if(CGRectContainsPoint(quadrante2, touchPoint))
        {
            endCorner = BASSO_SINISTRA;
        }
        else if(CGRectContainsPoint(quadrante3, touchPoint))
        {
            endCorner = ALTO_DESTRA;
        }
        else if(CGRectContainsPoint(quadrante4, touchPoint))
        {
            endCorner = ALTO_SINISTRA;
        }
		
		if(startCorner == endCorner)
		{
			switch (startCorner)
			{
				case ALTO_DESTRA:
					mouse.x = pageWidth;
					mouse.y = 0;
					break;
				case BASSO_DESTRA:
					mouse.x = pageWidth;
					mouse.y = pageHeight;
					break;
				case ALTO_SINISTRA:
					mouse.x = 0;
					mouse.y = 0;
					break;
				case BASSO_SINISTRA:
					mouse.x = 0;
					mouse.y = pageHeight;
					break;
			}
		}
		else
		{
			// Controllo in quale quadrante il tocco è stato effettuato
			switch (startCorner)
			{
				case BASSO_DESTRA: // Parte bassa
				case BASSO_SINISTRA:
					if(touchPoint.x > pageWidth * 0.5)
					{
						mouse.x = pageWidth * 2;
						mouse.y = pageHeight;
					}
					else
					{
						mouse.x = -pageWidth;
						mouse.y = pageHeight;
					}
					break;
				case ALTO_DESTRA://  Parte alta
				case ALTO_SINISTRA:
					if(touchPoint.x > pageWidth * 0.5)
					{
						mouse.x = pageWidth * 2;
						mouse.y = 0;
					}
					else
					{
						mouse.x = -pageWidth;
						mouse.y = 0;
					}
					break;
			}
		}
	}
	
	// Faccio partire il timer di giramento automatico
	foldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(timerFireMethod:) userInfo:nil repeats:YES];
}

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender
{
	if((isZooming) || (foldingTimer != nil))
		return;
	
	if ([sender numberOfTouches] > 1)
        return;
	
	CGPoint touchPoint = [sender locationInView:self];
	
	if(sender.state == UIGestureRecognizerStateBegan)
	{
		if ([self handleTouchBegan:touchPoint] == NO)
		{
			return;
		}
	}
	else if(sender.state == UIGestureRecognizerStateEnded)
	{
		if(isFolding == YES)
			[self handleTouchEnd:touchPoint];
		return;
	}
	else if(sender.state == UIGestureRecognizerStateChanged)
	{
		if (isFolding == NO)
		{
			return;
		}
	}
	
//	NSLog(@"touchPoint.x = %f touchPoint.y = %f", touchPoint.x, touchPoint.y);
	
	if(isLandscape)
	{
		touchPoint = CGPointMake(touchPoint.x - self.frame.size.width / 2, self.frame.size.height - touchPoint.y);
	}
	
	mouse.x = touchPoint.x;
	mouse.y = touchPoint.y;
	
	if(isLandscape == YES)
	{
		[self recalc];
	}
	else
	{
		[self recalcVertical];
	}

}

-(void) harmonizeFollower
{
	if(abs(mouse.x - follow.x) < .5)
	{
		follow.x = mouse.x;
	}
	else
	{
		follow.x += (mouse.x - follow.x) * .50;
	}
	
	if(follow.x == NAN)
	{
		NSLog(@"follow.x nan");
	}
	
	if(abs(mouse.y - follow.y) < .5)
	{
		follow.y = mouse.y;
	}
	else
	{
		follow.y += (mouse.y - follow.y) * .50;
	}
}

-(void)setIsZooming:(BOOL)value
{
	isZooming = value;
	if(isZooming == NO)
	{
//		NSLog(@"prima della cura self.frame = %f  %f",self.frame.size.width, self.frame.size.height);
		self.frame = CGRectMake(originalFrameRect.origin.x, originalFrameRect.origin.y, originalFrameRect.size.width, originalFrameRect.size.height);
		currentPageLayer.mask = nil;
//		NSLog(@"dopo la cura self.frame = %f  %f",self.frame.size.width, self.frame.size.height);
	}
}

-(BOOL) isZooming
{
	return isZooming;
}


#pragma mark callback per quando il device cambia orientamento
- (void) layoutSubviews
{
	NSLog(@"layoutSubviews");
	[super layoutSubviews];
	originalFrameRect = CGRectMake(self.frame.origin.x, self.frame.origin.x, self.frame.size.width, self.frame.size.height);
	
	UIDeviceOrientation orientation = [[UIDevice currentDevice] orientation];
	if(orientation == UIDeviceOrientationUnknown || orientation == UIDeviceOrientationFaceUp || orientation == UIDeviceOrientationFaceDown)
		return;
	// Se l'orientamento non è cambiato non faccio nulla
	if( (UIDeviceOrientationIsLandscape(currentOrientation) && UIDeviceOrientationIsLandscape(orientation)) ||
		 (UIDeviceOrientationIsPortrait(currentOrientation) && UIDeviceOrientationIsPortrait(orientation)) )
		  return;
	if(currentOrientation == orientation)
		return;
	
	if(UIDeviceOrientationIsLandscape(orientation))
	{
			isLandscape = YES;
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			[self createLayers];
			[self setupInitValues];
			[self setLayerFrames];
			[CATransaction commit];
			
			pageCache.pageSize = CGSizeMake(self.bounds.size.width / 2, self.bounds.size.height);
	}
	else
	{
			isLandscape = NO;
			[self setupInitValues];
			[CATransaction begin];
			[CATransaction setValue:(id)kCFBooleanTrue forKey:kCATransactionDisableActions];
			[self createLayersVertical];
			[self setLayerFramesVertical];
			[CATransaction commit];
			
			pageCache.pageSize = self.bounds.size;
	}
	
	currentOrientation = orientation;
	
	[self getImages];
}

#pragma mark vai a pagina
- (void) goToPage:(int)pageNumber
{
	if(isFolding == YES)
		return;
	
	// Controllo se la pagina esiste
	if((pageNumber < 0) || (pageNumber > numberOfPages) || (pageNumber == currentPageIndex))
	{
		return;
	}
	
	goingToPage = YES;
	isFolding = YES;
	
	// Preparo le pagine e giro
	if(pageNumber > currentPageIndex) // Avanti
	{
		// Preparazione
		if(isLandscape)
		{
			topRightPageReverse.contents = (id) [pageCache cachedImageForPageIndex:pageNumber - 1];
			bottomRightPage.contents = (id) [pageCache cachedImageForPageIndex:pageNumber];
		}
		else
		{
			nextPageLayer.contents = (id)[pageCache cachedImageForPageIndex:pageNumber];
		}
			
		// Giro
		startCorner = BASSO_DESTRA;
		endCorner = BASSO_SINISTRA;
		
		mouse.x = self.frame.size.width - 10;
		mouse.y = self.frame.size.height - 10;
		
		[self handleTouchBegan:CGPointMake(mouse.x, mouse.y)];
	}
	else // Indietro
	{
		// Preparazione
		if(isLandscape)
		{
			topLeftPageReverse.contents = (id) [pageCache cachedImageForPageIndex:pageNumber];
			bottomLeftPage.contents = (id) [pageCache cachedImageForPageIndex:pageNumber - 1];
		}
		else
		{
			prevPageLayer.contents = (id)[pageCache cachedImageForPageIndex:pageNumber];
		}
		
		// Giro
		startCorner = BASSO_SINISTRA;
		endCorner = BASSO_DESTRA;
		
		mouse.x = 10;
		mouse.y = self.frame.size.height - 10;
		
		[self handleTouchBegan:CGPointMake(mouse.x, mouse.y)];
	}
	
	foldingTimer = [NSTimer scheduledTimerWithTimeInterval:0.1 target:self selector:@selector(foldingTimerandler:) userInfo:nil repeats:YES];
	
	currentPageIndex = pageNumber;
	
	// Imposto questo per non incrementare di nuovo le pagine alla fine del metodo di ricalcolo
	autoTurn = YES;
}

- (void) turnPageFwd
{
	int pageToGo;
	if(isLandscape == YES)
	{
		pageToGo = currentPageIndex + 2;
	}
	else
	{
		pageToGo = currentPageIndex + 1;
	}
	
	[self goToPage:pageToGo];
}

- (void) turnPageBack
{
	int pageToGo;
	if(isLandscape)
	{
		pageToGo = currentPageIndex - 2;
	}
	else
	{
		pageToGo = currentPageIndex - 1;
	}
	
	[self goToPage:pageToGo];
}

#pragma mark gestione evento timer
- (void)timerFireMethod:(NSTimer*)theTimer
{
//    NSLog(@"timerFireMethod");
	if(isLandscape)
		[self recalc];
	else
		[self recalcVertical];
}

- (void)foldingTimerandler:(NSTimer*)theTimer
{
	if(startCorner == BASSO_DESTRA)
	{
		// avanti
		mouse.x -= 100;
		if(mouse.x <= -20)
		{
			[foldingTimer invalidate];
			foldingTimer = nil;
			[self handleTouchEnd:CGPointMake(mouse.x, mouse.y)];
		}
	}
	else
	{
		mouse.x += 100;
		if(mouse.x >= pageWidth)
		{
			[foldingTimer invalidate];
			foldingTimer = nil;
			[self handleTouchEnd:CGPointMake(mouse.x, mouse.y)];
		}
	}
	
	if(isLandscape == YES)
	{
		[self recalc];
	}
	else
	{
		[self recalcVertical];
	}
}

+(int) getCurrentPageIndex
{
	return currentPageIndex;
}

+(int) getNumberOfPages
{
	return [[LeavesCache sharedCache] numberOfPages];
}

+(BOOL) getIsLandscape
{
	return isLandscape;
}

+(void) setIsLandscape:(BOOL)value
{
	isLandscape = value;
}

@end

CGFloat distance(CGPoint a, CGPoint b)
{
	return sqrtf(powf(a.x-b.x, 2) + powf(a.y-b.y, 2));
}

CGFloat gradiToRad(CGFloat gradi)
{
	return gradi * M_PI / 180;
}