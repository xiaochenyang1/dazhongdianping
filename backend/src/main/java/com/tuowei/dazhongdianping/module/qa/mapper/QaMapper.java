package com.tuowei.dazhongdianping.module.qa.mapper;

import com.tuowei.dazhongdianping.module.qa.model.ShopAnswerRow;
import com.tuowei.dazhongdianping.module.qa.model.ShopQuestionRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface QaMapper {

    boolean existsShop(@Param("shopId") Long shopId, @Param("region") String region);

    void insertQuestion(ShopQuestionRow row);

    List<ShopQuestionRow> selectQuestions(
            @Param("shopId") Long shopId, @Param("region") String region,
            @Param("limit") int limit, @Param("offset") int offset);

    long countQuestions(@Param("shopId") Long shopId, @Param("region") String region);

    ShopQuestionRow selectQuestion(
            @Param("id") Long id, @Param("shopId") Long shopId, @Param("region") String region);

    void insertAnswer(ShopAnswerRow row);

    int incrementAnswerCount(@Param("questionId") Long questionId);

    List<ShopAnswerRow> selectAnswers(@Param("questionId") Long questionId);
}
