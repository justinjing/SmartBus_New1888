//
//	 ______    ______    ______
//	/\  __ \  /\  ___\  /\  ___\
//	\ \  __<  \ \  __\_ \ \  __\_
//	 \ \_____\ \ \_____\ \ \_____\
//	  \/_____/  \/_____/  \/_____/
//
//
//	Copyright (c) 2013-2014, {Bee} open source community
//	http://www.bee-framework.com
//
//
//	Permission is hereby granted, free of charge, to any person obtaining a
//	copy of this software and associated documentation files (the "Software"),
//	to deal in the Software without restriction, including without limitation
//	the rights to use, copy, modify, merge, publish, distribute, sublicense,
//	and/or sell copies of the Software, and to permit persons to whom the
//	Software is furnished to do so, subject to the following conditions:
//
//	The above copyright notice and this permission notice shall be included in
//	all copies or substantial portions of the Software.
//
//	THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//	AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
//	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS
//	IN THE SOFTWARE.
//

#import "NSString+BeeExtension.h"

#import "Bee_UnitTest.h"
#import "NSData+BeeExtension.h"
#import "NSObject+BeeTypeConversion.h"

// ----------------------------------
// Source code
// ----------------------------------

#pragma mark -

@implementation NSString(BeeExtension)

@dynamic data;
@dynamic date;

@dynamic MD5;
@dynamic MD5Data;

@dynamic SHA1;

@dynamic APPEND;
@dynamic LINE;
@dynamic REPLACE;

- (NSData *)data
{
	return [self dataUsingEncoding:NSUTF8StringEncoding allowLossyConversion:YES];
}

- (NSDate *)date
{
	NSTimeZone * local = [NSTimeZone localTimeZone];
	
	NSString * format = @"yyyy-MM-dd HH:mm:ss";
	NSString * text = [(NSString *)self substringToIndex:format.length];
	
	NSDateFormatter * dateFormatter = [[[NSDateFormatter alloc] init] autorelease];
	[dateFormatter setDateFormat:format];
	[dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
	
	return [NSDate dateWithTimeInterval:(3600 + [local secondsFromGMT])
							  sinceDate:[dateFormatter dateFromString:text]];
}

- (NSStringAppendBlock)APPEND
{
	NSStringAppendBlock block = ^ NSString * ( id first, ... )
	{
		va_list args;
		va_start( args, first );
				
		NSString * append = [[NSString alloc] initWithFormat:first arguments:args];
		
		NSMutableString * copy = [self mutableCopy];
		[copy appendString:append];
		[append release];

		va_end( args );
		
		return [copy autorelease];
	};

	return [[block copy] autorelease];
}

- (NSStringAppendBlock)LINE
{
	NSStringAppendBlock block = ^ NSString * ( id first, ... )
	{
		NSMutableString * copy = [self mutableCopy];

		if ( first )
		{
			va_list args;
			va_start( args, first );
			
			NSString * append = [[NSString alloc] initWithFormat:first arguments:args];
			[copy appendString:append];
			[append release];

			va_end( args );
		}

		[copy appendString:@"\n"];

		return [copy autorelease];
	};
	
	return [[block copy] autorelease];
}

- (NSStringReplaceBlock)REPLACE
{
	NSStringReplaceBlock block = ^ NSString * ( NSString * string1, NSString * string2 )
	{
		return [self stringByReplacingOccurrencesOfString:string1 withString:string2];
	};
	
	return [[block copy] autorelease];
}

- (NSArray *)allURLs
{
	NSMutableArray * array = [NSMutableArray array];
	
	NSInteger stringIndex = 0;
	while ( stringIndex < self.length )
	{
		NSRange searchRange = NSMakeRange(stringIndex, self.length - stringIndex);
		NSRange httpRange = [self rangeOfString:@"http://" options:NSCaseInsensitiveSearch range:searchRange];
		NSRange httpsRange = [self rangeOfString:@"https://" options:NSCaseInsensitiveSearch range:searchRange];
		
		NSRange startRange;
		if ( httpRange.location == NSNotFound )
		{
			startRange = httpsRange;
		}
		else if ( httpsRange.location == NSNotFound )
		{
			startRange = httpRange;
		}
		else
		{
			startRange = (httpRange.location < httpsRange.location) ? httpRange : httpsRange;
		}
		
		if (startRange.location == NSNotFound)
		{
			break;			
		}
		else
		{
			NSRange beforeRange = NSMakeRange( searchRange.location, startRange.location - searchRange.location );
			if ( beforeRange.length )
			{
				//				NSString * text = [string substringWithRange:beforeRange];
				//				[array addObject:text];
			}
			
			NSRange subSearchRange = NSMakeRange(startRange.location, self.length - startRange.location);
			NSRange endRange = [self rangeOfString:@" " options:NSCaseInsensitiveSearch range:subSearchRange];
			if ( endRange.location == NSNotFound)
			{
				NSString * url = [self substringWithRange:subSearchRange];
				[array addObject:url];
				break;				
			}
			else
			{
				NSRange URLRange = NSMakeRange(startRange.location, endRange.location - startRange.location);
				NSString * url = [self substringWithRange:URLRange];
				[array addObject:url];
				
				stringIndex = endRange.location;
			}
		}
	}
	
	return array;
}

+ (NSString *)queryStringFromDictionary:(NSDictionary *)dict
{
    NSMutableArray * pairs = [NSMutableArray array];
	for ( NSString * key in dict.allKeys )
	{
		NSString * value = [((NSObject *)[dict objectForKey:key]) asNSString];
		NSString * urlEncoding = [value URLEncoding];
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, urlEncoding]];
	}
	
	return [pairs componentsJoinedByString:@"&"];
}

+ (NSString *)queryStringFromArray:(NSArray *)array
{
	NSMutableArray *pairs = [NSMutableArray array];
	
	for ( NSUInteger i = 0; i < [array count]; i += 2 )
	{
		NSObject * obj1 = [array objectAtIndex:i];
		NSObject * obj2 = [array objectAtIndex:i + 1];
		
		NSString * key = nil;
		NSString * value = nil;
		
		if ( [obj1 isKindOfClass:[NSNumber class]] )
		{
			key = [(NSNumber *)obj1 stringValue];
		}
		else if ( [obj1 isKindOfClass:[NSString class]] )
		{
			key = (NSString *)obj1;
		}
		else
		{
			continue;
		}
		
		if ( [obj2 isKindOfClass:[NSNumber class]] )
		{
			value = [(NSNumber *)obj2 stringValue];
		}
		else if ( [obj1 isKindOfClass:[NSString class]] )
		{
			value = (NSString *)obj2;
		}
		else
		{
			continue;
		}
		
		NSString * urlEncoding = [value URLEncoding];
		[pairs addObject:[NSString stringWithFormat:@"%@=%@", key, urlEncoding]];
	}
	
	return [pairs componentsJoinedByString:@"&"];
}

+ (NSString *)queryStringFromKeyValues:(id)first, ...
{
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	
	va_list args;
	va_start( args, first );
	
	for ( ;; )
	{
		NSObject<NSCopying> * key = [dict count] ? va_arg( args, NSObject * ) : first;
		if ( nil == key )
			break;
		
		NSObject * value = va_arg( args, NSObject * );
		if ( nil == value )
			break;
		
		[dict setObject:value forKey:key];
	}
	va_end( args );
	return [NSString queryStringFromDictionary:dict];
}

- (NSString *)urlByAppendingDict:(NSDictionary *)params
{
    NSURL * parsedURL = [NSURL URLWithString:self];
	NSString * queryPrefix = parsedURL.query ? @"&" : @"?";
	NSString * query = [NSString queryStringFromDictionary:params];
	return [NSString stringWithFormat:@"%@%@%@", self, queryPrefix, query];	
}

- (NSString *)urlByAppendingArray:(NSArray *)params
{
    NSURL * parsedURL = [NSURL URLWithString:self];
	NSString * queryPrefix = parsedURL.query ? @"&" : @"?";
	NSString * query = [NSString queryStringFromArray:params];
	return [NSString stringWithFormat:@"%@%@%@", self, queryPrefix, query];		
}

- (NSString *)urlByAppendingKeyValues:(id)first, ...
{
	NSMutableDictionary * dict = [NSMutableDictionary dictionary];
	
	va_list args;
	va_start( args, first );
	
	for ( ;; )
	{
		NSObject<NSCopying> * key = [dict count] ? va_arg( args, NSObject * ) : first;
		if ( nil == key )
			break;
		
		NSObject * value = va_arg( args, NSObject * );
		if ( nil == value )
			break;

		[dict setObject:value forKey:key];
	}
    va_end( args );
	return [self urlByAppendingDict:dict];
}

- (BOOL)empty
{
	return [self length] > 0 ? NO : YES;
}

- (BOOL)notEmpty
{
	return [self length] > 0 ? YES : NO;
}

- (BOOL)is:(NSString *)other
{
	return [self isEqualToString:other];
}

- (BOOL)isNot:(NSString *)other
{
	return NO == [self isEqualToString:other];
}

- (BOOL)isValueOf:(NSArray *)array
{
	return [self isValueOf:array caseInsens:NO];
}

- (BOOL)isValueOf:(NSArray *)array caseInsens:(BOOL)caseInsens
{
	NSStringCompareOptions option = caseInsens ? NSCaseInsensitiveSearch : 0;
	
	for ( NSObject * obj in array )
	{
		if ( NO == [obj isKindOfClass:[NSString class]] )
			continue;
		
		if ( [(NSString *)obj compare:self options:option] )
			return YES;
	}
	
	return NO;
}

- (NSString *)URLEncoding
{
	NSString * result = (NSString *)CFURLCreateStringByAddingPercentEscapes( kCFAllocatorDefault,
																			(CFStringRef)self,
																			NULL,  
																			(CFStringRef)@"!*'();:@&=+$,/?%#[]",  
																			kCFStringEncodingUTF8 );  
	return [result autorelease];
}

- (NSString *)URLDecoding
{
	NSMutableString * string = [NSMutableString stringWithString:self]; 
    [string replaceOccurrencesOfString:@"+"  
							withString:@" "  
							   options:NSLiteralSearch  
								 range:NSMakeRange(0, [string length])];  
    return [string stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
}

- (NSString *)MD5
{
	NSData * value;
	
	value = [NSData dataWithBytes:[self UTF8String] length:[self length]];
	value = [value MD5];

	if ( value )
	{
		char			tmp[16];
		unsigned char *	hex = (unsigned char *)malloc( 2048 + 1 );
		unsigned char *	bytes = (unsigned char *)[value bytes];
		unsigned long	length = [value length];
		
		hex[0] = '\0';
		
		for ( unsigned long i = 0; i < length; ++i )
		{
			sprintf( tmp, "%02x", bytes[i] );
			strcat( (char *)hex, tmp );
		}
		
		NSString * result = [NSString stringWithUTF8String:(const char *)hex];
		free( hex );
		return result;
	}
	else
	{
		return nil;
	}
}

- (NSData *)MD5Data
{
	// TODO:
	return nil;
}

// thanks to @uxyheaven
- (NSString *)SHA1
{
    const char *	cstr = [self cStringUsingEncoding:NSUTF8StringEncoding];
    NSData *		data = [NSData dataWithBytes:cstr length:self.length];

    uint8_t			digest[CC_SHA1_DIGEST_LENGTH] = { 0 };
	CC_LONG			digestLength = (CC_LONG)data.length;

    CC_SHA1( data.bytes, digestLength, digest );

    NSMutableString * output = [NSMutableString stringWithCapacity:CC_SHA1_DIGEST_LENGTH * 2];
	
    for ( int i = 0; i < CC_SHA1_DIGEST_LENGTH; i++ )
	{
		[output appendFormat:@"%02x", digest[i]];
	}

    return output;
}

- (NSString *)trim
{
	return [self stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
}

- (NSString *)unwrap
{
	if ( self.length >= 2 )
	{
		if ( [self hasPrefix:@"\""] && [self hasSuffix:@"\""] )
		{
			return [self substringWithRange:NSMakeRange(1, self.length - 2)];
		}

		if ( [self hasPrefix:@"'"] && [self hasSuffix:@"'"] )
		{
			return [self substringWithRange:NSMakeRange(1, self.length - 2)];
		}
	}

	return self;
}

- (BOOL)isUserName
{
	NSString *		regex = @"(^[A-Za-z0-9]{3,20}$)";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];
}

- (BOOL)isPassword
{
	NSString *		regex = @"(^[A-Za-z0-9]{6,20}$)";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];	
}

- (BOOL)isEmail
{
	NSString *		regex = @"[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,4}";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];
}

- (BOOL)isUrl
{
    NSString *		regex = @"http(s)?:\\/\\/([\\w-]+\\.)+[\\w-]+(\\/[\\w- .\\/?%&=]*)?";
	NSPredicate *	pred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", regex];
	
	return [pred evaluateWithObject:self];
}

- (BOOL)isTelephone
{
    NSString * MOBILE = @"^1(3[0-9]|5[0-35-9]|8[025-9])\\d{8}$";
    NSString * CM = @"^1(34[0-8]|(3[5-9]|5[017-9]|8[278])\\d)\\d{7}$";
    NSString * CU = @"^1(3[0-2]|5[256]|8[56])\\d{8}$";
    NSString * CT = @"^1((33|53|8[09])[0-9]|349)\\d{7}$";
    NSString * PHS = @"^0(10|2[0-5789]|\\d{3})\\d{7,8}$";
    NSPredicate *regextestmobile = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", MOBILE];
    NSPredicate *regextestcm = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CM];
    NSPredicate *regextestcu = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CU];
    NSPredicate *regextestct = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", CT];
    NSPredicate *regextestphs = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", PHS];

    return  [regextestmobile evaluateWithObject:self]   ||
            [regextestphs evaluateWithObject:self]      ||
            [regextestct evaluateWithObject:self]       ||
            [regextestcu evaluateWithObject:self]       ||
            [regextestcm evaluateWithObject:self];
}

#if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)
- (CGSize)sizeWithFont:(UIFont *)font byWidth:(CGFloat)width
{
	return [self sizeWithFont:font
			constrainedToSize:CGSizeMake(width, 999999.0f)
				lineBreakMode:UILineBreakModeWordWrap];	
}

- (CGSize)sizeWithFont:(UIFont *)font byHeight:(CGFloat)height
{
	return [self sizeWithFont:font
			constrainedToSize:CGSizeMake(999999.0f, height)
				lineBreakMode:UILineBreakModeWordWrap];
}
#endif	// #if (TARGET_OS_IPHONE || TARGET_IPHONE_SIMULATOR)

- (BOOL)match:(NSString *)expression
{
	NSRegularExpression * regex = [NSRegularExpression regularExpressionWithPattern:expression
																			options:NSRegularExpressionCaseInsensitive
																			  error:nil];
	if ( nil == regex )
		return NO;
	
	NSUInteger numberOfMatches = [regex numberOfMatchesInString:self
														options:0
														  range:NSMakeRange(0, self.length)];
	if ( 0 == numberOfMatches )
		return NO;

	return YES;
}

- (BOOL)matchAnyOf:(NSArray *)array
{
	for ( NSString * str in array )
	{
		if ( NSOrderedSame == [self compare:str options:NSCaseInsensitiveSearch] )
		{
			return YES;
		}
	}
	
	return NO;
}

@end

#pragma mark -

@implementation NSMutableString(BeeExtension)

@dynamic APPEND;
@dynamic LINE;
@dynamic REPLACE;

- (NSMutableStringAppendBlock)APPEND
{
	NSMutableStringAppendBlock block = ^ NSMutableString * ( id first, ... )
	{
		va_list args;
		va_start( args, first );
		
		NSString * append = [[NSString alloc] initWithFormat:first arguments:args];
		[self appendString:append];
		[append release];
		
		va_end( args );

		return self;
	};
	
	return [[block copy] autorelease];
}

- (NSMutableStringAppendBlock)LINE
{
	NSMutableStringAppendBlock block = ^ NSMutableString * ( id first, ... )
	{
		if ( first )
		{
			va_list args;
			va_start( args, first );
			
			NSString * append = [[NSString alloc] initWithFormat:first arguments:args];
			[(NSMutableString *)self appendString:append];
			[append release];
			
			va_end( args );
		}
		
		[(NSMutableString *)self appendString:@"\n"];

		return self;
	};
	
	return [[block copy] autorelease];
}

- (NSMutableStringReplaceBlock)REPLACE
{
	NSMutableStringReplaceBlock block = ^ NSMutableString * ( NSString * string1, NSString * string2 )
	{
		[self replaceOccurrencesOfString:string1
							  withString:string2
								 options:NSCaseInsensitiveSearch
								   range:NSMakeRange(0, self.length)];
		
		return self;
	};
	
	return [[block copy] autorelease];
}

@end

// ----------------------------------
// Unit test
// ----------------------------------

#pragma mark -

#if defined(__BEE_UNITTEST__) && __BEE_UNITTEST__

TEST_CASE( NSString_BeeExtension )
{
}
TEST_CASE_END

#endif	// #if defined(__BEE_UNITTEST__) && __BEE_UNITTEST__
