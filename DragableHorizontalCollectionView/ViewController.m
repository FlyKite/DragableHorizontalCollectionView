//
//  ViewController.m
//  DragableHorizontalCollectionView
//
//  Created by FlyKite on 16/4/6.
//  Copyright © 2016年 FlyKite. All rights reserved.
//

#import "ViewController.h"

#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height

@interface ViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout>
@property (strong, nonatomic) UICollectionView *collectionView;
@property (strong, nonatomic) NSMutableArray *dataArray;
@property (strong, nonatomic) UICollectionViewCell *movingCell;
@property (assign, nonatomic) CGPoint offsetInMovingCell;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    self.dataArray = [NSMutableArray array];
    // 这里生成个数组，可以自己改一下个数试试
    int count = 7;
    for (int i = 0; i < count; i++) {
        [self.dataArray addObject:[NSString stringWithFormat:@"%d", i]];
    }
    [self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"cell"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - 水平排列
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    NSInteger count = self.dataArray.count;
    count += 2 * (self.dataArray.count / 6);
    count += self.dataArray.count % 6 == 0 ? 2 : 4 + (6 - self.dataArray.count % 6);
    return count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"cell" forIndexPath:indexPath];
    cell.backgroundColor = [UIColor lightGrayColor];
    UILabel *label = [cell viewWithTag:0x1234];
    if (!label) {
        label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height)];
        label.textAlignment = NSTextAlignmentCenter;
        label.tag = 0x1234;
        [cell addSubview:label];
        
        // 添加pan手势
        UIPanGestureRecognizer *pan = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(dealPan:)];
        [cell addGestureRecognizer:pan];
    }
    // 计算水平排列的真实位置
    NSInteger realItem = indexPath.item - 2;
    realItem -= realItem / 8 * 2;
    if (realItem % 2 == 0) {
        realItem = realItem - realItem % 6 + realItem % 6 / 2;
    } else {
        realItem = realItem - realItem % 6 + realItem % 6 / 2 + 3;
    }
    // 设置文本
    if (realItem < self.dataArray.count) {
        cell.alpha = 1;
        label.text = self.dataArray[realItem];
        cell.userInteractionEnabled = YES;
    } else {
        // 用半透明来表示这个是一个空的格子，并且关闭交互
        cell.alpha = 0.5;
        cell.userInteractionEnabled = NO;
    }
    return cell;
}

- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
    // 返回item的大小，其实这里一屏放了8个Cell
    if ((indexPath.item / 2) % 4 == 0) {
        return CGSizeMake(0, ScreenWidth / 3 - 20);
    }
    return CGSizeMake(ScreenWidth / 3 - 20, ScreenWidth / 3 - 20);
}

#pragma mark - 拖拽排序
- (void)dealPan:(UIPanGestureRecognizer *)pan {
    if (pan.state == UIGestureRecognizerStateBegan) {
        // 开始拖拽时将Cell复制一份并隐藏原Cell
        UICollectionViewCell *cell = (UICollectionViewCell *)pan.view;
        cell.hidden = YES;
        CGRect frame = [self.collectionView convertRect:cell.bounds fromView:cell];
        UICollectionViewCell *newCell = [[UICollectionViewCell alloc] initWithFrame:frame];
        newCell.backgroundColor = cell.backgroundColor;
        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, cell.bounds.size.width, cell.bounds.size.height)];
        label.textAlignment = NSTextAlignmentCenter;
        label.text = ((UILabel *)[cell viewWithTag:0x1234]).text;
        [newCell addSubview:label];
        
        [self.collectionView addSubview:newCell];
        self.movingCell = newCell;
        // 记录开始移动时手指所在的点相对于Cell的中心点的偏移量
        CGPoint location = [pan locationInView:cell];
        self.offsetInMovingCell = CGPointMake(location.x - cell.bounds.size.width / 2, location.y - cell.bounds.size.height / 2);
    } else if (pan.state == UIGestureRecognizerStateChanged) {
        // 移动Cell
        CGPoint location = [pan locationInView:self.collectionView];
        CGPoint locationInScreen = [pan locationInView:self.view];
        self.movingCell.center = CGPointMake(location.x - self.offsetInMovingCell.x, location.y - self.offsetInMovingCell.y);
        // 计算手指是否移动到了另一个Cell内
        NSInteger width = pan.view.bounds.size.width;
        NSInteger height = pan.view.bounds.size.height;
        if (location.y >= 0 && location.y <= self.collectionView.bounds.size.height) {
            // 在CollectionView内部时再去判断是否移动到另一个Cell内
            if ((NSInteger)locationInScreen.x % (width + 15) >= 15 && (NSInteger)location.y % (height + 15) <= height) {
                // 移动到了某个Cell内，计算这个Cell的Index
                CGRect oldFrame = [self.collectionView convertRect:pan.view.bounds fromView:pan.view];
                NSInteger newIndex = (NSInteger)location.y / (height + 15) * 3 + (NSInteger)location.x / (width + 15);
                NSInteger oldIndex = (NSInteger)oldFrame.origin.y / (height + 15) * 3 + (NSInteger)oldFrame.origin.x / (width + 15);
                if (newIndex < self.dataArray.count && newIndex != oldIndex) {
                    NSLog(@"from %ld to %ld", oldIndex, newIndex);
                    [self moveCellFrom:oldIndex to:newIndex];
                }
            }
        }
    } else if (pan.state == UIGestureRecognizerStateEnded) {
        // 松开手指则将复制的Cell移动到原Cell的位置并隐藏，同时将原Cell显示
        [UIView animateWithDuration:0.3 animations:^{
            CGPoint center = CGPointMake(pan.view.bounds.size.width / 2, pan.view.bounds.size.height / 2);
            self.movingCell.center = [self.collectionView convertPoint:center fromView:pan.view];
        } completion:^(BOOL finished) {
            pan.view.hidden = NO;
            [self.movingCell removeFromSuperview];
            self.movingCell = nil;
        }];
    }
}

// 移动Cell
- (void)moveCellFrom:(NSInteger)oldIndex to:(NSInteger)newIndex {
    // 移动到了另一个Cell内，移动Cell的位置
    if (newIndex % 6 / 3 == oldIndex % 6 / 3) {
        // 交换的两个cell在同一行内
        if (newIndex < oldIndex) {
            // 从右往左移动
            for (NSInteger i = oldIndex - 1; i >= newIndex; i--) {
                NSIndexPath *newIndexPath = [self getIndexPathByRealItem:i];
                NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item + 1 inSection:0];
                [self.collectionView moveItemAtIndexPath:newIndexPath toIndexPath:oldIndexPath];
            }
        } else {
            // 从左往右移动
            for (NSInteger i = oldIndex + 1; i <= newIndex; i++) {
                NSIndexPath *newIndexPath = [self getIndexPathByRealItem:i];
                NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item - 1 inSection:0];
                [self.collectionView moveItemAtIndexPath:newIndexPath toIndexPath:oldIndexPath];
            }
        }
        NSIndexPath *newIndexPath = [self getIndexPathByRealItem:oldIndex];
        NSIndexPath *oldIndexPath = [self getIndexPathByRealItem:newIndex];
        [self.collectionView moveItemAtIndexPath:newIndexPath toIndexPath:oldIndexPath];
    } else {
        // 要交换的两个cell不在同一行
        if (newIndex < oldIndex) {
            // 从第二行移动到第一行
            // 移动规则：旧位置先移动到位置5，然后与位置2交换，随后移动到新位置，之后的位置5与位置3交换
            if (oldIndex != 5) {
                [self moveCellFrom:oldIndex to:5];
            }
            NSIndexPath *newIndexPath = [self getIndexPathByRealItem:oldIndex - oldIndex % 6 + 5]; // 位置5
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item - 1 inSection:0]; // 位置2
            [self.collectionView moveItemAtIndexPath:newIndexPath toIndexPath:oldIndexPath];
            [self moveCellFrom:5 to:3];
            [self moveCellFrom:2 to:newIndex];
        } else {
            // 从第一行移动到第二行
            // 移动规则：旧位置先移动到位置0，然后与位置3交换，随后移动到新位置，之后的位置0与位置2交换
            if (oldIndex != 0) {
                [self moveCellFrom:oldIndex to:0];
            }
            NSIndexPath *newIndexPath = [self getIndexPathByRealItem:oldIndex - oldIndex % 6]; // 位置0
            NSIndexPath *oldIndexPath = [NSIndexPath indexPathForItem:newIndexPath.item + 1 inSection:0]; // 位置3
            [self.collectionView moveItemAtIndexPath:newIndexPath toIndexPath:oldIndexPath];
            [self moveCellFrom:0 to:2];
            [self moveCellFrom:3 to:newIndex];
        }
    }
}

- (NSIndexPath *)getIndexPathByRealItem:(NSInteger)realItem {
    if (realItem % 6 / 3 == 0) {
        // 第一行
        realItem = realItem - realItem % 6 + realItem % 3 * 2;
    } else {
        // 第二行
        realItem = realItem - realItem % 6 + realItem % 3 * 2 + 1;
    }
    realItem += realItem / 6 * 2;
    realItem += 2;
    //    NSLog(@"%ld", realItem);
    return [NSIndexPath indexPathForItem:realItem inSection:0];
}

- (UICollectionView *)collectionView {
    if (!_collectionView) {
        UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
        layout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
        layout.minimumLineSpacing = 15;
        layout.minimumInteritemSpacing = 15;
        
        _collectionView = [[UICollectionView alloc] initWithFrame:CGRectMake(0, 100, ScreenWidth, (ScreenWidth / 3 - 20) * 2 + 15) collectionViewLayout:layout];
        _collectionView.backgroundColor = [UIColor cyanColor];
        _collectionView.delegate = self;
        _collectionView.dataSource = self;
        _collectionView.pagingEnabled = YES;
        [self.view addSubview:_collectionView];
    }
    return _collectionView;
}

@end
