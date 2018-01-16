//
//  KTTextEditView.m
//  KTTextEditView
//
//  Created by Karthus on 2018/1/9.
//  Copyright © 2018年 karthus. All rights reserved.
//

#import "KTTextEditView.h"
@protocol KTTextEditViewDelegate;

@implementation KTTextEditView


# pragma mark - Initialize and setup
- (instancetype)initWithFrame:(NSRect)frameRect textContainer:(NSTextContainer *)container
{
    self = [super initWithFrame:frameRect textContainer:container];
    if (self)
    {
        [self setupKTTextEditView];
    }
    return self;
}

- (instancetype)initWithFrame:(NSRect)frameRect
{
    self = [super initWithFrame:frameRect];
    if (self)
    {
        [self setupKTTextEditView];
    }
    return self;
}

- (void)awakeFromNib
{
    [super awakeFromNib];
    [self setupKTTextEditView];
}

- (void)setupKTTextEditView
{
    self.allowsUndo = YES;
    self.editable = YES;
    self.selectable = YES;
    self.continuousSpellCheckingEnabled = NO;
    self.richText = NO;
    self.importsGraphics = NO;
    self.allowsImageEditing = NO;
    
    [self registerForDraggedTypes:[NSImage imageTypes]];
    [self registerForDraggedTypes:[NSArray arrayWithObject:NSPasteboardTypeFileURL]];
    [self setDelegate:self];
    
    self.sendActionType = action_Enter;
}

- (void)kt_setDelegate:(_Nullable id <KTTextEditViewDelegate>)delegate
{
    _kt_delegate = delegate;
}

- (void)kt_setSendAction:(KTTextEditViewSendAction)action
{
    _sendActionType = action;
}

#pragma mark - override functions
- (void)paste:(id)sender
{
    NSPasteboard *pasteboard = [NSPasteboard generalPasteboard];
    NSLog(@"pasteboard types: %@", [pasteboard types]);
   
    //file-url check options
    NSArray *urlClasses = [NSArray arrayWithObject:[NSURL class]];
    NSDictionary *fileURLOptions = [NSDictionary dictionaryWithObject:
                             [NSNumber numberWithBool:YES] forKey:NSPasteboardURLReadingFileURLsOnlyKey];
    
    //image check options
    NSArray *imageClasses = [NSArray arrayWithObject:[NSImage class]];
    NSDictionary *imageOptions = [NSDictionary dictionary];
    
    if ([pasteboard canReadObjectForClasses:urlClasses options:fileURLOptions])
    {
        NSLog(@"There's a file in pasteboard");
        NSArray *fileURLs = [pasteboard readObjectsForClasses:urlClasses options:fileURLOptions];
        if (fileURLs != nil)
        {
            for(NSURL *url in fileURLs)
            {
                NSString *filePath = [url path];
                if ([self fileIsImageFile:filePath])
                {
                    //This file is an image, import it to the textview as a 'NSTextAttachment'.
                    NSError *error = nil;
                    NSFileWrapper *fileWrapper = [[NSFileWrapper alloc] initWithURL:url options:NSFileWrapperReadingImmediate error:&error];
                    if(error)
                    {
                        NSLog(@"create fileWrapper error at: %@, error:%@", filePath, error);
                        continue;
                    }
                    NSTextAttachment *attachment = [[NSTextAttachment alloc] initWithFileWrapper:fileWrapper];
                    NSAttributedString *attString = [NSAttributedString attributedStringWithAttachment:attachment];
                    [self.textStorage appendAttributedString:attString];
                }
                else
                {
                    //This file is not an image, notify the filepath through 'KTTextEditViewDelegate'.
                    NSLog(@"import a non-image file,path:%@", filePath);
                    if ([_kt_delegate respondsToSelector:@selector(textEditView:didImportNonImageFile:)])
                    {
                        [_kt_delegate textEditView:self didImportNonImageFile:filePath];
                    }
                }
            }
        }
    }
    else if ([pasteboard canReadObjectForClasses:imageClasses options:imageOptions])
    {
        NSLog(@"There‘s a item in pasteboard that can convert to an image");
        NSArray *items = [pasteboard readObjectsForClasses:imageClasses options:imageOptions];
        if (items != nil)
        {
            for(NSImage *image in items)
            {
                [self appendImageAttachment:image];
            }
        }
    }
    else
    {
        [super paste:sender];
    }
}

#pragma mark private functions
- (void)appendImageAttachment: (NSImage *)image
{
    if (image == nil)
    {
        return;
    }
    NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:image];
    NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
    [attachment setAttachmentCell: attachmentCell];
    NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
    [self.textStorage appendAttributedString:attributedString];
}

- (void)clearContents
{
    [self replaceCharactersInRange:NSMakeRange(0, self.textStorage.length) withString:@""];
}

- (BOOL)fileIsImageFile: (NSString*)filePath
{
    NSString *pathExtension = [filePath pathExtension];
    
    if ([pathExtension isEqualToString:@"png"] || [pathExtension isEqualToString:@"jpg"] ||
        [pathExtension isEqualToString:@"jpeg"] || [pathExtension isEqualToString:@"gif"]||
        [pathExtension isEqualToString:@"bitmap"])
    {
        return YES;
    }
    else
    {
        return NO;
    }
}

#pragma mark - NSDraggingDestnation

- (BOOL)performDragOperation:(id <NSDraggingInfo>)sender
{
    NSLog(@"performDragOperation.");
    
    NSPasteboard *pboard = [sender draggingPasteboard];
    if ( [[pboard types] containsObject:NSFilenamesPboardType] )
    {
        //The dragging sources are files
        NSArray *files = [pboard propertyListForType:NSFilenamesPboardType];
        if(files != nil)
        {
            for(NSString* path in files)
            {
                if ([self fileIsImageFile:path])
                {
                    NSImage *image = [[NSImage alloc]initWithContentsOfFile:path];
                    [self appendImageAttachment:image];
                }
                else
                {
                    //This file is not an image, notify the filepath through 'KTTextEditViewDelegate'.
                    NSLog(@"import a non-image file,path:%@", path);
                    if ([_kt_delegate respondsToSelector:@selector(textEditView:didImportNonImageFile:)])
                    {
                        [_kt_delegate textEditView:self didImportNonImageFile:path];
                    }
                }
            }
        }
    }
    else if ([NSImage canInitWithPasteboard: pboard])
    {
        //The draggin sources are not files, but maybe something can representation as image
        NSImage *image = [[NSImage alloc] initWithPasteboard: pboard];
        [self appendImageAttachment:image];
    }
    else
    {
        return [super performDragOperation:sender];
    }
    return YES;
}


#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if(textView == self)
    {
        //it means user pressed the enter key in the inputTextView
        if (commandSelector == @selector(insertNewline:) && self.sendActionType == action_Enter)
        {
            if([_kt_delegate respondsToSelector:@selector(performSendAction)])
            {
                [_kt_delegate performSendAction];
            }
            return YES;
        }
        else if (commandSelector == @selector(noop:) && self.sendActionType == action_CommandEnter)
        {
            if([_kt_delegate respondsToSelector:@selector(performSendAction)])
            {
                [_kt_delegate performSendAction];
            }
            return YES;
        }
        else
        {
            return NO;
        }
    }
    return NO;
}





@end
