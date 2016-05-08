package org.example.util;

import org.apache.camel.Exchange;
import org.apache.camel.builder.RouteBuilder;
import org.apache.camel.main.Main;

public class RunCamel {

    public static void main(String[] args) throws Exception {
        Main main = new Main();
        main.addRouteBuilder(new MyRouteBuilder());
        System.out.println("Starting Camel. Use ctrl + c to terminate the JVM.\n");
        main.run();
    }

    private static class MyRouteBuilder extends RouteBuilder {
        @Override
        public void configure() throws Exception {
            from("file://inbox/mlcp")
                .to("mlcp:localhost:8500?username=admin&password=admin&options_file=mlcp-inbox-options.txt");

            from("file://inbox/shapefiles")
                .multicast()
                .parallelProcessing()
                .to("direct:ingestShapefile", "direct:processShapefile")
                .end();

            from("direct:ingestShapefile")
                .log("Ingest shapefile via mlcp")
                .to("mlcp:localhost:8500?username=admin&password=admin&options_file=mlcp-shapefile-options.txt");

            from("direct:processShapefile")
                .log("Processing shapefile")
                .process(new CamelMultipartProcessor())
                .setHeader(Exchange.HTTP_QUERY, constant("targetSrs=WGS84"))
                .setHeader(Exchange.HTTP_METHOD, constant("POST"))
                .setHeader(Exchange.CONTENT_TYPE, constant("multipart/form-data; boundary=\"gc0p4Jq0M2Yt08jU534c0p\""))
                .log("Sending shapefile to Ogre")
                .to("http4://ogre.adc4gis.com/convert")
                .setHeader(Exchange.HTTP_QUERY, constant("extension=json&collection=geo-json&transform=geo-json"))
                .setHeader(Exchange.HTTP_METHOD, constant("POST"))
                .setHeader(Exchange.CONTENT_TYPE, constant("application/json"))
                .log("Ingesting GeoJSON via MarkLogic REST API")
                .to("http4://localhost:8500/v1/documents")
                .log("Finished processing shapefile");

            from("timer:foo?repeatCount=1")
                .autoStartup(false)
                .to("http4://data.gdeltproject.org/gdeltv2/lastupdate.txt")
                .log("Received last update content")
                .split(bodyAs(String.class).tokenize("\n"))
                .choice()
                .when(body().contains("export"))
                .split(bodyAs(String.class).tokenize(" "))
                .choice()
                .when(body().contains("export"))
                .setHeader(Exchange.HTTP_URI, bodyAs(String.class))
                .setHeader("GdeltDataset", bodyAs(String.class))
                .log("Retrieving ${body}")
                .setHeader(Exchange.HTTP_METHOD, constant(org.apache.camel.component.http4.HttpMethods.GET))
                .to("http4://will-be-replaced")
                .removeHeader(Exchange.HTTP_URI)
                .unmarshal()
                .zipFile()
                .split(bodyAs(String.class).tokenize("\n"))
                .setHeader(Exchange.HTTP_METHOD, constant(org.apache.camel.component.http4.HttpMethods.POST))
                .setHeader(Exchange.HTTP_QUERY, simple("extension=xml&collection=gdelt&transform=gdelt&trans:dataset=${header.GdeltDataset}"))
                .setHeader(Exchange.CONTENT_TYPE, constant("text/plain"))
                .to("http4://localhost:8500/v1/documents?authUsername=admin&authPassword=admin")
                .end()
                .log("All done")
            ;
        }
    }
}

