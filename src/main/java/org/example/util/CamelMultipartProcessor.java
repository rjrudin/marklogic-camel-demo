package org.example.util;

import java.io.File;

import org.apache.camel.Exchange;
import org.apache.camel.Processor;
import org.apache.http.entity.mime.MultipartEntityBuilder;

public class CamelMultipartProcessor implements Processor {

    @Override
    public void process(Exchange exchange) throws Exception {
        File f = exchange.getIn().getBody(File.class);
        MultipartEntityBuilder entity = MultipartEntityBuilder.create();
        entity.addBinaryBody("upload", f);
        exchange.getOut().setBody(entity.build());
    }

}
