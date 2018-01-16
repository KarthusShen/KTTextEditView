//
//  KTTextEditView.h
//  KTTextEditView
//
//  Created by Karthus on 2018/1/9.
//  Copyright © 2018年 karthus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol KTTextEditViewDelegate;

typedef enum : NSUInteger
{
    action_Enter = 0,
    action_CommandEnter = 1
}KTTextEditViewSendAction;

@interface KTTextEditView : NSTextView <NSTextViewDelegate>

@property (nullable, weak) id<KTTextEditViewDelegate> kt_delegate;
@property (nonatomic, assign)KTTextEditViewSendAction sendActionType;
- (void)kt_setDelegate:(_Nullable id <KTTextEditViewDelegate>)delegate;
- (void)kt_setSendAction:(KTTextEditViewSendAction)action;

@end



@protocol KTTextEditViewDelegate <NSObject>
@optional
/**
 When the KTTExtEditView import a non-image file (by means of copy-pauste or drag-and-drop etc.),
 notify the delegate what the filepath is.
 */
- (void)textEditView:(KTTextEditView *_Nullable)textView didImportNonImageFile:(NSString *_Nullable)filePath;

- (void)performSendAction;
@end
