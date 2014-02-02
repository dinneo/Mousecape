//
//  MCCursor.m
//  Mousecape
//
//  Created by Alex Zielenski on 2/2/14.
//  Copyright (c) 2014 Alex Zielenski. All rights reserved.
//

#import "MCCursor.h"

MCCursorScale cursorScaleForScale(CGFloat scale) {
    if (scale < 0.0)
        return MCCursorScaleNone;
    
    return (MCCursorScale)((NSInteger)scale * 100);
}

@interface MCCursor ()
@property (readwrite, strong) NSMutableDictionary *representations;
- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version;
@end

@implementation MCCursor
+ (MCCursor *)cursorWithDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    return [[self alloc] initWithCursorDictionary:dict ofVersion:version];
}

- (id)init {
    if ((self = [super init])) {
        self.frameCount      = 1;
        self.frameDuration   = 1.0;
        self.size            = NSZeroSize;
        self.hotSpot         = NSZeroPoint;
        self.representations = [NSMutableDictionary dictionary];
    }
    return self;
}

- (id)initWithCursorDictionary:(NSDictionary *)dict ofVersion:(CGFloat)version {
    if ((self = [self init])) {
        
        if (![self _readFromDictionary:dict ofVersion:version])
            return nil;
        
    }
    
    return self;
}

- (id)copyWithZone:(NSZone *)zone {
    MCCursor *cursor = [[MCCursor allocWithZone:zone] init];
    
    cursor.frameCount      = self.frameCount;
    cursor.frameDuration   = self.frameDuration;
    cursor.size            = self.size;
    cursor.representations = self.representations.mutableCopy;
    cursor.hotSpot         = self.hotSpot;
    cursor.name            = self.name;
    
    return cursor;
}

+ (NSSet *)keyPathsForValuesAffectingValueForKey:(NSString *)key {
    
    NSSet *keyPaths = [super keyPathsForValuesAffectingValueForKey:key];
    
    if ([key isEqualToString:@"imageWithAllReps"]) {
        keyPaths = [keyPaths setByAddingObjectsFromArray:@[ @"representations" ]];
    }
    return keyPaths;
}

- (BOOL)_readFromDictionary:(NSDictionary *)dictionary ofVersion:(CGFloat)version {
    if (!dictionary || !dictionary.count)
        return NO;
    
    NSNumber *frameCount    = [dictionary objectForKey:MCCursorDictionaryFrameCountKey];
    NSNumber *frameDuration = [dictionary objectForKey:MCCursorDictionaryFrameDuratiomKey];
    //    NSNumber *repeatCount   = dictionary[MCCursorDictionaryRepeatCountKey];
    NSNumber *hotSpotX      = [dictionary objectForKey:MCCursorDictionaryHotSpotXKey];
    NSNumber *hotSpotY      = [dictionary objectForKey:MCCursorDictionaryHotSpotYKey];
    NSNumber *pointsWide    = [dictionary objectForKey:MCCursorDictionaryPointsWideKey];
    NSNumber *pointsHigh    = [dictionary objectForKey:MCCursorDictionaryPointsHighKey];
    NSArray *reps           = [dictionary objectForKey:MCCursorDictionaryRepresentationsKey];
    
    // we only take version 2.0 documents.
    if (version >=  2.0) {
        if (frameCount && frameDuration && hotSpotX && hotSpotY && pointsWide && pointsHigh && reps && reps.count > 0) {
            
            self.frameCount    = frameCount.unsignedIntegerValue;
            self.frameDuration = frameDuration.doubleValue;
            self.hotSpot       = NSMakePoint(hotSpotX.doubleValue, hotSpotY.doubleValue);
            self.size          = NSMakeSize(pointsWide.doubleValue, pointsHigh.doubleValue);
            //            self.repeatCount   = repeatCount.unsignedIntegerValue;
            
            
            for (NSData *data in reps) {
                // data in v2.0 documents are saved as PNGs
                NSBitmapImageRep *rep = [[NSBitmapImageRep alloc] initWithData:data];
                rep.size = NSMakeSize(self.size.width, self.size.height * self.frameCount);
                [self setRepresentation:rep forScale:cursorScaleForScale(rep.pixelsWide / self.size.width)];
            }
            if (self.representations.count == 0)
                return NO;
            
            return YES;
        }
        
    }
    
    return NO;
}

- (NSDictionary *)dictionaryRepresentation {
    NSMutableDictionary *drep = [NSMutableDictionary dictionary];
    drep[MCCursorDictionaryFrameCountKey]    = @(self.frameCount);
    drep[MCCursorDictionaryFrameDuratiomKey] = @(self.frameDuration);
    drep[MCCursorDictionaryHotSpotXKey]      = @(self.hotSpot.x);
    drep[MCCursorDictionaryHotSpotYKey]      = @(self.hotSpot.y);
    drep[MCCursorDictionaryPointsWideKey]    = @(self.size.width);
    drep[MCCursorDictionaryPointsHighKey]    = @(self.size.height);
    
    NSMutableArray *pngs = [NSMutableArray array];
    for (NSString *key in self.representations) {
        NSBitmapImageRep *rep = self.representations[key];
        pngs[pngs.count] = [rep representationUsingType:NSPNGFileType properties:nil];
    }
    
    drep[MCCursorDictionaryRepresentationsKey] = pngs;
    
    return drep;
}

- (id)valueForKey:(NSString *)key {
    if ([key isEqualToString:@"hotSpot"]) {
        return [NSValue valueWithPoint:self.hotSpot];
    }
    
    if ([key isEqualToString:@"size"]) {
        return [NSValue valueWithSize:self.size];
    }
    
    return [super valueForKey:key];
}

- (void)setValue:(id)value forKey:(NSString *)key {
    if ([key isEqualToString:@"hotSpot"]) {
        self.hotSpot = [value pointValue];
        return;
    }
    
    if ([key isEqualToString:@"size"]) {
        self.size = [value sizeValue];
        return;
    }
    
    [super setValue:value forKey:key];
}

- (void)setRepresentation:(NSImageRep *)imageRep forScale:(MCCursorScale)scale {
    [self willChangeValueForKey:@"representations"];
    if (imageRep)
        [self.representations setObject:imageRep forKey:@(scale)];
    else
        [self.representations removeObjectForKey:@(scale)];
    [self didChangeValueForKey:@"representations"];
}

- (void)removeRepresentationForScale:(MCCursorScale)scale {
    [self setRepresentation:Nil forScale:scale];
}

- (NSImageRep *)representationForScale:(MCCursorScale)scale {
    return self.representations[@(scale)];
}

- (NSImageRep *)representationWithScale:(CGFloat)scale {
    return [self representationForScale:cursorScaleForScale(scale)];
}

- (NSImage *)imageWithAllReps {
    NSImage *image = [[NSImage alloc] initWithSize:NSMakeSize(self.size.width, self.size.height * self.frameCount)];
    image.matchesOnMultipleResolution  = YES;
    [image addRepresentations:self.representations.allValues];
    return image;
}

- (BOOL)isEqualTo:(MCCursor *)object {
    if (![object isKindOfClass:self.class]) {
        return NO;
    }
    
    BOOL props =  (object.frameCount == self.frameCount &&
                   object.frameDuration == self.frameDuration &&
                   NSEqualSizes(object.size, self.size) &&
                   NSEqualPoints(object.hotSpot, self.hotSpot) &&
                   [object.name isEqualToString:self.name]);

//    props = (props && [self.representations isEqualToDictionary:object.representations]);
    
    return props;
}

- (BOOL)isEqual:(id)object {
    return [self isEqualTo:object];
}

@end
