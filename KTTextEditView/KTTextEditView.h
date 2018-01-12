//
//  KTTextEditView.h
//  KTTextEditView
//
//  Created by Karthus on 2018/1/9.
//  Copyright © 2018年 karthus. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@protocol KTTextEditViewDelegate;

@interface KTTextEditView : NSTextView <NSTextViewDelegate>

@property (nullable, weak) id<KTTextEditViewDelegate> kt_delegate;

- (void)kt_setDelegate:(_Nullable id <KTTextEditViewDelegate>)delegate;

@end


@protocol KTTextEditViewDelegate <NSObject>
@optional
- (void)textEditView:(KTTextEditView *_Nullable)textView didImportFile:(NSString *_Nullable)filePath;
@end
