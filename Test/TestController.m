#import "TestController.h"
#import "JAMultiTypeSavePanelController.h"


static NSDictionary *sTypes = nil;


@implementation TestController

- (IBAction) save:(id)sender
{
	// Unfortunately, NSAttributedString will only give you types that are not UTIs and specify readable rather than writeable types, so we need to do this manually.
	if (sTypes == nil)
	{
		sTypes = [NSDictionary dictionaryWithObjectsAndKeys:
		NSPlainTextDocumentType, @"public.plain-text",
		NSRTFTextDocumentType, @"public.rtf",
		NSRTFDTextDocumentType, @"com.apple.rtfd",
		NSHTMLTextDocumentType, @"public.html",
		NSDocFormatTextDocumentType, @"com.microsoft.word.doc",
		NSWordMLTextDocumentType, @"org.openxmlformats.wordprocessingml.document",
		nil];
		[sTypes retain];
	}
	JAMultiTypeSavePanelController *saveController = [JAMultiTypeSavePanelController controllerWithSupportedUTIs:[sTypes allKeys]];
	saveController.autoSaveSelectedUTIKey = @"type";
	[saveController beginForFile:@"untitled"
				  modalForWindow:window
				   modalDelegate:self
				  didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)];
}


- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	NSLog(@"Save panel result: %i", returnCode);
	[sheetController.savePanel orderOut:nil];
	
	if (returnCode == NSOKButton)
	{
		NSError *error = nil;
		NSLog(@"Saving as %@/%@", sheetController.selectedUTI, [sTypes objectForKey:sheetController.selectedUTI]);
		
		NSRange range = {0, textView.textStorage.length};
		NSDictionary *typeAttr = [NSDictionary dictionaryWithObject:[sTypes objectForKey:sheetController.selectedUTI] forKey:NSDocumentTypeDocumentAttribute];
		NSString *path = sheetController.savePanel.filename;
		
		NSFileWrapper *wrapper = [textView.textStorage fileWrapperFromRange:range documentAttributes:typeAttr error:&error];
		if (wrapper == nil)
		{
			[[NSAlert alertWithError:error] beginSheetModalForWindow:window
													   modalDelegate:nil
													  didEndSelector:NULL
														 contextInfo:nil];
		}
		else
		{
			BOOL OK = [wrapper writeToFile:path atomically:YES updateFilenames:YES];
			if (!OK)
			{
				[[NSAlert alertWithMessageText:@"Failed to save document."
								 defaultButton:nil
							   alternateButton:nil
								   otherButton:nil
					 informativeTextWithFormat:@"Unfortunately, NSFileWrapper doesn't feel like telling us why."]
				 beginSheetModalForWindow:window
							modalDelegate:nil
						   didEndSelector:nil
							  contextInfo:nil];
			}
		}
	}
}

@end