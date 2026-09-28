package com.tuowei.dazhongdianping.module.guide.mapper;

import com.tuowei.dazhongdianping.module.guide.model.GuideArticleRow;
import com.tuowei.dazhongdianping.module.guide.model.GuideSectionRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface GuideMapper {

    List<GuideArticleRow> selectPublished(
            @Param("region") String region, @Param("limit") int limit, @Param("offset") int offset);

    long countPublished(@Param("region") String region);

    List<GuideArticleRow> selectAdmin(
            @Param("region") String region, @Param("limit") int limit, @Param("offset") int offset);

    long countAdmin(@Param("region") String region);

    GuideArticleRow selectById(@Param("id") Long id, @Param("region") String region);

    List<GuideSectionRow> selectSections(@Param("articleId") Long articleId);

    void insertArticle(GuideArticleRow row);

    int updateArticle(GuideArticleRow row);

    int updateStatus(@Param("id") Long id, @Param("region") String region, @Param("status") int status);

    void deleteSections(@Param("articleId") Long articleId);

    void insertSection(GuideSectionRow row);
}
