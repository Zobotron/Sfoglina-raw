
#import <Foundation/Foundation.h>

@interface PDFContainer : NSObject
{
	CGPDFDocumentRef pdf;
	CGPDFDictionaryRef tableOfContents;
}

- (NSUInteger) numberOfPages;
- (void) renderPageAtIndex:(NSUInteger)index inContext:(CGContextRef)ctx;

@end
