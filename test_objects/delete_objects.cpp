#include <yarp/os/Network.h>
#include <yarp/sig/Vector.h>
#include <yarp/os/all.h>
#include <yarp/sig/all.h>
#include <yarp/dev/all.h>
#include <iostream>
#include <string>

using namespace yarp::sig;
using namespace yarp::os;



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


    yarp::os::Bottle cmd, rep;
    cmd.addString("deleteAll");
    toWorld.write(cmd, rep);

    std::string response = rep.get(0).asString();
    std::cout<<"operation outcome: "<< response <<"\n\n";
}
