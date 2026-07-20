package com.tuowei.dazhongdianping.module.reservation.mapper;

import com.tuowei.dazhongdianping.module.reservation.model.ReservationLogRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationRow;
import com.tuowei.dazhongdianping.module.reservation.model.ReservationSlotRow;
import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import org.apache.ibatis.annotations.Mapper;
import org.apache.ibatis.annotations.Param;

@Mapper
public interface ReservationMapper {

    List<ReservationSlotRow> selectSlots(
            @Param("shopId") Long shopId,
            @Param("region") String region,
            @Param("date") LocalDate date
    );

    ReservationSlotRow selectSlot(
            @Param("slotId") Long slotId,
            @Param("shopId") Long shopId,
            @Param("region") String region
    );

    int reserveCapacity(@Param("slotId") Long slotId, @Param("people") Integer people);

    int releaseCapacity(@Param("slotId") Long slotId, @Param("people") Integer people);

    void insertReservation(ReservationRow row);

    ReservationRow selectUserReservation(
            @Param("id") Long id,
            @Param("userId") Long userId,
            @Param("region") String region
    );

    ReservationRow selectMerchantReservation(
            @Param("id") Long id,
            @Param("merchantId") Long merchantId,
            @Param("region") String region
    );

    long countUserReservations(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status
    );

    List<ReservationRow> selectUserReservations(
            @Param("userId") Long userId,
            @Param("region") String region,
            @Param("status") Integer status,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    long countMerchantReservations(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("shopIds") List<Long> shopIds,
            @Param("shopId") Long shopId,
            @Param("status") Integer status,
            @Param("dateFrom") LocalDate dateFrom,
            @Param("dateTo") LocalDate dateTo
    );

    List<ReservationRow> selectMerchantReservations(
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("shopIds") List<Long> shopIds,
            @Param("shopId") Long shopId,
            @Param("status") Integer status,
            @Param("dateFrom") LocalDate dateFrom,
            @Param("dateTo") LocalDate dateTo,
            @Param("limit") Integer limit,
            @Param("offset") Integer offset
    );

    int cancelReservation(@Param("id") Long id, @Param("userId") Long userId);

    int rescheduleReservation(
            @Param("id") Long id,
            @Param("userId") Long userId,
            @Param("slotId") Long slotId,
            @Param("reserveTime") LocalDateTime reserveTime,
            @Param("status") Integer status
    );

    int updateMerchantStatus(
            @Param("id") Long id,
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("fromStatus") Integer fromStatus,
            @Param("toStatus") Integer toStatus
    );

    int rescheduleMerchantReservation(
            @Param("id") Long id,
            @Param("merchantId") Long merchantId,
            @Param("region") String region,
            @Param("slotId") Long slotId,
            @Param("reserveTime") LocalDateTime reserveTime,
            @Param("status") Integer status
    );

    void insertLog(ReservationLogRow row);

    List<ReservationLogRow> selectLogs(@Param("reservationId") Long reservationId);
}
