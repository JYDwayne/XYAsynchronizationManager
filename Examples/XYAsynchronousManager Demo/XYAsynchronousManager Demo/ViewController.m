//
//  ViewController.m
//  XYAsynchronousManager Demo
//
//  Created by xuyang on 2017/3/29.
//  Copyright © 2017年 SeanXuCn. All rights reserved.
//

#import "ViewController.h"
#import "XYAsynchronousManager.h"

@interface ViewController ()<UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, weak) IBOutlet UITableView *tableView;
@property (nonatomic, copy) NSMutableArray *taskArray;
@property (nonatomic, strong) NSArray *listSourceArray;

//isRunning只是为了Demo演示的时候将各项演示区分开,当你实际使用时完全无需添加这个变量
@property (nonatomic, assign) BOOL isRunning;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.tableView.rowHeight = 50.f;
    [self.tableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
}

#pragma mark - actions

- (void)OneGroupConcurrence{
    if (self.isRunning) return;
    self.isRunning = YES;
    
    //1、设置总并发数量，并给这组并发设置一个唯一id
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"oneGroup" totalCount:self.taskArray.count doneBlock:^{
        XYAM_Log(@"oneGroup Tasks Done!");
        self.isRunning = NO;
    }];
    
    [self.taskArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            XYAM_Log(@"Task %@ executed", obj);
            
            //2、当你完成一步操作的时候，告知manager你完成了一步操作，你可以完全不考虑当前是在什么线程内，只需要直接调用即可。
            [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"oneGroup"];
        });
    }];
}

- (void)TwoGroupConcurrence{
    if (self.isRunning) return;
    self.isRunning = YES;
    //1、设置第一组总并发数量，并给这组并发设置一个唯一id
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"groupOne" totalCount:self.taskArray.count doneBlock:^{
        XYAM_Log(@"groupOne Tasks Done!");
        self.isRunning = NO;
    }];
    
    //2、设置第二组总并发数量，并给这组并发设置一个唯一id
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"groupTwo" totalCount:self.taskArray.count doneBlock:^{
        XYAM_Log(@"groupTwo Tasks Done!");
        self.isRunning = NO;
    }];
    
    //3、开始第一组任务
    [self.taskArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            XYAM_Log(@"groupOne Task %@ executed", obj);
            
            //2、当你完成一步操作的时候，告知manager你完成了一步操作，你可以完全不考虑当前是在什么线程内，只需要直接调用即可。
            [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupOne"];
        });
    }];
    
    //4、开始第二组任务
    [self.taskArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            XYAM_Log(@"groupTwo Task %@ executed", obj);
            
            //2、当你完成一步操作的时候，告知manager你完成了一步操作，你可以完全不考虑当前是在什么线程内，只需要直接调用即可。
            [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupTwo"];
        });
    }];
    
    /**
     本例中：1、2、3、4的顺序也可以改成1、3、2、4或者是其他组合。
     只要保证先使用id和数量创建同步管理器(synchronizer)，再开始执行就没问题。
     */
}

- (void)ThreeGroupsConcurrenceAndDependence{
    if (self.isRunning) return;
    self.isRunning = YES;
    
    /** 1、设置第三组总并发数量，并给这组并发设置一个唯一id
     *  这个组里只有两个步骤，第一个步骤是第一组完成，第二个步骤是第二组完成。
     */
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"groupThree" totalCount:2 doneBlock:^{
        
        //组1和组2都完成了
        XYAM_Log(@"groupThree Tasks Done!");
        self.isRunning = NO;
    }];
    
    //2、设置第一组总并发数量，并给这组并发设置一个唯一id
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"groupOne" totalCount:self.taskArray.count doneBlock:^{
        XYAM_Log(@"groupOne Tasks Done!");
        
        //当你完成一步操作的时候，告知manager你完成了一步操作，你可以完全不考虑当前是在什么线程内，只需要直接调用即可。
        [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupThree"];
    }];
    
    //3、设置第二组总并发数量，并给这组并发设置一个唯一id
    [[XYAsynchronousManager sharedManager] xy_synchronizeWithIdentifier:@"groupTwo" totalCount:self.taskArray.count doneBlock:^{
        XYAM_Log(@"groupTwo Tasks Done!");
        
        //当你完成一步操作的时候，告知manager你完成了一步操作，你可以完全不考虑当前是在什么线程内，只需要直接调用即可。
        [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupThree"];
    }];
    
    
    
    //开始执行组一
    [self.taskArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            XYAM_Log(@"groupOne Task %@ executed", obj);
            
            [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupOne"];
        });
    }];
    
    //开始执行组二
    [self.taskArray enumerateObjectsWithOptions:NSEnumerationConcurrent usingBlock:^(id  _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        dispatch_async(dispatch_get_global_queue(0, 0), ^{
            XYAM_Log(@"groupTwo Task %@ executed", obj);
            
            [[XYAsynchronousManager sharedManager] xy_synchronizeOneStepByIdentifier:@"groupTwo"];
        });
    }];
}

#pragma mark - tableView
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView{
    return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return [self.listSourceArray count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    static NSString *cellId = @"cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellId forIndexPath:indexPath];
    cell.textLabel.text = [self.listSourceArray objectAtIndex:indexPath.row];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    switch (indexPath.row) {
        case 0:
            [self OneGroupConcurrence];
            break;
        case 1:
            [self TwoGroupConcurrence];
            break;
        case 2:
            [self ThreeGroupsConcurrenceAndDependence];
            break;
        default:
            break;
    }
}


#pragma mark - lazy
- (NSMutableArray *)taskArray{
    if (nil == _taskArray) {
        _taskArray = [NSMutableArray arrayWithCapacity:200];
        for (int i = 0; i < 100; i++) {
            [_taskArray addObject:@(i)];
        }
    }
    return _taskArray;
}

- (NSArray *)listSourceArray{
    if (nil == _listSourceArray) {
        _listSourceArray = @[@"并发一组异步操作,完成后回调",@"同时并发两组异步操作,互不影响,完成后回调",@"先同时并发两组操作,完成后执行第三组操作",@"请在控制台查看输出的结果"];
    }
    return _listSourceArray;
}
@end
