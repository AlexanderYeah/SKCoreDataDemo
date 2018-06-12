//
//  Student+CoreDataProperties.m
//  SKCodeDataDemo
//
//  Created by Alexander on 2018/6/12.
//  Copyright © 2018年 alexander. All rights reserved.
//
//

#import "Student+CoreDataProperties.h"

@implementation Student (CoreDataProperties)

+ (NSFetchRequest<Student *> *)fetchRequest {
	return [[NSFetchRequest alloc] initWithEntityName:@"Student"];
}

@dynamic name;
@dynamic age;
@dynamic sex;

@end
