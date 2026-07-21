package com.tuowei.dazhongdianping.module.admin.privacy.mapper;

import com.tuowei.dazhongdianping.module.admin.privacy.model.AdminPrivacyTaskQuery;
import com.tuowei.dazhongdianping.module.admin.privacy.model.AdminPrivacyTaskRow;
import java.util.List;

public interface AdminPrivacyMapper {

    long countPrivacyTasks(AdminPrivacyTaskQuery query);

    List<AdminPrivacyTaskRow> selectPrivacyTasks(AdminPrivacyTaskQuery query);
}
