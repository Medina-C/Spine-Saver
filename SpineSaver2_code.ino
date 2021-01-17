#include <SoftwareSerial.h>
#include<Wire.h>

#define rxPin 10
#define txPin 11
 
const int MPU_addr=0x68;
int16_t AcX,AcY,AcZ,Tmp,GyX,GyY,GyZ;
 
int minVal=265;
int maxVal=402;

int TOLERANCE = 20;
int highTol = 10;
int medTol = 15;
int lowTol = 20;

int timeSeconds = 10;
 
double rawX;
double rawY;
double rawZ;

double smoothX;
double smoothY;
double smoothZ;

double avX;
double avY;
double avZ;

int readRate = 50;

//Bluetooth Stuff
SoftwareSerial btSerial(rxPin, txPin);
char btIn = 0;


void readRaw(){
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x3B);
  Wire.endTransmission(false);
  Wire.requestFrom(MPU_addr,14,true);
  AcX=Wire.read()<<8|Wire.read();
  AcY=Wire.read()<<8|Wire.read();
  AcZ=Wire.read()<<8|Wire.read();
  int xAng = map(AcX,minVal,maxVal,-90,90);
  int yAng = map(AcY,minVal,maxVal,-90,90);
  int zAng = map(AcZ,minVal,maxVal,-90,90);
   
  rawX= RAD_TO_DEG * (atan2(-yAng, -zAng)+PI);
  rawY= RAD_TO_DEG * (atan2(-xAng, -zAng)+PI);
  rawZ= RAD_TO_DEG * (atan2(-yAng, -xAng)+PI);
}

void smoothRead(int readTime, bool setupRun){

  double xtotal = 0;
  double ytotal = 0;
  double ztotal = 0;
  
  for (int i = 0; i <= (readTime / readRate); i++){
      readRaw();
      xtotal += rawX;
      ytotal += rawY;
      ztotal += rawZ;

      delay(readRate);
  }

  if (setupRun){
    avX = xtotal / double(readTime / readRate);
    avY = ytotal / double(readTime / readRate);
    avZ = ztotal / double(readTime / readRate);
  }

  else{
    smoothX = xtotal / double(readTime / readRate);
    smoothY = ytotal / double(readTime / readRate);
    smoothZ = ztotal / double(readTime / readRate);
  }
  
}

void readBluetooth(char & btIn)
{
  char temp = btSerial.read();
  if(temp >= 65 && temp <= 90)
  {
    btIn = temp;
  }
}

void setup(){
  Wire.begin();
  Wire.beginTransmission(MPU_addr);
  Wire.write(0x6B);
  Wire.write(0);
  Wire.endTransmission(true);
  
  Serial.begin(9600);
  btSerial.begin(9600);
}

void loop() {
    
  readBluetooth(btIn);    
       
  switch(btIn) {
  
  case 'C': //calibration
      Serial.println("Calibration");
      smoothRead(1000, true);
      btSerial.write('C');
      btIn = 0;
      break;

  case 'H':
      Serial.println("High Tolerance mode");
      TOLERANCE = highTol;
      btIn = 'S';
      break;

  case 'M':
      Serial.println("Medium Tolerance mode");
      TOLERANCE = medTol;
      btIn = 'S';
      break;

  case 'L':
      Serial.println("Low Tolerance mode");
      TOLERANCE = lowTol;
      btIn = 'S';
      break;

  case 'S':
      Serial.println("Started");
      
      smoothRead(1000, false);

      Serial.println(abs(smoothX - avX));
      Serial.println(abs(smoothY - avY));
      Serial.println(abs(smoothZ - avZ));
        
      if (abs(smoothX - avX) > TOLERANCE)
        { 
          Serial.println("Bad posture");
          btSerial.write('B');
        }
      else{
        btSerial.write('G');
      }

      break;
  }
 }
