//
//  LeavesCache.h
//  Leaves
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

//
// Modificato da: Gigi Villa 2012
//

#import <Foundation/Foundation.h>
#import "PDFContainer.h"

@interface LeavesCache : NSObject
{
	NSMutableDictionary *pageCache;
	PDFContainer *dataSource;
	CGSize pageSize;
	CGSize thumbnailSize;
}

@property (assign, nonatomic) CGSize pageSize;
@property (assign, nonatomic) CGSize thumbnailSize;

+(LeavesCache *) sharedCacheWhithSize:(CGSize)aPageSize;
+(LeavesCache *) sharedCache;

- (CGImageRef) cachedImageForPageIndex:(int)pageIndex;
- (void) precacheImageForPageIndex:(int)pageIndex;
- (void) minimizeToPageIndex:(int)pageIndex vertical:(BOOL)isVertical;
- (UIImage *) imageForPageIndex:(NSUInteger)pageIndex;
- (UIImage *) thumbnailForPageIndex:(NSUInteger)pageIndex;
- (void) flush;
- (NSUInteger) numberOfPages;

@end
