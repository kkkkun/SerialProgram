function out=Get_IMU(data)
%% 解算出相应的IMU:YAW,Pitch,Roll,ALt,temp,Press
for i=1:6
   temp=0;
   temp = bitor(bitshift(data(2*i+1),8),data(2*i+2));
   if temp>32768
         temp=0-bitand(temp,32767);
   else
         temp = bitand(temp,32767);
   end
   out(i) = temp/10;
end
end


