package com.tuowei.dazhongdianping.module.admin.auth.service;

import com.tuowei.dazhongdianping.common.admin.AdminSession;
import com.tuowei.dazhongdianping.common.api.ForbiddenException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import org.springframework.stereotype.Service;

@Service
public class AdminPermissionChecker {
    public void require(AdminSession session, String permission, boolean regionScoped) {
        if (regionScoped && !session.regions().contains(RegionContext.getRegion().name())) {
            throw new ForbiddenException("当前管理员无权操作该区域");
        }
        if (permission != null && !permission.isBlank() && !session.permissions().contains(permission)) {
            throw new ForbiddenException("没有权限执行该操作");
        }
    }
}
