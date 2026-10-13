package com.tuowei.dazhongdianping.module.moderation.service;

import com.tuowei.dazhongdianping.module.moderation.mapper.AutomodHitMapper;
import com.tuowei.dazhongdianping.module.moderation.model.AutomodHitRow;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AutomodHitWriter {

    private final AutomodHitMapper mapper;

    public AutomodHitWriter(AutomodHitMapper mapper) {
        this.mapper = mapper;
    }

    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void record(AutomodHitRow row) {
        mapper.insert(row);
    }
}
