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

#define TRIGGER_PIN 13// Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN 12// Arduino pin tied to echo pin on the ultrasonic sensor.
#define MAX_DISTANCE 450

#define TRIGGER_PIN1 14 // Arduino pin tied to trigger pin on the ultrasonic sensor.
#define ECHO_PIN1 27
#define MAX_DISTANCE1 450

const int buttonPin1 = 23; //button1SOS
const int buttonPin2 = 22; //button2NAVI

NewPing sonar(TRIGGER_PIN, ECHO_PIN, MAX_DISTANCE); // NewPing setup of pins and maximum distance.

NewPing sonar1(TRIGGER_PIN1, ECHO_PIN1, MAX_DISTANCE1);

MedianFilter filter(31,0);
MedianFilter filter1(31,0);


int x=0;
int x1=0;
int x2=0;
int x3=0;
String s;
String a;
String a1;
String a2;
String a3;
String a4;
int buttonState1 = 0; 
int buttonState2 = 0;

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
          filter.in(uS);
          o = filter.out();
          filter1.in(uS1);
          o1 = filter1.out();
          Serial.print("Ping: ");
          x = o / US_ROUNDTRIP_CM;
          x2 = o1 / US_ROUNDTRIP_CM;
          Serial.println( x);
          Serial.println("cm");
          Serial.println( x2);
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
             
             //button1
         {
           buttonState1 = digitalRead(buttonPin1);
           if (buttonState1 == HIGH) 
           {
                  Serial.println("SOS");
                  a2="SOS";
            }
           else {
                    Serial.println("OFF");
                 }
           }

//button2
          {
            buttonState2 = digitalRead(buttonPin2);
            if (buttonState2 == HIGH)
            {
                Serial.println("NAVI");
                a3="NAVI";
              }
            else 
            {
                Serial.println("OFF");
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
                 
            s=a+","+a1+","+a2+","+a3;
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
