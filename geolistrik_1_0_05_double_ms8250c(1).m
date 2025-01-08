%written by Muhammad Nurul Puji
%geolistrik 1.0
%muhammadpuji.its@gmail.com
%hp.+6285279405640
%Geophysics Engineering Department
%Institut Teknologi Sepuluh Nopember (ITS)
%Surabaya

%double MS8250C communication (voltage & current measurement)
%Arduino communication
%multi elektroda (32)
%error check
%IP non aktif (customable)
%using ADC MCP3424
%using current sensor ACS712
%current data from Arduino in mili Ampere

%PLEASE BE AWARE TO NOT CONFIGURE SAME CHANNEL FOR ALL A,M,N,B. EX: 2,2,2,2
%IT MEANS A,M,N,B WILL CONNECT TOGETHER AND CAN CAUSE SORT CIRCUIT

clear;
clc;
tic;
%Setting serial MS8280C Tegangan
s1 = serial('COM3');				%posisi serial cek terlebih dahulu di device manager
s1.BaudRate=19200;
s1.StopBits=2;
s1.Timeout=10;
s1.Terminator='CR/LF';
s1.DataBits=7;
get(s1,{'BaudRate','DataBits','Parity','StopBits','Terminator'});
fopen(s1);
pause(1);

%Setting serial Arduino kontrol relay
s2 = serial('COM4','BaudRate',9600);		%posisi serial cek terlebih dahulu di device manager
fopen(s2);
pause(1);

%Setting serial MS8280C Arus
s3 = serial('COM5');				%posisi serial cek terlebih dahulu di device manager
s3.BaudRate=19200;
s3.StopBits=2;
s3.Timeout=10;
s3.Terminator='CR/LF';
s3.DataBits=7;
get(s3,{'BaudRate','DataBits','Parity','StopBits','Terminator'});
fopen(s3);
pause(1);

%untuk handle file penyimpanan data
nama_file = input('Nama file penyimpanan: ', 's');
[file_id,msg] = fopen(strcat(nama_file,'.csv'),'w');
fprintf(file_id,'No,Depth,A,M,N,B,Sample ke,Current(mA),Average Current(mA),Voltage(mV),Average Voltage(mV)\n');

jumlah_elektroda=32;
elektroda_off=33;	%karena secara hardware ada 32 elektroda maka jika diluar itu berarti perintah off
send2Arduino_OFF=strcat(num2str(elektroda_off),',',num2str(elektroda_off),',',num2str(elektroda_off),',',num2str(elektroda_off));
depth=fix(jumlah_elektroda/3);
jumlah_sample=str2double(input('jumlah pengambilan sample perkonfigurasi elektroda: ', 's'));   %jumlah pengambilan sample perkonfigurasi susunan elektroda

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
        kumulatif_nilai_tegangan=0;            %tegangan
        for data=1:jumlah_sample
            no_data=no_data+1;
            fprintf(s2,send2Arduino);
            pause(0.5); %delay untuk setting relay (CEK LAGI!!!!!!)

            fscanf(s2);  %data tidak disimpan. hanya untuk memastikan konfigurasi relay
            flushinput(s1);         %menghapus buffer read serial (biar terupdate datanya)
            raw_data_1=fscanf(s1);  %data tegangan (MS8250C)          
            flushinput(s3);         %menghapus buffer read serial (biar terupdate datanya)
            raw_data_2=fscanf(s3);  %data arus (MS8250C)          


            %mekanisme pengaturan OFF dan IP dari relay setelah pengambilan data
            fprintf(s2,send2Arduino_OFF);   %relay non aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
            fprintf(s2,send2Arduino_IP);    %Induced polarization aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan IP aktif
            fprintf(s2,send2Arduino_OFF);   %relay non aktif
            fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
            
            nilai_tegangan=ms8250c_teganganDC_mV(raw_data_1);   %data tegangan dari ms8250c
            nilai_arus=ms8250c_arusDC_mA(raw_data_2);	%data arus dari ms8250c
            
            if (nilai_tegangan==0 || nilai_arus==0)
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
                    pause(0.5); %delay untuk setting relay (CEK LAGI!!!!!!)

                    fscanf(s2);  %data tidak disimpan. hanya untuk memastikan konfigurasi relay
                    flushinput(s1);         %menghapus buffer read serial (biar terupdate datanya)
                    raw_data_1=fscanf(s1);  %data tegangan (MS8250C)     
                    flushinput(s3);         %menghapus buffer read serial (biar terupdate datanya)
                    raw_data_2=fscanf(s3);  %data arus (MS8250C)

                    %mekanisme pengaturan OFF dan IP dari relay setelah pengambilan data
                    fprintf(s2,send2Arduino_OFF);   %relay non aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
                    fprintf(s2,send2Arduino_IP);    %Induced polarization aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan IP aktif
                    fprintf(s2,send2Arduino_OFF);   %relay non aktif
                    fscanf(s2);                     %data tidak disimpan. hanya untuk timing memastikan sdh non aktif
                    
                    nilai_tegangan=ms8250c_teganganDC_mV(raw_data_1);   %data tegangan dari ms8250c
                    nilai_arus=ms8250c_arusDC_mA(raw_data_2);	%data arus dari ms8250c
                    
                    if (nilai_tegangan==0 || nilai_arus==0)
                        kontrol_elektroda=0;
                    end
                else
                    kontrol_elektroda=1;
                end
            end
            
            kumulatif_nilai_arus=kumulatif_nilai_arus+nilai_arus;
            average_arus=kumulatif_nilai_arus/data;
            
            kumulatif_nilai_tegangan=kumulatif_nilai_tegangan+nilai_tegangan;
            average_tegangan=kumulatif_nilai_tegangan/data;
            
            display(strcat('no_data: ',num2str(no_data),' Depth: ',num2str(i),' AMNB: ',AMNB,' sample ke: ',num2str(data),' Current: ',num2str(nilai_arus),'mA',' Average Current: ',num2str(average_arus),'mA',' Voltage: ',num2str(nilai_tegangan),'mV',' Average Voltage: ',num2str(average_tegangan),'mV'));
            fprintf(file_id,strcat(num2str(no_data),',',num2str(i),',',AMNB,',',num2str(data),',',num2str(nilai_arus),',',num2str(average_arus),',',num2str(nilai_tegangan),',',num2str(average_tegangan),'\n'));

        end
    end
end

%closing komunikasi serial MS8250C Tegangan
fclose(s1);
delete(s1);
clear s1;

%closing komunikasi serial Arduino Kontrol Relay
fclose(s2);
delete(s2);
clear s2;

%closing komunikasi serial MS8250C Arus
fclose(s3);
delete(s3);
clear s3;

%closing file_id
fprintf(file_id,'No,Depth,A,M,N,B,Sample ke,Current(mA),Average Current(mA),Voltage(mV),Average Voltage(mV)\n');
fclose(file_id);

clc
load gong.mat;
sound(y);
display('Finish..');
toc