%%解算出各个加速度传感器的数据
function out=Get_Motion(data)

for i=1:9
   temp=0;
   temp = bitor(bitshift(data(2*i+1),8),data(2*i+2));
   if temp>32768
         temp=0-bitand(temp,32767);
   else
         temp = bitand(temp,32767);
   end
   out(i)= temp;
end
end