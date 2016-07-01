/*
 * Copyright (c) Microsoft Corporation. All rights reserved.
 */

#ifndef AVAConstants_Internal_h
#define AVAConstants_Internal_h

// API Error
static NSString* const kAVADefaultApiErrorDomain = @"AVADefaultApiErrorDomain";
static NSInteger const kAVADefaultApiMissingParamErrorCode = 234513;
static NSInteger const kAVAHttpErrorCodeMissingParameter = 422;



typedef NS_ENUM(NSInteger, AVASendPriority) {
  AVASendPriorityDefault,
  AVASendPriorityHight,
  AVASendPriorityBackground
};

#endif /* AVAConstants_Internal_h */