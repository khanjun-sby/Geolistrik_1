clear;
clc;
tic;
%Setting serial MS8280C
s1 = serial('COM3');
s1.BaudRate=19200;
s1.StopBits=2;
s1.Timeout=10;
s1.Terminator='CR/LF';
s1.DataBits=7;
get(s1,{'BaudRate','DataBits','Parity','StopBits','Terminator'});
fopen(s1);
pause(1);

%Setting serial Arduino
s2 = serial('COM4','BaudRate',9600);
fopen(s2);
pause(1);

%Setting sensor arus ACS712 05B
mVperAmp=185;          %dari datasheet
ACS_Offset=2500;       %dalam mv dari datasheet

%untuk handle file penyimpanan data
nama_file = input('Nama file penyimpanan: ', 's');
[file_id,msg] = fopen(strcat(nama_file,'.csv'),'w');
fprintf(file_id,'No,Depth,A,M,N,B,Sample ke,Current(A),Average Current(A),Voltage(V),Average Voltage(V)\n');

jumlah_elektroda=32;
send2Arduino_OFF=strcat(num2str(jumlah_elektroda),',',num2str(jumlah_elektroda),',',num2str(jumlah_elektroda),',',num2str(jumlah_elektroda));
depth=fix(jumlah_elektroda/3);
jumlah_sample=2;   %jumlah pengambilan sample perkonfigurasi susunan elektroda

display('Data Aquisition Process. Please wait..');
no_data=0;
kontrol_elektroda=1;        %diasumsikan elektroda terpasang dgn benar
for i=1:depth
    j_max=jumlah_elektroda-(3*i);
    for j=1:j_max
        A=j-1;      %mulai dari 0 (sesuai pengalamatan relay pada Arduino)
        M=A+i;
        N=M+i;
        B=N+i;
        send2Arduino=strcat(num2str(A),';',num2str(M),';',num2str(N),';',num2str(B));
        send2Arduino_IP=strcat(num2str(B),';',num2str(M),';',num2str(N),';',num2str(A));
        AMNB=strcat(num2str(A+1),',',num2str(M+1),',',num2str(N+1),',',num2str(B+1));
        
        kumulatif_nilai_arus=0;         %arus
        kumulatif_value_1=0;            %tegangan
        for data=1:jumlah_sample
            no_data=no_data+1;
            fprintf(s2,send2Arduino);
            pause(0.2); %delay untuk setting relay (CEK LAGI!!!!!!)

            raw_data_2=fscanf(s2);  %ambil data dari Arduino terlebih dahulu sekaligus memastikan konfigurasi relay
            flushinput(s1);         %menghapus buffer read serial (biar terupdate datanya)
            raw_data_1=fscanf(s1);  %data tegangan (MS8250C)          

            %mekanisme pengaturan OFF dan IP dari relay setelah pengambilan data
            fprintf(s2,send2Arduino_OFF);   %relay non aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
            fprintf(s2,send2Arduino_IP);    %Induced polarization aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan IP aktif
            fprintf(s2,send2Arduino_OFF);   %relay non aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
            
            koma_1=str2num(raw_data_1(1));
            koma_2=str2num(raw_data_1(2));
            value_1=str2num(raw_data_1(3:6));
            
            if value_1==0
                kontrol_elektroda=0;
            end
   
            while kontrol_elektroda==0
                load gong.mat;
                sound(y);
                clc;
                display('WARNING !!');
                display(strcat(num2str(no_data),'. Zero voltage detected on A,M,N,B: ',AMNB));
                display('Make sure your electroda are connected properly..');
                display('Press "Y" and enter after you Re-check the electroda configuration');
                display('Or Press "N" and enter to ignore it.');
                cek=input('','s');
                
                if cek=='Y';
                    kontrol_elektroda=1;
                    fprintf(s2,send2Arduino);
                    pause(0.2); %delay untuk setting relay (CEK LAGI!!!!!!)

                    raw_data_2=fscanf(s2);  %ambil data dari Arduino terlebih dahulu sekaligus memastikan konfigurasi relay
                    flushinput(s1);         %menghapus buffer read serial (biar terupdate datanya)
                    raw_data_1=fscanf(s1);  %data tegangan (MS8250C)          

                    %mekanisme pengaturan OFF dan IP dari relay setelah pengambilan data
                    fprintf(s2,send2Arduino_OFF);   %relay non aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
                    fprintf(s2,send2Arduino_IP);    %Induced polarization aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan IP aktif
                    fprintf(s2,send2Arduino_OFF);   %relay non aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
                    
                    koma_1=str2num(raw_data_1(1));
                    koma_2=str2num(raw_data_1(2));
                    value_1=str2num(raw_data_1(3:6));
                    
                    if value_1==0
                        kontrol_elektroda=0;
                    end
                else
                    kontrol_elektroda=1;
                end
            end
            
            value_2=str2num(raw_data_1(7:10));
            mode=raw_data_1(11);
            sign=raw_data_1(13);

            %satuannya voltage
            if (koma_1==0)
                value_1=value_1*0.001;
            elseif (koma_1==1)
                value_1=value_1*0.01;
            elseif (koma_1==2)
                value_1=value_1*0.1;
            elseif (koma_1==4)
                value_1=value_1*0.0001;
            else Value_1=NaN;
            end

            if(sign==';')
                value_1=value_1*(-1);
            end

            %satuannya Hz
            if (koma_2==0)
                value_2=value_2*0.01;
            elseif (koma_2==1)
                value_2=value_2*0.1;
            elseif (koma_2==2)
                value_2=value_2;
            elseif (koma_2==3)
                value_2=value_2*10;
            elseif (koma_2==4)
                value_2=value_2*100;
            elseif (koma_2==5)
                value_2=value_2*1000;
            elseif (koma_2==6)
                value_2=value_2*10000;
            else value_2=NaN;
            end

            %display
            if(sign=='6')
                display(strcat('Voltage (AC): ',num2str(value_1),' Volt'));
                display(strcat('Freq: ', num2str(value_2), ' Hz'));
            elseif(sign==':' || sign==';')
                display(strcat('Voltage (DC): ',num2str(value_1),' Volt'));
                display(strcat('Freq: ', num2str(value_2), ' Hz'));
            end

            buff_arus=str2num(raw_data_2);
            buff_arus=5000*buff_arus/1023;
            nilai_arus=(buff_arus - ACS_Offset)/mVperAmp;

            display(strcat('Raw Current (DC): ',raw_data_2));
            display(strcat('Current (DC): ',num2str(nilai_arus),' Ampere'));
            
            kumulatif_nilai_arus=kumulatif_nilai_arus+nilai_arus;
            average_arus=kumulatif_nilai_arus/data;
            
            kumulatif_value_1=kumulatif_value_1+value_1;
            average_tegangan=kumulatif_value_1/data;
            
            display(strcat('no_data: ',num2str(no_data),' Depth: ',num2str(i),' AMNB: ',AMNB,' sample ke: ',num2str(data),' Current: ',num2str(nilai_arus),'A',' Average Current: ',num2str(average_arus),'A',' Voltage: ',num2str(value_1),'V',' Average Voltage: ',num2str(average_tegangan),'V'));
            fprintf(file_id,strcat(num2str(no_data),',',num2str(i),',',AMNB,',',num2str(data),',',num2str(nilai_arus),',',num2str(average_arus),',',num2str(value_1),',',num2str(average_tegangan),'\n'));

        end
    end
end

%closing komunikasi serial MS8250C
fclose(s1);
delete(s1);
clear s1;

%closing komunikasi serial Arduino
fclose(s2);
delete(s2);
clear s2;

%closing file_id
fprintf(file_id,'No,Depth,A,M,N,B,Sample ke,Current(A),Average Current(A),Voltage(V),Average Voltage(V)\n');
fclose(file_id);

clc
load gong.mat;
sound(y);
display('Finish..');
toc