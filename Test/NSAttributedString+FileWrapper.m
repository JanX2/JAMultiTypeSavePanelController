/*	
	NSAttributedString+FileWrapper.m
	
	Category on NSAttributedString for simplifying NSFileWrapper creation.
	
	
	© 2012-2013 Jan Weiß
	
	Permission is hereby granted, free of charge, to any person obtaining a
	copy of this software and associated documentation files (the “Software”),
	to deal in the Software without restriction, including without limitation
	the rights to use, copy, modify, merge, publish, distribute, sublicense,
	and/or sell copies of the Software, and to permit persons to whom the
	Software is furnished to do so, subject to the following conditions:

	The above copyright notice and this permission notice shall be included in
	all copies or substantial portions of the Software.

	THE SOFTWARE IS PROVIDED “AS IS”, WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
	IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
	FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL
	THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
	LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
	FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER
	DEALINGS IN THE SOFTWARE.
*/

#import "NSAttributedString+FileWrapper.h"

NSString * const	SimpleTextType			= @"com.apple.traditional-mac-plain-text";
NSString * const	Word97Type				= @"com.microsoft.word.doc";
NSString * const	Word2003XMLType			= @"com.microsoft.word.wordml";
NSString * const	Word2007Type			= @"org.openxmlformats.wordprocessingml.document";
NSString * const	OpenDocumentTextType	= @"org.oasis-open.opendocument.text";

static NSDictionary *documentTypesForSaving = nil; // Global cache for document types that are available for saving NSAttributedString objects to.

__attribute__((constructor))
static void initialize_navigationBarImages() {
	// Unfortunately, NSAttributedString will only give you types that are not UTIs and specify readable rather than writeable types, so we need to do this manually.
	if (documentTypesForSaving == nil)
	{
		documentTypesForSaving = [[NSDictionary alloc] initWithObjectsAndKeys:
								  NSPlainTextDocumentType, kUTTypePlainText,
								  NSRTFTextDocumentType, (NSString *)kUTTypeRTF,
								  NSRTFDTextDocumentType, (NSString *)kUTTypeRTFD,
								  NSWebArchiveTextDocumentType, (NSString *)kUTTypeWebArchive,
								  NSHTMLTextDocumentType, (NSString *)kUTTypeHTML,
								  NSDocFormatTextDocumentType, Word97Type,
								  NSWordMLTextDocumentType, Word2003XMLType,
								  NSOfficeOpenXMLTextDocumentType, Word2007Type,
								  NSOpenDocumentTextDocumentType, OpenDocumentTextType,
								  nil];
	}
}

__attribute__((destructor))
static void destroy_navigationBarImages() {
	[documentTypesForSaving release];
}

@implementation NSAttributedString (FileWrapper)

+ (NSArray *)availableUTIsForSaving;
{
	return [documentTypesForSaving allKeys];
}

- (NSFileWrapper *)fileWrapperForUTI:(NSString *)typeName
							   error:(NSError **)error;
{
	return [self fileWrapperForUTI:typeName attributes:nil error:error];
}
- (NSFileWrapper *)fileWrapperForUTI:(NSString *)typeName
						  attributes:(NSDictionary *)attributes
							   error:(NSError **)error;
{
	NSString *documentType = [documentTypesForSaving objectForKey:typeName];
	return [self fileWrapperForDocumentType:documentType attributes:attributes error:error];
}

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
										error:(NSError **)error;
{
	return [self fileWrapperForDocumentType:documentType attributes:nil error:error];
}

- (NSFileWrapper *)fileWrapperForDocumentType:(NSString *)documentType 
								   attributes:(NSDictionary *)attributes 
										error:(NSError **)error;
{
    if (documentType == nil)  return nil;
	
	NSFileWrapper *wrapper = nil;
    NSRange range = NSMakeRange(0, self.length);
    NSDictionary *attributesDict;
	
	if (attributes == nil) 
	{
		attributesDict = [NSDictionary dictionaryWithObject:documentType forKey:NSDocumentTypeDocumentAttribute];
	} else 
	{
		NSMutableDictionary *mutableAttributesDict = [[attributes mutableCopy] autorelease];
		[mutableAttributesDict setObject:documentType forKey:NSDocumentTypeDocumentAttribute];
		attributesDict = mutableAttributesDict;
	}
    
    if (documentType == NSRTFDTextDocumentType || (documentType == NSPlainTextDocumentType))
    {
        wrapper = [self fileWrapperFromRange:range documentAttributes:attributesDict error:error];
    }
    else
    {
        NSData *data = [self dataFromRange:range documentAttributes:attributesDict error:error];
        if (data) {
            wrapper = [[[NSFileWrapper alloc] initRegularFileWithContents:data] autorelease];
            if (!wrapper && error) 
			{
				*error = [NSError errorWithDomain:NSCocoaErrorDomain code:NSFileWriteUnknownError userInfo:nil];
			}
        }
    }
	
    return wrapper;
}


@end
