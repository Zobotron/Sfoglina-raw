//
//  LeavesCache.m
//  Leaves
//
//  Created by Tom Brow on 5/12/10.
//  Copyright 2010 Tom Brow. All rights reserved.
//

//
// Modificato da: Gigi Villa 2012
//


#import "LeavesCache.h"

@implementation LeavesCache

@synthesize pageSize, thumbnailSize;

static LeavesCache *sharedCache = nil;

+(LeavesCache *) sharedCacheWhithSize:(CGSize)aPageSize
{
	if(sharedCache == nil)
	{
		sharedCache = [[LeavesCache alloc] initWithPageSize:aPageSize];
	}
	
	return sharedCache;
}

+(LeavesCache *) sharedCache
{
	NSAssert(sharedCache != nil, @"LeavesCache non inizializzata");
	return sharedCache;
}

- (id) initWithPageSize:(CGSize)aPageSize
{
	if ((self = [super init]))
	{
		pageSize = aPageSize;
		pageCache = [[NSMutableDictionary alloc] init];
		dataSource = [[PDFContainer alloc] init];
	}
	return self;
}

// Pagina singola
- (UIImage *) imageForPageIndex:(NSUInteger)pageIndex
{
	if((pageSize.width == 0) || (pageSize.height == 0))
	{
		return nil;
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, 
												 (int)pageSize.width, 
												 (int)pageSize.height, 
												 8,						/* bits per component*/
												 (int)pageSize.width * 4, 	/* bytes per row */
												 colorSpace, 
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	CGContextClipToRect(context, CGRectMake(0, 0, pageSize.width, pageSize.height));
	
	[dataSource renderPageAtIndex:pageIndex inContext:context];
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	UIImage *toRet = [UIImage imageWithCGImage:image];
	CGImageRelease(image);
	
	return toRet;
}

// miniatura
- (UIImage *) thumbnailForPageIndex:(NSUInteger)pageIndex
{
	if((thumbnailSize.width == 0) || (thumbnailSize.height == 0))
	{
		return nil;
	}
	
	CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
	CGContextRef context = CGBitmapContextCreate(NULL, 
												 (int)thumbnailSize.width, 
												 (int)thumbnailSize.height, 
												 8,						/* bits per component*/
												 (int)thumbnailSize.width * 4, 	/* bytes per row */
												 colorSpace, 
												 kCGImageAlphaPremultipliedLast | kCGBitmapByteOrder32Big);
	CGColorSpaceRelease(colorSpace);
	CGContextClipToRect(context, CGRectMake(0, 0, thumbnailSize.width, thumbnailSize.height));
	
	[dataSource renderPageAtIndex:pageIndex inContext:context];
	
	CGImageRef image = CGBitmapContextCreateImage(context);
	CGContextRelease(context);
	
	UIImage *toRet = [UIImage imageWithCGImage:image];
	CGImageRelease(image);
	
	return toRet;
}


- (CGImageRef) cachedImageForPageIndex:(int)pageIndex
{
	int num = [dataSource numberOfPages];
	if((pageIndex < 0) || (pageIndex >= num))
	{
		return nil;
	}
			
	NSNumber *pageIndexNumber = [NSNumber numberWithInt:pageIndex];
	UIImage *pageImage;
	@synchronized (pageCache)
	{
		pageImage = [pageCache objectForKey:pageIndexNumber];
	}
	
	if (!pageImage)
	{
		pageImage = [self imageForPageIndex:pageIndex];
		@synchronized (pageCache)
		{
			[pageCache setObject:pageImage forKey:pageIndexNumber];
		}
	}
	
	CGImageRef toRet = pageImage.CGImage;
	return toRet;
}

- (void) precacheImageForPageIndexNumber:(NSNumber *)pageIndexNumber
{
	@autoreleasepool
	{
		[self cachedImageForPageIndex:[pageIndexNumber intValue]];
	}
}

- (void) precacheImageForPageIndex:(int)pageIndex
{
	[self performSelectorInBackground:@selector(precacheImageForPageIndexNumber:) withObject:[NSNumber numberWithInt:pageIndex]];
}

- (void) minimizeToPageIndex:(int)pageIndex vertical:(BOOL)isVertical
{
	// Pialla le pagine di troppo
	int chechIndex = 0;
	if(isVertical)
	{
		chechIndex = 2;
	}
	else
	{
		chechIndex = 3;
	}
		
	@synchronized (pageCache)
	{
		for (NSNumber *key in [pageCache allKeys])
		{
			if (ABS([key intValue] - (int)pageIndex) > chechIndex)
			{
				[pageCache removeObjectForKey:key];
			}
        }
	}
}

- (void) flush
{
	@synchronized (pageCache)
	{
		[pageCache removeAllObjects];
	}
}

- (NSUInteger) numberOfPages
{
	return dataSource.numberOfPages;
}

#pragma mark accessors

- (void) setPageSize:(CGSize)value
{
	pageSize = value;
	[self flush];
}

@end
