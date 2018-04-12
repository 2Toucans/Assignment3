//
//  ModelReader.h
//  Assignment2
//
//  Created by Aaron Freytag on 2018-04-04.
//  Copyright © 2018 2Toucans. All rights reserved.
//

#ifndef ModelReader_h
#define ModelReader_h
#import <Foundation/Foundation.h>
#include "Model.h"

@interface ModelReader : NSObject

+ (Model*) loadModel: (NSString*)res;

@end

#endif /* ModelReader_h */
