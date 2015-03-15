//
//  LeavesView.h
//  Leaves
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

//
// Modificato da: Gigi Villa 2012
//


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import "LeavesCache.h"
#import "LeavesViewControllerProtocol.h"

// fattore di scala per struttura
#define MAX_SCALE 4;
#define MIN_SCALE 1;
#define SCALE_STEP 0.25;

// fattore di scala per immagini pagine
#define MAX_IMG_SCALE 1;
#define MIN_IMG_SCALE 0.5;

// Angoli di partenza del trascinamento pagina
enum {
	BASSO_DESTRA = 1,
	BASSO_SINISTRA = 2,
	ALTO_DESTRA  = 3,
	ALTO_SINISTRA = 4
};

@interface LeavesView : UIView <UIGestureRecognizerDelegate>
{
    /** Nota per Mario : 
     Quando applico una maschera al livello il bastardo mi mette come superlayer della mascher il livello 
     della pagina, quindi quando applico le trasformazioni alla pagina la maschera se ne va affanculo.
     Allora io che sono astuto metto la pagina e una maschera in un altro layer che se ne sta fermo, poi maschero quello.
     */
    
	// Accrocchi a destra
	CALayer *topRightPage;
	CAShapeLayer *topRightPageMask;
	
	CALayer *topRightPageReverse;
    CALayer *topRightPageReverseContainer; // Il livello che contiene pagina e maschera
	CAGradientLayer *topRightPageReverseShadow;
	CAShapeLayer *topRightPageReverseMask;
	
	CALayer *bottomRightPage;
	CAGradientLayer *bottomRightPageShadow;
	CAShapeLayer *bottomRightPageMask;
	// Mi serve un container per la maschera quando sono in verticale, se ne uso uno
	// già fatto mi confondo coi nomi e mi incasino
	CALayer *bottomRightPageContainer;
	
	// Quelli di sinistra
	CALayer *topLeftPage;
	CAShapeLayer *topLeftPageMask;
	
	CALayer *topLeftPageReverse;
	CAGradientLayer *topLeftPageReverseShadow;
	CAShapeLayer *topLeftPageReverseMask;
	CALayer *topLeftPageReverseContainer;
	
	CALayer *bottomLeftPage;
	CAGradientLayer *bottomLeftPageShadow;
	CAShapeLayer *bottomLeftPageMask;
	
	//*******************
	// Pagine verticali
	//*******************
	CALayer *currentPageLayer;
	CAShapeLayer *currentPageMask;
	CALayer *nextPageLayer;
	CALayer *prevPageLayer;
	// Siccome ruota e mi ruoterebbe pure l'ombra devo metterla in un container
	CALayer *farlokPageLayer;
	CALayer *farlokPageLayerContainer;
	CAShapeLayer *farlokPageMask;
	// Ombre, me ne servono solo due
	CAGradientLayer *farlokShadow;
	CAGradientLayer *currentPageShadow;
	
	// Pagina per puntare alla pagina successiva/precedente in modalità verticale
	CALayer *dummyPage;
	
	// pallette per il debug
	CALayer *M;
	CALayer *F;
	CALayer *R1;
    CALayer *R2;
	CALayer *T0;
	CALayer *T1;
	CALayer *T2;
	CALayer *T3;
	
	// robe per calcolo
	CGPoint leafEdge;
	int numberOfPages;
	
	LeavesCache *pageCache;
	CGFloat preferredTargetWidth;
	BOOL backgroundRendering;
	
//	CGPoint touchBeganPoint;
	CGRect nextPageRect, prevPageRect;
	
	float pageWidth;
    float pageHeight;
	float pageHalfHeight;
	float pageDiagonal;
	
	// Serve per il disegno della carta che sporge, senza bordo non si vede un cazzo
	float maskHeightOffset;
	
	float bisectorTangent;
	
	CGPoint spineTop;
	CGPoint spineBottom;
	
	float dx;
    float dy;
    float a2f;
    float fixedRadius;
	
    CGPoint tangentBottom;
    
    // Pinto del triangolo sul limete della pagina
    CGPoint T3Point;
	
	CGPoint mouse;
	CGPoint follow;
	
	CGPoint radius1;
	CGPoint radius2;
	CGPoint bisector;
	
	// Angolo di rotazione della pagina
	float pageAngle;
	
	// Angolo di rotazione ombra
	float shadowAngle;
	
	// Numero totale di pagine
	int totPages;
	
	// Mi servono due cosine per controllare che la pagina sia stata effettivamente voltata
	// Altrimenti se il tizio molla a metà mi va avanti/indietro uguale. cazzo.
	int startCorner; // 1 = angolo destro basso / 2 = angolo sinistro basso / 3 = angolo destro alto / 4 = angolo sinistro alto
	int endCorner; // Stessa roba, mi serve per sapere se ho girato davvero pagina
    
    // Rettangoli per i quattro quadranti
    CGRect quadrante1;
    CGRect quadrante2;
    CGRect quadrante3;
    CGRect quadrante4;
	
	// Questo mi dice se sono partito in basso
	BOOL basso;
	
	float scale;
	float imgScale;
    
    // timer per il completamento del giramento di pagina
    // Algtrimenti resta li e aspetta come un cucù
    NSTimer *foldingTimer;
	
	BOOL isFolding;
	BOOL isZooming;
	BOOL goingToPage;
	
	// Orientamento corrente per controllo rotazioni
	UIDeviceOrientation currentOrientation;
	
	UIScrollView *myScroller;
	
	// Misura originale del frame, mi serve quando faccio lo zoom
	// per tornare comero prima
	CGRect originalFrameRect;
	
	// Flag che mi dice se sto girando da solo
	BOOL autoTurn;
}

@property (readwrite, retain) LeavesCache *pageCache;
@property (assign, nonatomic) CGPoint leafEdge;
@property (readonly) float pageWidth;
@property (readonly) float pageHeight;
@property (readwrite) BOOL isZooming;
@property (readwrite) id<LeavesViewControllerProtocol> myController;

// refreshes the contents of all pages via the data source methods, much like -[UITableView reloadData]
- (void) reloadData;
- (void) getImages;
- (void) getZoomImagesWithScale:(NSNumber *)theScale;
- (void) goToPage:(int)pageNumber;
- (void) turnPageFwd;
- (void) turnPageBack;

- (IBAction)handlePanGesture:(UIPanGestureRecognizer *)sender;

+(int) getCurrentPageIndex;
+(int) getNumberOfPages;
+(BOOL) getIsLandscape;
+(void) setIsLandscape:(BOOL)value;

@end

