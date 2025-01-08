function tegangan = ms8250c_teganganDC_mV(raw_data)
    koma_1=str2double(raw_data(1));
    value_1=str2double(raw_data(3:6));
    sign=raw_data(13);
    mode=raw_data(11);
    OL=raw_data(14);        %over limit (8=over limit, 0=oke)
    
    %Cek DC apa bukan
    if(sign==':' || sign==';' || sign=='8' || sign=='9')
        %Cek pengukuran Tegangan apa bukan
        if(mode==';')      %channel V
            %untuk pengukuran Tegangan (dalam mV)
            if (koma_1==0 && OL~='8')
                value_1=value_1*1;  %0.001 --> V
            elseif (koma_1==1 && OL~='8')
                value_1=value_1*10;   %0.01 --> V
            elseif (koma_1==2 && OL~='8')
                value_1=value_1*100;    %0.1 --> V
            elseif (koma_1==4 && OL~='8')
                value_1=value_1*0.1; %0.0001 --> V
            else
                value_1=NaN;
            end
        else
            value_1=NaN;
        end
    
        %ada tambahan didalamnya per 9 agt 17
        if((sign==';')||(sign=='9'))
            value_1=value_1*(-1);
        end

        tegangan=value_1;
        pause(0.344);
    else
        tegangan=NaN;           %jika bukan AC
    end