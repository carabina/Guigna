#import "GAdditions.h"


@implementation NSArray (GAdditions)

- (NSString *)join {
    return [self componentsJoinedByString:@" "];
    
}

- (NSString *)join:(NSString *)separator {
    return [self componentsJoinedByString:separator];
    
}

@end


@implementation NSString (GAdditions)

- (BOOL)is:(NSString *)string {
    return [self isEqualToString:string];
}

- (BOOL)contains:(NSString *)string {
    return [self rangeOfString:string].location != NSNotFound;
}

- (NSUInteger)index:(NSString *)string {
    return [self rangeOfString:string].location;
}

- (NSUInteger)rindex:(NSString *)string {
    return [self rangeOfString:string options:NSBackwardsSearch].location;
}

- (NSArray *)split {
    return [self componentsSeparatedByString:@" "];
}

- (NSArray *)split:(NSString *)delimiter {
    return [self componentsSeparatedByString:delimiter];
}

@end


@implementation NSXMLNode (GAdditions)

- (NSArray *)nodesForXPath:(NSString *)xpath {
    return [self nodesForXPath:xpath error:nil];
}

- objectForKeyedSubscript:xpath {
    return [self nodesForXPath:xpath error:nil];
}

@end


@implementation NSXMLElement (GAdditions)

- objectForKeyedSubscript:(NSString *)xpath {
    if ([xpath hasPrefix:@"@"])
        return [[self attributeForName:[xpath substringFromIndex:1]] stringValue];
    else
        return [super objectForKeyedSubscript:xpath];
}

- (NSString *)href {
    return [[self attributeForName:@"href"] stringValue];
}

@end


@implementation NSUserDefaultsController (GAdditions)

- objectForKeyedSubscript:key {
    return [[self values] valueForKey:key];
}

- (void)setObject:value forKeyedSubscript:key {
    [[self values] setValue:value forKey:key];
}

@end


@implementation WebView (GAdditions)

- (void)swipeWithEvent:(NSEvent *)event {
    CGFloat x = [event deltaX];
	if (x < 0 && [self canGoForward])
		[self goForward];
	else if (x > 0 && [self canGoBack])
		[self goBack];
}

- (void)magnifyWithEvent:(NSEvent *)event {
	float multiplier = [self textSizeMultiplier] * ([event magnification] + 1.0);
	[self setTextSizeMultiplier:multiplier];
}

@end

