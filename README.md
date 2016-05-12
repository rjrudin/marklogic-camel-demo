# marklogic-camel-demo

This application shows how Camel and MarkLogic can work together. Assuming you have at least MarkLogic 8.0-4 installed 
(may work on earlier versions of MarkLogic 8), you can get this up and running easily by following these steps 
(note that you'll need NodeJS and npm and bower installed - grab the latest version of each if possible):

(CAUTION - I haven't tested these yet in a "clean" environment that doesn't have a bunch of Node modules lying around already. Will do that soon.)

1. ./gradlew mlDeploy (deploys the MarkLogic portion of the application to MarkLogic)
1. npm install (installs gulp and some other related tools) 
1. bower install (downloads all the webapp dependencies)
1. gulp build (builds the webapp)
1. ./gradlew bootRun (fires up the webapp on Spring Boot on port 8080)

Those steps will deploy the application to MarkLogic and fire up a Spring Boot webapp on port 8080. 

Next, you need to use a different Gradle task to run Camel:

1. ./gradlew camelRun

You can then copy any file to ./inbox/mlcp to ingest it, and you can copy shapefiles to ./inbox/shapefiles to
ingest those. Shapefiles can be obtained from a number of public repositories - one is http://www.gadm.org/country .

To try out the GDELT ingest, modify the RunCamel.java file - search for "autoStartup" in the file and change its
value to true. Then restart Camel - run camelRun again - and the program will ingest the latest GDELT event file.
This Camel route can be easily modified to run every 15 minutes, for example - see http://camel.apache.org/timer.html
for more information.

