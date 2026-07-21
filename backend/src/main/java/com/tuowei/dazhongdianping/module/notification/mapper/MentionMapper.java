package com.tuowei.dazhongdianping.module.notification.mapper;

import com.tuowei.dazhongdianping.module.notification.model.MentionUserRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface MentionMapper {
    List<MentionUserRow> selectActiveUsersByNicknames(@Param("nicknames") List<String> nicknames);
}
