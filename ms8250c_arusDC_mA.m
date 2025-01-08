function arus = ms8250c_arusDC_mA(raw_data)
    koma_1=str2double(raw_data(1));
    value_1=str2double(raw_data(3:6));
    sign=raw_data(13);
    mode=raw_data(11);
    OL=raw_data(14);        %over limit (8=over limit, 0=oke)
    
    %Cek DC apa bukan
    if(sign==':' || sign==';' || sign=='8' || sign=='9')    
        %Cek pengukuran Arus apa bukan
        if(mode=='=')   %channel uA             
            %untuk pengukuran arus (dalam mA)
            if (koma_1==0 && OL~='8')
                value_1=value_1*0.0001;    %0.1 --> uA
            elseif (koma_1==1 && OL~='8')
                value_1=value_1*.001;      %1 --> uA
            else value_1=NaN;
            end
        elseif(mode=='?')   %channel mA
            %untuk pengukuran arus (dalam mA)
            if (koma_1==0 && OL ~='8')
                value_1=value_1*0.01;   %0.01 --> mA
            elseif (koma_1==1 && OL~='8')
                value_1=value_1*0.1;    %0.1 --> mA
            else value_1=NaN;
            end
        elseif(mode=='0')   %Channel A
            %untuk pengukuran arus (dalam mA)
            if (koma_1==0 && OL ~='8')
                value_1=value_1*10;   %0.01 --> A
            elseif (koma_1==1 && OL~='8')
                value_1=value_1*100;    %0.1 --> A
            else value_1=NaN;
            end
        else
            value_1=NaN;    %jika bukan arus
        end

        %ada tambahan didalamnya per 9 agt 17
        if((sign==';')||(sign=='9'))
            value_1=value_1*(-1);
        end

        arus=value_1;
        pause(0.344);
    else
        arus=NaN;           %jika bukan DC
    end