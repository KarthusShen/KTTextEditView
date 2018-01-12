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
    [self registerForDraggedTypes:[NSAttributedString textTypes]];
    [self setDelegate:self];
}

- (void)kt_setDelegate:(_Nullable id <KTTextEditViewDelegate>)delegate
{
    _kt_delegate = delegate;
}

#pragma mark - override super functions
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
                NSString *pathExtension = [filePath pathExtension];
                
                if ([pathExtension isEqualToString:@"png"] || [pathExtension isEqualToString:@"jpg"] ||
                    [pathExtension isEqualToString:@"jpeg"] || [pathExtension isEqualToString:@"gif"]||
                    [pathExtension isEqualToString:@"bitmap"])
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
                    if ([_kt_delegate respondsToSelector:@selector(textEditView:didImportFile:)])
                    {
                        [_kt_delegate textEditView:self didImportFile:filePath];
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
                NSTextAttachmentCell *attachmentCell = [[NSTextAttachmentCell alloc] initImageCell:image];
                NSTextAttachment *attachment = [[NSTextAttachment alloc] init];
                [attachment setAttachmentCell: attachmentCell ];
                NSAttributedString *attributedString = [NSAttributedString  attributedStringWithAttachment: attachment];
                [self.textStorage appendAttributedString:attributedString];
            }
        }
    }
    else
    {
        [super paste:sender];
    }
}

#pragma mark - NSTextViewDelegate

- (BOOL)textView:(NSTextView *)textView doCommandBySelector:(SEL)commandSelector
{
    if(textView == self)
    {
        //it means user pressed the enter key in the inputTextView
        if (commandSelector == @selector(insertNewline:))
        {
            //TODO: Gather contents that user inputed.
            return YES;
        }
        
    }
    return NO;
}



@end
