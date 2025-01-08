%Setting serial Arduino
s2 = serial('COM6','BaudRate',9600);		%posisi serial cek terlebih dahulu di device manager
fopen(s2);
pause(1);

%untuk membaca konfigurasi channel AMNB
nama_file_AMNB = input('coba1234.csv: ', 's');
konf_AMNB=csvread(nama_file_AMNB,1,0);  %dimulai dari baris kedua dan kolom pertama
size_AMNB=size(konf_AMNB);
jumlah_konf=size_AMNB(1,1);

display('Data Aquisition Process. Please wait..');
no_data=0;
kontrol_elektroda=1;        %diasumsikan elektroda terpasang dgn benar
for j=1:jumlah_konf
    A=konf_AMNB(j,1)-1;      %mulai dari 0 (sesuai pengalamatan relay pada Arduino)
    M=konf_AMNB(j,2)-1;
    N=konf_AMNB(j,3)-1;
    B=konf_AMNB(j,4)-1;
    send2Arduino=strcat(num2str(A),';',num2str(M),';',num2str(N),';',num2str(B));
    send2Arduino_IP=strcat(num2str(B),';',num2str(M),';',num2str(N),';',num2str(A));
    AMNB=strcat(num2str(A+1),',',num2str(M+1),',',num2str(N+1),',',num2str(B+1));

    kumulatif_nilai_arus=0;         %arus
    kumulatif_nilai_tegangan=0;            %tegangan
end

%closing komunikasi serial Arduino
fclose(s2);
delete(s2);
clear s2;

display('Finish..');