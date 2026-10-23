package com.tuowei.dazhongdianping.module.auth.service;

import com.tuowei.dazhongdianping.config.PrivacyProperties;
import com.tuowei.dazhongdianping.module.auth.mapper.UserPrivacyMapper;
import com.tuowei.dazhongdianping.module.auth.model.PrivacyExportTaskRow;
import java.io.IOException;
import java.nio.file.Files;
import java.nio.file.Path;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Propagation;
import org.springframework.transaction.annotation.Transactional;

@Service
public class UserPrivacyArchiveService {
    private static final Logger log = LoggerFactory.getLogger(UserPrivacyArchiveService.class);
    private final UserPrivacyMapper mapper;
    private final Path exportBaseDir;

    public UserPrivacyArchiveService(UserPrivacyMapper mapper, PrivacyProperties properties) {
        this.mapper = mapper;
        this.exportBaseDir = Path.of(properties.getExportBaseDir()).toAbsolutePath().normalize();
    }

    // A separate transaction is essential when called from the deletion transaction's afterCommit callback.
    @Transactional(propagation = Propagation.REQUIRES_NEW)
    public void cleanupExpiredArchives() {
        for (PrivacyExportTaskRow task : mapper.selectExpiredOrRevokedExportTasks(100)) {
            try {
                Path path = Path.of(task.getFilePath()).toAbsolutePath().normalize();
                if (!path.startsWith(exportBaseDir) || path.equals(exportBaseDir)) {
                    throw new IllegalArgumentException("invalid archive location");
                }
                Files.deleteIfExists(path);
                mapper.clearExportFile(task.getId());
            } catch (IOException | RuntimeException exception) {
                log.warn("Privacy archive cleanup will retry for task {} ({})", task.getId(), exception.getClass().getSimpleName());
            }
        }
    }
}
