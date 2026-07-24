package com.tuowei.dazhongdianping.module.admin.user.mapper;

import com.tuowei.dazhongdianping.module.admin.user.model.AdminAppUserQuery;
import com.tuowei.dazhongdianping.module.admin.user.model.AdminAppUserRow;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface AdminAppUserMapper {

    long countUsers(@Param("query") AdminAppUserQuery query);

    List<AdminAppUserRow> selectUsers(@Param("query") AdminAppUserQuery query);

    AdminAppUserRow selectUserById(@Param("userId") Long userId);

    int updateUserStatus(@Param("userId") Long userId,
                         @Param("expectedStatus") Integer expectedStatus,
                         @Param("status") Integer status);

    long countReviewsByUserId(@Param("userId") Long userId);

    long countPostsByUserId(@Param("userId") Long userId);

    long countOrdersByUserId(@Param("userId") Long userId);

    long countReservationsByUserId(@Param("userId") Long userId);

    long countFavoritesByUserId(@Param("userId") Long userId);

    long countActiveSessionsByUserId(@Param("userId") Long userId);
}
