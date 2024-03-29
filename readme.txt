/*-----------------------------运行速度----------------------------------*/
数据读取速度:10s数据1.2s
接收机运行速度:4颗卫星10s数据16s

/*-----------------------------注释规范----------------------------------*/
1.所有标点符号使用英文标点符号
2.脚本文件代码段的注释以.结尾,因为发布时标题下面的多行注释会连城一行
3.要保证发布时格式美观

/*--------------------------文件夹命名规则-------------------------------*/
以.开头的文件夹是测试用的,与功能无关,只有使用时才加入搜索路径

/*---------------------------变量命名规则--------------------------------*/
k,i:做循环计数
n:数据点数
svN:卫星数
rp:接收机ecef位置
vp:接收机ecef速度
rs:卫星ecef位置
vs:卫星ecef速度

/*---------------------------卫星系统代号--------------------------------*/
G(GPS),R(GLONASS),E(Galileo),C(BDS),J(QZSS),I(IRNSS),参见RINEX 3.03

/*-------------------------卫星测量值修正符号-----------------------------*/
卫星钟差/钟频差对伪距/伪距率的修正是+
接收机钟差/钟频差对伪距/伪距率的修正是-
延迟项对伪距的修正是-

/*-----------------------------编程技巧----------------------------------*/
1.norm(a)比sqrt(a*a')快
2.cos比cospi快,cospi比cos精确
3.修改一行或一列向量中一段的数值时,所提供的数不必特意转成行或者列
4.sscanf比str2num快
5.使用索引直接扩展向量长度时,默认是行
6.ones(8,1)*x比repmat(x,8,1)快
7.矩阵各行取模,当行数小于50时,vecnorm(a,2,2)比sum(a.*a,2).^0.5快
8.主函数只写流程,跟算法相关的全部封装,要么是单独的函数文件,要么是嵌套函数
9.[0,0,0,0]比zeros(1,4)快
10.使用q/norm(q)代替quatnormalize
11.生成一个随机数时,randn比randn(1)快
12.矩阵索引,(1+1:5000+1)比(1+(1:5000))快
13.向量乘一个数比除一个数快
14.sum(a)/length(a)算均值比mean快
15.读文件,空行读到一个空字符矩阵,读到文件尾,返回-1(double)

/*-----------------------------更新日志----------------------------------*/
<===Version 1.0===> 2020.2.18
1.建立软件架构
2.实现GPS单天线L1CA接收机,具备捕获跟踪功能
3.添加GPS历书星历下载
4.添加BDS星历下载
5.添加RINEX 2 GPS星历文件读取

<===Version 1.1===> 2020.2.22
使用结构体配置接收机和跟踪通道

<===Version 1.2===> 2020.2.23
1.添加RINEX 3.03 BDS星历文件读取
2.添加画北斗星座图
3.星座图添加滑动条功能,调整高度角显示范围,看清重叠的卫星

<===Version 1.3===> 2020.2.26
1.复杂流程使用嵌套函数
2.为GPS单天线L1CA接收机添加定位功能

<===Version 1.4===>2020.2.27
1.FLL,PLL,DLL不用结构体,使用向量,用于加速
2.删除roundWeek,用于加速
3.添加卫星加速度计算
4.添加载波频率变化率前馈

<===Version 1.5===>2020.2.28
1.计算各卫星伪距伪距率残差
2.将接收机类从一个文件拆成文件夹

<===Version 1.6===>2020.3.1
1.整理代码注释,使代码可以发布
2.简化卫星方位角高度角计算程序
3.接收机运行后可以计算卫星的方位角高度角
4.接收机运行后可以计算电离层校正值

<===Version 1.7===>2020.3.5
1.添加静态惯导滤波测试,验证状态约束卡尔曼滤波的效果
2.添加卫星3D显示
3.添加所有GPS卫星捕获画图

<===Version 1.8===>2020.3.5
1.重写姿态角,姿态阵,四元数之间的相互变换,为了加速(只能处理一个数据)
2.重写四元数乘法

<===Version 1.9===>2020.3.7
1.删除默认数据路径和结果路径文件,选择文件时将常用文件夹加入快速访问
2.添加IMU测试(研究了如何在静止时加入陀螺仪输出量测,如何构造航向修正约束)

<===Version 1.10===>2020.3.13
1.添加载波跟踪滤波器测试(研究了如何设计级联卡尔曼滤波,在信号跟踪时级联滤波的具
  体设计)

<===Version 1.11===>2020.3.15
1.添加递推计算均值方差类
2.添加接收机时钟修正
3.新建GPS单天线深组合程序,可以读取IMU数据,并在IMU采样时间点进行定位

<===Version 1.12===>2020.4.8
1.添加GPS紧组合
2.所有类取消不能修改属性的限制
3.引入channel = obj.channels(k);
4.接收机类和通道类中的函数全部独立成文件,在定义类时声明其属性
  参见help-Methods in Separate Files

<===Version 1.13===>2020.4.9
1.添加GPS深组合,单天线深组合和紧组合使用的导航滤波器相同

<===Version 1.14===>2020.4.9
1.添加深组合载波驱动频率控制
2.通道存载波驱动频率
3.优化二阶锁相环,二阶延迟锁定环计算过程

<===Version 1.15===>2020.4.15
1.添加信号质量指示器
2.添加载体运动引起的载波加速度
3.单天线深组合需要输入航向角

<===Version 1.16===>2020.6.6
1.IMU数据预滤波

<===Version 2.0===>2020.8.2
1.添加北斗历书下载
2.添加NovAtel数据解析
3.添加SBG数据导入
4.添加USRP测试程序
5.修改UTC到GPS时和北斗时的转换程序,去掉秒数取整
6.通道类自带绘图函数
7.修改交互星座图回调函数机制
8.GPS星历解析时不能以第三子帧开始
9.添加GPS+BDS接收机

<===Version 2.1===>2020.8.3
1.添加通道类画鉴相器输出
2.组合导航滤波器加零偏估计约束,解决运动到静止恢复慢的问题
3.整理编码格式

<===Version 2.2===>2020.8.5
1.接收机只使用一个时间系统
2.添加北斗定位

<===Version 2.3===>2020.8.6
1.将GPS接收机的交互星座图改为新方法

<===Version 2.4===>2020.8.9
1.添加GPS+BDS深组合

<===Version 2.5===>2020.8.10
1.添加GPS+BDS接收机获取运行结果和画3D星座图
2.添加加权卫星导航解算
3.通道添加鉴相器方差计算
4.添加卫星数量统计

<===Version 2.6===>2020.8.11
1.长时间失锁放弃跟踪
2.定位之前检验几何精度因子,太大不解算

<===Version 2.7===>2020.8.13
1.修复一些bug

<===Version 2.8===>2020.8.18
1.添加杆臂补偿
2.添加北斗卫星加速度计算
3.添加上次运动状态
4.初始化定位也做几何精度因子判别,防止初始误差大
5.计算天线加速度时做杆臂补偿

<===Version 2.9===>2020.8.18
1.添加画所有通道的图

<===Version 2.10===>2020.9.4
1.修北斗信号跟踪码相位的bug

<===Version 2.11===>2020.12.20
1.静止时的角速度量测使用N点延迟的数据,因为机动检测有延迟,防止最近的几个不稳定点影响零偏估计
2.对比两种预滤波器模型:与驱动频率无关;估驱动频率误差
3.修改GPS星历下载,cddis不能用了,换esa

<===Version 3.0===>2021.1.1
1.创建通道对象数组时使用empty函数
2.使用星历计算卫星位置rs_ephe区分GPS和北斗,二者使用的地球参数不一样,算出来的位置差十几米
3.添加GPS中频信号仿真
4.添加Sagnac效应频率差补偿
5.卫星速度解算时进行光速修正

<===Version 3.1===>2021.1.1
1.添加载噪比表

<===Version 3.2===>2021.1.3
1.添加轨迹发生器
2.GPS中频信号仿真可以使用生成的轨迹

<===Version 3.3===>2021.1.3
1.轨迹发生器添加角速度和加速度生成

<===Version 3.4===>2021.1.4
1.GPS中频信号仿真加入姿态对信号的影响
2.添加使用采集的伪距伪距率进行定位验证

<===Version 4.0===>2021.1.15
1.改变相干积分时间控制方法
2.添加窄带宽带功率比值法载噪比计算
3.给出DLL,PLL跟踪噪声与环路带宽和载噪比的关系
4.添加DLL,PLL调频调相和直接调相
5.添加跟踪噪声方差计算
6.优化GPS相关程序,涉及北斗的还没改

<===Version 4.1===>2021.1.28
1.导入的IMU数据单位换成deg/s,m/s^2
2.滤波器中的IMU数据单位换成rad/s,m/s^2
3.中频信号仿真改成二次函数插值计算
4.添加IMU生成
5.载波加速度前馈每1ms做一次
6.添加地理信息计算
7.问题1:静止时导航滤波器的速度有偏.解决:导航滤波器速度量测方程需考虑光速修正
8.问题2:常速度运动时,载波加速度的积分误差曲线不平.解决:载波加速度的计算公式不对,接收机速度也会带来载波加速度
9.问题3:有加速度时测速有偏.解决:取载波多普勒时需考虑定位点与跟踪点的时间差
10.问题4:缓加速度时滤波不对.解决:惯导解算时要求相邻时刻惯导输出的平均值
11.问题5:长积分时间时不对.解决:载波频率修正时考虑钟频差,码相位修正时考虑钟差
12.问题6:加速度突变会引起速度误差突然增大.解决:添加加速度突变探测

<===Version 4.2===>2021.2.2
1.手晃运动滤波不对,惯导解算的原因,姿态更新改成二阶龙格库塔,速度更新加速度增量补偿,速度更新的姿态阵要用上次的
2.跟踪时不做钟频差补偿，在提取卫星测量量时补偿钟频差

<===Version 4.3===>2021.2.16
1.添加卫星导航滤波器

<===Version 4.4===>2021.2.22
1.添加11维导航滤波器
2.深组合模式可以不修时钟

<===Version 5.0===>2021.3.3
1.改完北斗的程序

<===Version 5.1===>2021.3.15
1.添加简单的相位缠绕校正(把陀螺零偏Q缩小,加计零偏Q放大,加计零偏还是振荡,说明还有没找到的误差)
2.使用历书计算卫星位置增加周数

<===Version 5.2===>2021.4.12
1.添加三阶锁相环
2.添加GPS纯矢量跟踪
3.明确矢量跟踪和深组合的概念,环路部分称为矢量跟踪,加了IMU称为深组合
4.纯矢量跟踪导航滤波器添加残差检验

<===Version 5.3===>2021.4.15
1.通道存跟踪结果全放在最后
2.添加MTi惯导数据解析

<===Version 5.4===>2021.4.20
1.添加Huber滤波
2.滤波器中经纬度误差换成北向东向位置误差
3.使用Matlab工具箱中的IMU模型生成IMU数据
4.添加8字型轨迹

<===Version 5.5===>2021.4.23
1.更改文件名处理方式
2.加权卫星导航解算添加Huber处理
3.卫星导航滤波器添加简化的Huber处理
4.中频信号生成时可以添加杆臂

<===Version 5.6===>2021.5.7
1.惯导导航滤波器静态时的角速度量测考虑地球自转角速度补偿
2.改codeDiscBuffPtr清零位置

<===Version 5.7===>2021.6.7
1.添加Spirent仿真器数据处理
2.添加博士论文仿真文件夹
3.添加太阳位置计算
4.添加相位缠绕效应计算
5.覆盖dcmeci2ecef函数,因为里面用到了angle2dcm

<===Version 5.8===>2021.8.15
1.添加IMU零偏稳定性和速率随机游走的仿真
2.载波加速度辅助时外推半步,能消除手晃轨迹的速度误差
3.添加论文程序文件夹

<===Version 5.9===>2021.10.21
1.添加通道载波相位量测量
2.添加惯导解算类和测试脚本
3.添加文件夹创建脚本
4.单天线导航滤波器中添加简化的Huber加权
5.GPS接收机添加卫星数量画图和伪距误差画图
6.目前GPS+BDS接收机没存satmeas

<===Version 5.10===>2021.11.11
1.修改惯导解算类为惯性导航类
2.修改单天线导航滤波器,可以处理惯导和卫星步长不一致的情况,使其继承于惯性导航类,让惯导相关参数独立出来
3.整理测试导航滤波器的程序
4.NovAtel添加RANGECMP数据解析
5.更换北斗历书ftp网址

<===Version 5.11===>2021.11.14
1.优化单天线导航滤波器量测方程部分
2.添加双天线导航滤波器和测试程序

<===Version 5.12===>2021.11.20
1.添加载波相位方差计算
2.添加载噪比阈值设置
3.测试导航滤波器时使用随机数流

<===Version 6.0===>2021.11.30
1.添加GPS多天线L1CA接收机
2.修改GPS通道画图机制
3.添加卫星可见性画图
4.GPS+BDS接收机添加画载噪比
5.添加GPS+BDS紧组合
6.BDS通道添加FLL和三阶锁相环

<===Version 6.1===>2021.12.1
1.添加估计惯导延迟的导航滤波器
2.在地理系做杆臂修正

<===Version 6.2===>2022.2.8
1.单天线导航滤波器增加已知惯导延迟补偿功能
2.添加单天线导航滤波器惯导延迟补偿测试程序
3.imuGene.m中使用随机数流生成随机数
4.原来的码鉴相器缓存换成鉴相器缓存,存储码鉴相器,载波鉴相器,鉴频器的输出,用来做更复杂的算法
5.GPS L1CA通道跟踪中添加载波开环,BDS B1C中没加
6.GL1CA接收机添加基于码鉴相器和鉴频器的矢量跟踪模式
