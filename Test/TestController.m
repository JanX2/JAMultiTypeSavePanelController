#import "TestController.h"
#import "JAMultiTypeSavePanelController.h"

#import "NSAttributedString+FileWrapper.h"

NSString * const	DefaultFileName								= @"untitled";


@interface TestController ()
- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo;
@end


@implementation TestController

- (void) dealloc
{
	[saveController release];
	
	[super dealloc];
}

- (void) prepareSaveController {
	if (saveController == nil)  saveController = [[JAMultiTypeSavePanelController alloc] initWithSupportedUTIs:[NSAttributedString availableUTIsForSaving]];
	
	saveController.autoSaveSelectedUTIKey = @"type";
	
	// Documents that contain attachments can only be saved in formats that support embedded graphics. 
	if ([textView.textStorage containsAttachments])
	{
		saveController.enabledUTIs = [NSSet setWithObjects:(NSString *)kUTTypeRTFD, (NSString *)kUTTypeWebArchive, nil];
	}
	else
	{
		saveController.enabledUTIs = nil; // Setting enabledUTIs to nil prevents it from having any effect.
	}
}

- (IBAction) save:(id)sender
{
	[self prepareSaveController];
	
	[saveController beginForFile:DefaultFileName
				  modalForWindow:window
				   modalDelegate:self
				  didEndSelector:@selector(savePanelDidEnd:returnCode:contextInfo:)];
}

#if NS_BLOCKS_AVAILABLE
- (IBAction) saveUsingBlock:(id)sender
{
	[self prepareSaveController];
	
	[saveController beginSheetForFileName:DefaultFileName
						   modalForWindow:window 
						completionHandler:^(NSInteger returnCode) {
							// Alternatively, code similar to “-savePanelDidEnd:returnCode:contextInfo:” could be included here directly
							[self savePanelDidEnd:saveController returnCode:returnCode contextInfo:NULL];
						}];
}
#else
- (IBAction) saveUsingBlock:(id)sender
{
	NSLog(@"Blocks unavailable!");
}
#endif 
	 
- (void)savePanelDidEnd:(JAMultiTypeSavePanelController *)sheetController returnCode:(NSInteger)returnCode contextInfo:(void *)contextInfo
{
	
	NSLog(@"Save panel result: %ld", (long)returnCode);
	[sheetController.savePanel orderOut:nil];
	
	if (returnCode == NSOKButton)
	{
		NSError *error = nil;
		
		NSString *typeName = sheetController.selectedUTI;
		NSLog(@"Saving as %@", typeName);
		
		NSTextStorage *textStorage = textView.textStorage;
		
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
		NSURL *fileURL = sheetController.savePanel.URL;
#else
		NSString *path = sheetController.savePanel.filename;
#endif
        
		NSFileWrapper *wrapper = [textStorage fileWrapperForUTI:typeName error:&error];
		
		BOOL OK = (wrapper != nil);
		
		if (OK)
		{
#if (MAC_OS_X_VERSION_MIN_REQUIRED >= 1060)
			OK = [wrapper writeToURL:fileURL 
							 options:(NSFileWrapperWritingAtomic | NSFileWrapperWritingWithNameUpdating) 
				 originalContentsURL:nil 
							   error:&error];
#else
			OK = [wrapper writeToFile:path atomically:YES updateFilenames:YES];
#endif
		}
		
		if (!OK)
		{
			[[NSAlert alertWithError:error] beginSheetModalForWindow:window
													   modalDelegate:nil
													  didEndSelector:NULL
														 contextInfo:nil];
		}
		
	}
}

@end
