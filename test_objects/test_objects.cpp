#include <yarp/os/Network.h>
#include <yarp/sig/Vector.h>
#include <yarp/os/all.h>
#include <yarp/sig/all.h>
#include <yarp/dev/all.h>
#include <iostream>
#include <string>

using namespace yarp::sig;
using namespace yarp::os;


void createSphere(
        yarp::os::Port& outPort, 
        double mass, double radius=0.02,
        double x=0, double y=0, double z=0,
        double yaw=0.0, double roll=0.0, double pitch=0.0,
        int red=255, int green=0, int blue=0, 
        std::string name="sphere", int gravity=0,  int collisions=0) 
{
    
    
    yarp::os::Bottle cmd, rep;

    cmd.addString("makeSphere");

    //radius in mt
    cmd.addDouble(mass);
    cmd.addDouble(radius);

    //pose
    cmd.addDouble(x); 
    cmd.addDouble(y);
    cmd.addDouble(z);  
    cmd.addDouble(yaw);  
    cmd.addDouble(roll);
    cmd.addDouble(pitch);

    // color
    cmd.addInt(red); 
    cmd.addInt(green);
    cmd.addInt(blue);

    //name
    cmd.addString(""); //frame
    cmd.addString(name); //name

    //physics
    cmd.addInt(gravity); 
    cmd.addInt(collisions);

    outPort.write(cmd, rep);
    std::cout << rep.get(0).asString() <<"\n";

}
void createBox(
        yarp::os::Port& outPort, 
        double mass, 
        double width, double height, double thickness,
        double x=0, double y=0, double z=0,
        double yaw=0.0, double roll=0.0, double pitch=0.0,
        int red=255, int green=0, int blue=0, 
        std::string name="sphere", int gravity=0,  int collisions=0) 
{
    
    
    yarp::os::Bottle cmd, rep;

    cmd.addString("makeBox");

    cmd.addDouble(mass);
    cmd.addDouble(width); 
    cmd.addDouble(height);
    cmd.addDouble(thickness);  
    
    //pose   
    cmd.addDouble(x); 
    cmd.addDouble(y);
    cmd.addDouble(z);  

    cmd.addDouble(yaw);  
    cmd.addDouble(roll);
    cmd.addDouble(pitch);

    // color
    cmd.addInt(red); 
    cmd.addInt(green);
    cmd.addInt(blue);

    //name
    cmd.addString(""); //frame
    cmd.addString(name); //name

    //physics
    cmd.addInt(gravity); 
    cmd.addInt(collisions);

    outPort.write(cmd, rep);
    std::cout << rep.get(0).asString() <<"\n";

}

void createCylinder(
        yarp::os::Port& outPort, 
        double mass, 
        double radius, double length,
        double x=0, double y=0, double z=0,
        double yaw=0.0, double roll=0.0, double pitch=0.0,
        int red=255, int green=0, int blue=0, 
        std::string name="sphere", int gravity=0,  int collisions=0) 
{
    
    
    yarp::os::Bottle cmd, rep;

    cmd.addString("makeCylinder");

    cmd.addDouble(mass);
    cmd.addDouble(radius); 
    cmd.addDouble(length);  
    
    //pose   
    cmd.addDouble(x); 
    cmd.addDouble(y);
    cmd.addDouble(z);  

    cmd.addDouble(yaw);  
    cmd.addDouble(roll);
    cmd.addDouble(pitch);

    // color
    cmd.addInt(red); 
    cmd.addInt(green);
    cmd.addInt(blue);

    //name
    cmd.addString(""); //frame
    cmd.addString(name); //name

    //physics
    cmd.addInt(gravity); 
    cmd.addInt(collisions);

    outPort.write(cmd, rep);
    std::cout << rep.get(0).asString() <<"\n";
}

int main()
{
   
    yarp::os::Network yarp;
    if (!yarp.checkNetwork())
    {
        std::cout<<"[FATAL] in main.cpp:\n\tNo Yarp Server running!!!\n";
        return -1;
    }

    yarp::os::Port toWorld;

    const std::string strToWorld = "/world_output_port";
    const std::string strFromWorld = "/world_input_port";

    toWorld.open(strToWorld);

    if( !(yarp::os::Network::connect(strToWorld, strFromWorld)))
    {
        std::cout<<"\n[FATAL] gazeboWorld::init()\n";
        std::cout<<"Problems connecting to simulated world\n";
        std::exit(0);
    }

    createSphere(toWorld, 
         // mass radius  x    y    z      yaw  roll pitch   red green blue    name   gravity collisions
            1.0, 0.05,   1.0, 1.0, 1.0,   0.0, 0.0, 0.0,    255,  100,   0,   "mySphere",  1,      1);
    std::cout << "waiting for a char to end...";
    createSphere(toWorld, 
         // mass radius  x    y    z      yaw  roll pitch   red green blue    name   gravity collisions
            1.0, 0.05,   -1.0, -1.0, 1.0,   0.0, 0.0, 0.0,    255,  100,   0,   "myOtherSphere",  1,      1);
    std::cout << "waiting for a char to end...";
        
    
    createBox(toWorld, 
         // mass w     h     t      x    y    z      yaw  roll pitch   red green blue    name   gravity collisions
            1.0, 0.05, 0.05, 0.05,  1.0, -1.0, 1.0,   0.0, 0.0, 0.0,    255,  100,   0,   "myBox",  1,      1);
    std::cout << "waiting for a char to end...";
    
    char c;
    std::cin >> c;



    yarp::os::Bottle cmd, rep;
    cmd.addString("deleteAll");
    toWorld.write(cmd, rep);

    std::string response = rep.get(0).asString();
    std::cout<<"operation outcome: "<< response <<"\n\n";
}
