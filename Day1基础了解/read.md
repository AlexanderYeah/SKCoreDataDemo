# 基本介绍
[参考资料1](https://www.jianshu.com/p/d5030eb30562)    
[参考资料2](https://www.jianshu.com/p/9f1828d49cf5)  



## 增删改查

```//
//  ViewController.m
//  TestDemo
//
//  Created by Alexander on 2018/6/12.
//  Copyright © 2018年 alexander. All rights reserved.
//

#import "ViewController.h"
#import "Student+CoreDataClass.h"
@interface ViewController ()

// 创建数据模型
@property (nonatomic,readwrite,strong)NSManagedObjectModel *mgrModel;


// 协调器
@property (nonatomic,readwrite,strong)NSPersistentStoreCoordinator *coord;

// 上下文
@property (nonatomic,strong)NSManagedObjectContext *context;



@end

@implementation ViewController

// 懒加载形式加载coredata
- (NSManagedObjectModel *)mgrModel
{
	if (!_mgrModel) {
	   // 在此处创建模型的时候 连接上对应的表
	   // 注意扩展名为 momd，而不是 xcdatamodeld 类型
	  NSURL *url = [[NSBundle mainBundle]URLForResource:@"TestDemo" withExtension:@"momd"];
	  _mgrModel = [[NSManagedObjectModel alloc]initWithContentsOfURL:url];
		
	};
	return _mgrModel;
}

// 懒加载协调器
- (NSPersistentStoreCoordinator *)coord
{
	if (!_coord) {
		_coord = [[NSPersistentStoreCoordinator alloc]initWithManagedObjectModel:self.mgrModel];
		NSURL *url = [[self documentDirectoryURL] URLByAppendingPathComponent:@"TestDemo.sqlite"];
		
		NSError *error;
		[_coord addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:url options:nil error:&error];
		
		if (error) {
			NSLog(@"创建协调器的时候有错误");
		}
	}
	return _coord;
	
}

// 懒加载上下文
- (NSManagedObjectContext *)context
{
	if (!_context) {
		_context  = [[NSManagedObjectContext alloc]initWithConcurrencyType:NSMainQueueConcurrencyType];
		// 绑定数据库
		_context.persistentStoreCoordinator = self.coord;
	};
	return _context;

}

// 用来获取 document 目录
- (nullable NSURL *)documentDirectoryURL {
    return [[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask].firstObject;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
	[self updateBatchData];
	
}
// 1 插入数据
- (void)insertDataWithName:(NSString *)name age:(NSInteger)age
{
	Student *stu = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:self.context];
	stu.name = name;
	stu.age = age;
	
	// 进行保存
	NSError *error;
	[self.context save:&error];
	
	if (error) {
		NSLog(@"插入数据出错");
	}else{
		NSLog(@"插入数据成功");
	}
	
}


// 2 查询数据
/**
	从数据库查询数据会用到三个类
	1 --> NSFetchRequest 查询请求
	2 --> NSPredicate 谓词 筛选条件
	3 --> NSSortDescriptor 排序规则  相当于 ORDERBY
*/
- (void)queryData
{
	// 实例查询请求
	NSFetchRequest *fetchReq = [[NSFetchRequest alloc]init];
	// 哪一张表
	NSEntityDescription *entry = [NSEntityDescription entityForName:@"Student" inManagedObjectContext:self.context];
	// 谓词
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age > %@",@(10)];
	// 设置筛选条件
	fetchReq.predicate = predicate;
	// 设置排序方式
	NSArray *sortsArr = @[ [NSSortDescriptor sortDescriptorWithKey:@"age" ascending:YES]];
	
	fetchReq.sortDescriptors = sortsArr;
	
	[fetchReq setEntity:entry];
	
	// 执行查询操作
	NSError *error;
	NSArray<Student *> *stus = [self.context executeFetchRequest:fetchReq error:&error];
	
	NSLog(@"%@",stus);
	
	for (Student *stu in stus) {
		
		// 删除比较简单 就是调用delete 方法
//		if (stu.age < 20) {
//			// 删除掉item
//			[self.context deleteObject:stu];
//			// 保存操作
//			[self.context save:nil];
//		}
//
//
//		// 更新数据  就是遍历数据 进行修改
//		if ([stu.name isEqualToString:@"kkk"]) {
//			stu.name = @"WonderBoy";
//		}
		
		NSLog(@"name--%@ age--%ld",stu.name,stu.age);
	}
	
}



// 3 批量插入数据
- (void)insertBulkData
{
	for (int i = 0 ; i < 20; i ++) {
		Student * stu = [NSEntityDescription insertNewObjectForEntityForName:@"Student" inManagedObjectContext:self.context];
		int16_t stuID = arc4random_uniform(9999);
		stu.name = [NSString stringWithFormat:@"stu--%d",stuID];
		stu.age = arc4random_uniform(20) + 10;		
	}
	// 进行保存
	[self.context save:nil];
}



// 4 批量更新数据
/**
	NSBatchUpdateRequest 是不加载到内存中直接操作本地数据库进行更新,这就避免了内存不足的问题。
*/
- (void)updateBatchData
{
	// 1 创建跟新请求
	NSBatchUpdateRequest *req = [[NSBatchUpdateRequest alloc]initWithEntity:[Student entity]];
	
	// 2 predicate 谓词 指定条件
	NSPredicate *predicate = [NSPredicate predicateWithFormat:@"age > %@",@(20)];
	req.predicate = predicate;
	// 3 更新字段 key 是要更新的值 value 是目标更新的值
	// req.propertiesToUpdate = @{@"name":@"stu_name"};
	// 4 resultType 返回的数据类型
	// NSStatusOnlyResultType Bool 值
	// NSUpdatedObjectIDsResultType 返回更新成功的ID
	// NSUpdatedObjectsCountResultType 更新成功的总数
	
	req.resultType = NSUpdatedObjectIDsResultType;
	
	// 5 执行请求
	NSBatchUpdateResult *updateRes = [self.context executeRequest:req error:nil];
	NSArray<NSManagedObjectID *> *updatesIDs = updateRes.result;
	
	// 6 数据库的更新完毕之后 通知内存中的数据更新数据
	NSDictionary *updatedDict = @{NSUpdatedObjectsKey : updatesIDs};
	[NSManagedObjectContext mergeChangesFromRemoteContextSave:updatedDict intoContexts:@[self.context]];
	
}


- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}


@end
```
