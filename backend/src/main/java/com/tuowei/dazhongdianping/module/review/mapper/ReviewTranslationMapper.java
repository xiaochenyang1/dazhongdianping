package com.tuowei.dazhongdianping.module.review.mapper;

import com.tuowei.dazhongdianping.module.review.model.ReviewTranslationRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ReviewTranslationMapper {

    ReviewTranslationRow selectByUser(
            @Param("reviewId") Long reviewId,
            @Param("userId") Long userId,
            @Param("targetLang") String targetLang);

    void insert(ReviewTranslationRow row);

    int updateContent(@Param("id") Long id, @Param("content") String content);

    ReviewTranslationRow selectById(@Param("id") Long id);

    List<ReviewTranslationRow> selectByReview(
            @Param("reviewId") Long reviewId,
            @Param("region") String region,
            @Param("targetLang") String targetLang);
}
