
#include<WiFi.h>
#include <NewPing.h>
#include <MedianFilter.h>
#include <Wire.h>
#include <MedianFilter.h>

const char* ssid = "aakash";
const char* password = "12345678";

IPAddress ip(192, 168, 43, 116);
IPAddress gateway(192, 168, 0, 1);
IPAddress subnet(255, 255, 255, 0);
WiFiServer server(80);

//jsn 1
#define TRIGGER_PIN 17// Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN 16// Arduino pin tied to echo pin on the ultrasonic sensor.
#define MAX_DISTANCE 450
//jsn2
#define TRIGGER_PIN1 18 // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN1 19
#define MAX_DISTANCE1 450

//ultra senor
#define TRIGGER_PIN2 33 // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN2 5
#define MAX_DISTANCE2 450


const int buttonPin1 = 23; //button1SOS
const int buttonPin2 = 25; //button2NAVI
const int buttonPin3 = 26; //button3face
const int buttonPin4 = 27;//button4object
const int buttonPin5 = 32; //button5barcode
//adxl
const int xpin = 34;                
const int ypin = 35;                  
const int zpin = 36;




NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.

NewPing sonar1(TRIGGER_PIN1, ECHO_PIN1, MAX_DISTANCE1);

NewPing sonar2(TRIGGER_PIN2, ECHO_PIN2, MAX_DISTANCE2);

MedianFilter filter(31,0);
MedianFilter filter1(31,0);
MedianFilter filter2(31,0);

int x=0;
int x1=0;
int x2=0;
int x3=0;
int x4=0;
int w=0;
String s;
String a;//jsn1
String a1;//jsn2
String a2;//1
String a3;//2
String a4;//3
String a5;//4
String a6;//5
String a7;//away,to,away
String a8;//elebow
String a9;//water


int buttonState1 = 0;
int buttonState2 = 0;
int buttonState3 = 0;
int buttonState4 = 0;
int buttonState5 = 0;


TaskHandle_t Task2;


void Task2code( void * parameter )
{
    for (;;)
    {
 
        // Check if a client has connected
        WiFiClient client = server.available();
        if (!client)
            continue;
        // Wait until the client sends some data
        // Serial.println("new client");
        while(!client.available())
            delayMicroseconds(1);
 
        if(client.available())
        {

                // FoR ECE
          delay(50); // Wait 50ms between pings (about 20 pings/sec). 29ms should be the shortest delay between pings.
          unsigned int o,uS = sonar.ping(); // Send ping, get ping time in microseconds (uS).
          unsigned int o1,uS1 = sonar1.ping();
          unsigned int o2,uS2 = sonar2.ping();
          filter.in(uS);
          o = filter.out();
         
          filter1.in(uS1);
          o1 = filter1.out();

          filter2.in(uS2);
          o2 = filter2.out();
         
          Serial.print("Ping: ");
          x = o / US_ROUNDTRIP_CM;
          x2 = o1 / US_ROUNDTRIP_CM;
          x4 = o2 / US_ROUNDTRIP_CM;
          Serial.println( x);
          Serial.println("cm");
          Serial.println( x2);
          Serial.println("cm");
          Serial.println( x4);
          Serial.println("cm");

          //JSN start
          {
             if ( x>= 0 && x<= 21)
                {
                   Serial.println("ignore");
                  }
             if ( x >100)
                {
                  Serial.println("no one");
                   }
            else
                {
                  if( x == x1)
                    {
                       Serial.println("staticc");
                       a="staticc";
                       }

                  if( x > x1)
                      {
                        Serial.println("away");
                        a="away";
                        }
                  if( x < x1)
                     {
                      Serial.println("towards");
                      a="towards";
                      }
                  x1=x;
                 }
            }
            //JSN END
            //JSN2 START
            {
                if ( x2>= 0 && x3<= 21)
                  {
                     Serial.println("ignore");
                    }
                if ( x2 >100)
                  {
                     Serial.println("no one");
                   }
               else
                  {
                      if( x2 == x3)
                      {
                        Serial.println("static1");
                       a1="static1";
                     
                      }

                      if( x2 > x3)
                        {
                          Serial.println("away1");
                          a1="away1";
                          }
                      if( x2 < x3)
                        {
                          Serial.println("towards1");
                          a1="towards1";
                          }
                      x2=x3;
                    }
             }

             //JSN2 END

             //ultrasonic start
             {
             if(x4>55 && x4<450)
               {
                    Serial.println("lowered surface");
                    Serial.print( x); // Convert ping time to distance in cm and print result (0 = outside set distance range)
                    Serial.println("cm");
                    a8="lowered";
                }
            if(x4>25 && x4<=54)
                {
                    Serial.println("elevated surface");
                    Serial.print( x); // Convert ping time to distance in cm and print result (0 = outside set distance range)
                    Serial.println("cm");
                    a8="elevated";
                }
             }
             //button1
         {
           buttonState1 = digitalRead(buttonPin1);
           if (buttonState1 == HIGH)
           {
                  Serial.println("SOS");
                  a2="SYES";
            }
           else {
                    Serial.println("OFF");
                    a2="SNO";
                 }
           }

//button2
          {
            buttonState2 = digitalRead(buttonPin2);
            if (buttonState2 == HIGH)
            {
                Serial.println("NAVI");
                a3="NYES";
              }
            else
            {
                Serial.println("OFF");
                a3="NNO";
             }
          }


//button3
          {
            buttonState3 = digitalRead(buttonPin3);
            if (buttonState3 == HIGH)
            {
                Serial.println("cam");
                a4="cYES";
              }
            else
            {
                Serial.println("OFF");
                a4="cNO";
             }
          }



//button4
          {
            buttonState4 = digitalRead(buttonPin4);
            if (buttonState4 == HIGH)
            {
                Serial.println("face");
                a5="fYES";
              }
            else
            {
                Serial.println("OFF");
                a5="fNO";
             }
          }

         
//button5
          {
            buttonState5 = digitalRead(buttonPin5);
            if (buttonState5 == HIGH)
            {
                Serial.println("bar");
                a6="bYES";
              }
            else
            {
                Serial.println("OFF");
                a6="bNO";
             }
          }
//adxl

//adxl
 
  Serial.print(analogRead(xpin));
  Serial.print("\t");
  Serial.print(analogRead(ypin));
  Serial.print("\t");
  Serial.print(analogRead(zpin));

//stick is vertical
if(analogRead(ypin)>=425 && analogRead(ypin)<=460)
  {
    Serial.println("stick is properly oriented");
  }

 
//Inclination towards user
if(analogRead(zpin)>=1920 && analogRead(zpin)<=2200)
  {
    delay(100);
  if(analogRead(zpin)>=1920 && analogRead(zpin)<=2200)
      {
        Serial.println("stick is inclined towards user");
        a7="towards user";
      }
  }


 
//Inclination away frm user
if(analogRead(zpin)>=1700 && analogRead(zpin)<=1850)
  {
    delay(100);
    if(analogRead(zpin)>=1700 && analogRead(zpin)<=1850)
      {
        Serial.println("stick is inclined away from user");
        a7="away user";

      }
   }

   
//stick fall
if(analogRead(ypin)>=300 && analogRead(ypin)<=400)
  {
    delay(3000);
  if(analogRead(ypin)>=300 && analogRead(ypin)<=400)
      {
          Serial.println("user fall");
          a7="user fall";
      }
  }

 //water
 {
  w=touchRead(T0);
    Serial.println(w);  // get value using T0
 

    if(w==0)
    {
      Serial.println("water detected");
      a9="water detected";
    }
  }
       // ECE END

          /*  digitalWrite(trigPin, LOW);
           delayMicroseconds(2);
           // Sets the trigPin on HIGH state for 10 micro seconds
            digitalWrite(trigPin, HIGH);
            delayMicroseconds(10);
            digitalWrite(trigPin, LOW);
            duration = pulseIn(echoPin, HIGH);
            // Calculating the distance
            distance= duration*0.034/2;
            distance1=distance+10;
            distance2=distance+20;*/
                 
            s=a+","+a1+","+a2+","+a3+","+a4+","+a5+","+a6+","+a7+","+a8+","+a9;
            Serial.println(s);
            // Return the response
            client.println("HTTP/1.1 200 OK");
            client.println("Content-Type: text/html");
            client.println("");
           // client.println("<!DOCTYPE HTML>");
          //  client.println("<html><body>");
            client.println(s);
         //   client.println("</body></html>");
            client.stop();                    //close the connection
            delayMicroseconds(1);
            client.flush();
        }
        delayMicroseconds(15);
    }
}

void setup()
{
    Serial.begin(115200);
   
    //Connecting to a WiFi network
    Serial.println("");
    Serial.print("Connecting to ");
    Serial.println(ssid);
    WiFi.config(ip, gateway, subnet);
    WiFi.begin(ssid, password);
    while (WiFi.status() != WL_CONNECTED)
    {
        delayMicroseconds(50);
       Serial.print(".");
    }
    Serial.println("");
    Serial.println("WiFi connected");
    Serial.println("IP address: ");
    Serial.println(WiFi.localIP());
    server.begin();
    Serial.println("Server started");
 

   //buttom
   pinMode(buttonPin1, INPUT);
   pinMode(buttonPin2, INPUT);
   pinMode(buttonPin3, INPUT);
   pinMode(buttonPin4, INPUT);
   pinMode(buttonPin5, INPUT);
   
   
      //create a task that will be executed in the Task2code() function, with priority 1 and executed on core 1
      xTaskCreatePinnedToCore(
                        Task2code,   /* Task function. */
                        "Task2",     /* name of task. */
                        10000,       /* Stack size of task */
                        NULL,        /* parameter of the task */
                        1,           /* priority of the task */
                        &Task2,      /* Task handle to keep track of created task */
                        1);          /* pin task to core 1 */
    delayMicroseconds(50);
}

void loop()
{
    delay(20) ;
    if(WiFi.status() != WL_CONNECTED)
    {
        Serial.println("WiFi disconnected");
        Serial.print("Reconnecting to ");
        Serial.println(ssid);
        WiFi.config(ip, gateway, subnet);
        WiFi.begin(ssid, password);
   
        while (WiFi.status() != WL_CONNECTED)
        {
            delayMicroseconds(50);
            Serial.print(".");
        }
        Serial.println("WiFi connected");
    }  
}
