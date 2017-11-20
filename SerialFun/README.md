# MATLAB  串口通信
> 由于项目需要，用matlab 做了一个串口通信工具，也碰到不少坑。这里总结一下。
## 读取串口数据

matlab 支持串口通信，因此直接调用串口的结构体serial就可以，在调用之前，需要对串口属性进行设置。
>```
>delete(instrfindall) %%关闭没用的，这句很重要 
>s=serial('COM5');%创建串口
>set(s,'BauRate',115200); %设置波特率
>set(s,'inputBufferSize',1024000) %设置输入缓冲区域为1M
> %串口事件回调设置
> set(s,'BytesAvailabelFcnMode','bytes');%设置中断响应函数对象
> set(s,'BytesAvailabelFcnCount',10);%设置终端触发方式
> s.BytesAvailabelFcn=@ReceiveCallback;%ReceiveCallback是中断的触发函数，这里我是自定义的。系统的回调函数为instrcallback;
>fopen(s);%打开串口
>%data=fread(s)%读取二进制字节 fwrite二进制写入 相应文本用fscanf 和fpintf
>
> %data %进行数据处理
>
>%fclose(s);
>%delete(s);
>%clear s;
以上的代码是MATLAB 串口读取的基本函数，对串口操作的整个过程可以概括为:“设置串口参数”->"打开串口“->"读取串口数据”->“关闭串口”。
### 串口通信方式选择
serial 中断方式参数为BytesAvailabelFcnMode,它的方式有Terminator 和bytes 两种。Terminator 为查询方式中断方式。其值有“LR（换行符）” 和“CR(回车符)” 两种。  
（1） 查询方式中断  
  查询方式中断方式为Terminator,值有CR和LF两个。查询中断的含义是在缓存区读取数据，当读取到存在CR和LF之后，触发中断，调用回调函数。查询中断简单但不适用。具体例子可以看http://blog.sina.com.cn/s/blog_6163bdeb0102e8qc.html
  >``` 
  >set(s,'BytesAvailabelFcnMode','Termiator');% 查询中断
  > set(s,'Terminator','CR');%设置中断方式
(2) 基于matlab 方式实时串行通信编程  
matlab更多的采用的事事件驱动方法中断。中断参数为"bytes"。即按字节中断。如设定缓存区域达到10个字节，就触发中断，调用回调函数，进行处理。
>``` 
>set(s,'BytesAvailabelFcnMode','bytes');%设置中断响应函数对象
> set(s,'BytesAvailabelFcnCount',10);%设置终端触发方式
> s.BytesAvailabelFcn=@ReceiveCallback;

我们可以对系统的instrcallback 函数进行修改调用系统的回调函数，但是系统的回调函数matlab 安装包下，可以右键打开，或者直接用which 命令查找它的位置，另外我们也可以自己写相应的回掉函数。比如我这里自己定义回调函数ReceiceCallback。
>```
>function ReceiveCallback( obj,event)     %创建中断响应函数  
>   global s a fid;
>   str = fread(s);%读取数据
>   % hex=dec2hex(str)
>   a=[];IMU_data = [];Motion_data=[];
>   sign_head1=hex2dec('A5');sign_head2 = hex2dec('5A');
>   sign_finish=hex2dec('AA');sign_IMU=hex2dec('A1');sign_Motion=hex2dec('A2');
>   a= [a;str];
>   j=1;
>   while (~isempty(a))
>         if j>size(a,1)
>           break;
>         end
>         if a(j)==sign_head1 && a(j+1) == sign_head2 
>            if (j+a(j+2)+1) > size(a,1) 
>                break;
>            end
>            index_start = j+2;
>            index_finish= index_start + a(j+2)-1;
>            pack = a(index_start:index_finish);
>            if ~isempty(pack) &&pack(pack(1))== sign_finish
>                  if pack(2) == sign_IMU
>                        IMU_data(1,:) = Get_IMU(pack);
>                        j = index_finish;
>                        continue;
>                  end
>                   if pack(2) ==sign_Motion
>                          Motion_data(1,:) = Get_Motion(pack);
>                          j = index_finish;
>                   end
>                   if ~isempty(IMU_data) && ~isempty(Motion_data)
>                        act_data = [IMU_data,Motion_data]
>                        fprintf(fid,'%8.1f%8.1f%8.1f%8.1f%8.1f%8.1f%8d%8d%8d%8d%8d%8d%8d%8d%8d\n',act_data);
>                        Motion_data=[];IMU_data=[];
>                        a(1:index_finish)=[];
>                         j=1;
>                    end
>                 end
>            else
>                j=j+1;
>        end    
>  end  
>end

回调函数包含两个参数，这个必须要，不能少。其中obj 是传递串口参数的。event暂时没用到。这里回调函数是从还从去读取二进制数据。然后解算出姿态传感器的姿态数据和传感器数据。并且存到txt中。姿态上报数据格式为A5 5A 开头，第三位为传递数据位(不包含A55A)，第四位为A1/A2,A1。A1 表示的是姿态数据，A2表示传感器数据。数据以AA结尾。因此算法的思路是每次有姿态数据和传感器数据然后就保存到文本中。  
参考  
1 http://blog.csdn.net/u010177286/article/details/45872365  
2 http://blog.csdn.net/guomutian911/article/details/41206663    
3 http://blog.sina.com.cn/s/blog_6163bdeb0102e8qc.html  
4 https://wenku.baidu.com/view/72661333b90d6c85ec3ac67f.html
