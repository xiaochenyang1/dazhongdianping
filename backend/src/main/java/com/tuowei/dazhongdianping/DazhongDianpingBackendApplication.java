package com.tuowei.dazhongdianping;

import com.tuowei.dazhongdianping.config.FileStorageProperties;
import com.tuowei.dazhongdianping.config.InfrastructureProperties;
import com.tuowei.dazhongdianping.config.PrivacyProperties;
import com.tuowei.dazhongdianping.config.SearchProperties;
import com.tuowei.dazhongdianping.config.SendCodeRateLimitProperties;
import org.mybatis.spring.annotation.MapperScan;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.boot.context.properties.EnableConfigurationProperties;
import org.springframework.scheduling.annotation.EnableScheduling;

@SpringBootApplication
@EnableScheduling
@MapperScan("com.tuowei.dazhongdianping.module")
@EnableConfigurationProperties({
        FileStorageProperties.class,
        InfrastructureProperties.class,
        SendCodeRateLimitProperties.class,
        PrivacyProperties.class,
        SearchProperties.class
})
public class DazhongDianpingBackendApplication {

    public static void main(String[] args) {
        SpringApplication.run(DazhongDianpingBackendApplication.class, args);
    }
}
