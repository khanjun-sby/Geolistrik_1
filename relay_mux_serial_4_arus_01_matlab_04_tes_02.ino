#include <MCP3424REVP.h>

MCP3424REVP MCP(104); // untuk setting (Adr0 dan Adr1) dihubungkan ke ground (0)
                      // 104 -> 0b01101000 ->0x68
                      // 0 -> 0b00000000 bisa pake 0 karena sdh ada (0b1101<<3) di kode library
long buff_analog;     //untuk pembacaan sensor arus melalui ADC MCP3424 18 bits masih microVolt
float data_arus;      //

String perintah_serial="";      //format perintah: A;M;N;B
String buff;

int mux_block_1[] = {22,24,26,28,30};      //LSB to MSB ABCDE // A
int mux_block_2[] = {23,25,27,29,31};      //LSB to MSB ABCDE // B
int mux_block_3[] = {32,34,36,38,40};      //LSB to MSB ABCDE // M
int mux_block_4[] = {33,35,37,39,41};      //LSB to MSB ABCDE // N

int mux_pin_com=53;        //mux common pin

int buff_int_1;
int buff_int_2;
int buff_int_3;
int buff_int_4;

char buff_char;

void setup() {
  // put your setup code here, to run once:
  MCP.begin(104);     //konfigurasi MCP3424
  MCP.configuration(2,18,0,1); // Channel 2, 18 bits resolution, one-shot mode, amplifier gain = 1
  
  pinMode(mux_pin_com,OUTPUT);
  relay_OFF();
  
  for( int i = 0; i<5; i++){
      pinMode(mux_block_1[i],OUTPUT);
      pinMode(mux_block_2[i],OUTPUT);
      pinMode(mux_block_3[i],OUTPUT);
      pinMode(mux_block_4[i],OUTPUT);
  }
  
  Serial.begin(9600);
}
void loop() {
  // put your main code here, to run repeatedly:

  while(Serial.available()>0) {
    buff_char = Serial.read();
    perintah_serial.concat(buff_char);
    delay(10);  
  }

  if(perintah_serial != ""){
    
    buff=splitValue(perintah_serial,';',0);
    buff_int_1=(buff.toInt());     //merubah menjadi integer

    buff=splitValue(perintah_serial,';',1);
    buff_int_2=(buff.toInt());

    buff=splitValue(perintah_serial,';',2);
    buff_int_3=(buff.toInt());

    buff=splitValue(perintah_serial,';',3);
    buff_int_4=(buff.toInt());

    if(buff_int_1<0 || buff_int_2<0 || buff_int_3<0 || buff_int_4<0 || buff_int_1>31 || buff_int_2>31 || buff_int_3>31 || buff_int_4>31){
      relay_OFF();
      delay(50);
    }else{
      //Untuk mengkonfigurasi blok relay
      relay_OFF();    //untuk memastikan relay off saat perubahan konfigurasi relay. menghindari short circuit ketika AMNB sdh terhubung
      delay(50);
      
      mux_select(mux_block_1, buff_int_1);
      mux_select(mux_block_2, buff_int_2);
      mux_select(mux_block_3, buff_int_3);
      mux_select(mux_block_4, buff_int_4);

      relay_ON();
      delay(100);  //delay 100 ms. delay konfigurasi relay
    }

    //bagian ini dikeluarkan dari struktur if else supaya meskipun mendapat perintah OFF, Arduino tetap mengirim data.
    //Data OFF tidak digunakan secara angka, namun penting untuk memberitahu Matlab bahwa konfigurasi relay OFF sdh dijalankan.
    //sedangkan Data ON menunjukkan nilai pengukuran arus listrik dalam satuan Ampere. Serta memberitahu Matlab bahwa konfigurasi relay ON sdh dijalankan.
    MCP.newConversion(); // New conversion is initiated
    buff_analog=MCP.measure();  // Measure, note that the library waits for a complete conversion
                                //Satuan masih microVolt (uV) belum dikonversi ke satuan Arus
    data_arus=buff_analog/185;  //mili Ampere (mA)
                             
    delayMicroseconds(50);  //delay 50 microseconds

    Serial.println(data_arus);
    perintah_serial="";
  }
}

void relay_OFF(){
  digitalWrite(mux_pin_com,HIGH);       //mux common pin HIGH supaya semua relay OFF (relay aktif LOW)
}

void relay_ON(){
  digitalWrite(mux_pin_com,LOW);        //mux common pin LOW supaya relay ON sesuai channel mux yang aktif (relay aktif LOW)
}

void mux_select(int mux_block[],int posisi){
  bool buff;
  for( int i = 0; i<5; i++){
    buff = bitRead(posisi,i);
    if (buff == 1){
      digitalWrite(mux_block[i],HIGH);
    }
    else if (buff == 0) {
      digitalWrite(mux_block[i],LOW);
    }
  }
}

//Function untuk memisahkan data dengan separator
String splitValue(String data, char separator, int index){
  int found = 0;
  int strIndex[]={0, -1};
  int maxIndex = data.length()-1;
  for(int i=0; i<=maxIndex && found<=index; i++){
    if(data.charAt(i) == separator || i==maxIndex){
      found++;
      strIndex[0] = strIndex[1]+1;
      strIndex[1] = (i == maxIndex) ? i+1 : i;
    }
  }
  return found>index ? data.substring(strIndex[0], strIndex[1]) : "";
}
