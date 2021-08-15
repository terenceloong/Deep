运行顺序:
file_preprocess->csv_read->error_xxx_cal->result_figure

umt_gene.m
生成Spirent仿真器用的.umt文件
需要先加载轨迹数据traj
.umt文件跟轨迹文件存在一起

csv_read.m
读取Spirent仿真器输出的.csv文件,运行完画位置速度曲线
生成变量t0,是开始时刻的GPS周内秒
轨迹数据存在矩阵motionSim中,[t,lat,lon,h,vn,ve,vd,an,ae,ad]

error_satnav_cal.m
计算卫星导航解算结果与仿真器基准值的误差
先将两个结果画在一张图里,再计算误差,再画误差曲线
卫星导航解算结果变量为time,pos,vel
仿真器基准值变量为motionSim
使用插值的方法计算定位时刻的基准值

error_filter_cal.m
计算滤波器结果与仿真器基准值的误差
先将两个结果画在一张图里,再计算误差,再画误差曲线
滤波器结果变量为:time,posF,velF,accF
仿真器基准值变量为motionSim
使用插值的方法计算定位时刻的基准值

result_figure.m
画一些其他的曲线:
载噪比,变量为CN0
载波频率变化率,变量为carrAccR
轨迹的速度和加速度刨面,变量为motionSim,用于写文章