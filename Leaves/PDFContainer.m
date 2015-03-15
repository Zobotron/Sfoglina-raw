#import "PDFContainer.h"
#import "Utilities.h"

@implementation PDFContainer

- (id)init
{
    if (self = [super init])
	{
		[self viewDidLoad];
	}
    return self;
}

- (void)dealloc {
	CGPDFDocumentRelease(pdf);
}

- (void) displayPageNumber:(NSUInteger)pageNumber
{
}

#pragma mark LeavesViewDataSource methods

- (NSUInteger) numberOfPages
{
	return CGPDFDocumentGetNumberOfPages(pdf);
}

- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx
{
	CGPDFPageRef page = CGPDFDocumentGetPage(pdf, index + 1);
	CGAffineTransform transform = aspectFit(CGPDFPageGetBoxRect(page, kCGPDFMediaBox), CGContextGetClipBoundingBox(ctx));
	CGContextConcatCTM(ctx, transform);
	CGContextDrawPDFPage(ctx, page);
}

#pragma mark UIViewController

- (void) viewDidLoad {
	
	CFURLRef pdfURL = CFBundleCopyResourceURL(CFBundleGetMainBundle(), CFSTR("catalogo.pdf"), NULL, NULL);
	pdf = CGPDFDocumentCreateWithURL((CFURLRef)pdfURL);
//	tableOfContents = CGPDFDocumentGetCatalog(pdf);
	CFRelease(pdfURL);
}

@end
