//
//  SearchResult.m
//  StoreSearch
//
//  Created by Nguyen Duy Khanh on 3/18/16.
//  Copyright © 2016 Nguyen Duy Khanh. All rights reserved.
//

#import "SearchResult.h"

@implementation SearchResult

-(NSComparisonResult)compareName:(SearchResult*)other;
{
    return [self.name localizedStandardCompare:other.name];
}
@end
