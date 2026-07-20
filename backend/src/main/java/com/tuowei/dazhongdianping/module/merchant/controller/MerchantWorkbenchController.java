package com.tuowei.dazhongdianping.module.merchant.controller;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.Region;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.browse.model.ShopListQuery;
import com.tuowei.dazhongdianping.module.browse.model.response.ShopListItemResponse;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSession;
import com.tuowei.dazhongdianping.module.merchant.auth.MerchantSessionContext;
import com.tuowei.dazhongdianping.module.merchant.auth.service.MerchantAuthService;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantLoginRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantRejectReservationRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantRegisterRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantSettlementApplyRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantStaffCreateRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantStaffStatusRequest;
import com.tuowei.dazhongdianping.module.merchant.model.request.MerchantStaffUpdateRequest;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantAccountResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantHealthResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantLoginResponse;
import com.tuowei.dazhongdianping.module.merchant.model.response.MerchantRoleListResponse;
import com.tuowei.dazhongdianping.module.merchant.service.MerchantFulfillmentService;
import com.tuowei.dazhongdianping.module.merchant.service.MerchantWorkbenchService;
import com.tuowei.dazhongdianping.module.merchant.service.MerchantReservationService;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantIdentityService;
import com.tuowei.dazhongdianping.module.merchant.identity.service.MerchantStaffService;
import com.tuowei.dazhongdianping.module.reservation.model.request.ReservationRescheduleRequest;
import com.tuowei.dazhongdianping.module.merchant.dashboard.service.MerchantDashboardService;
import jakarta.validation.Valid;
import java.util.Map;
import java.time.LocalDate;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/b/v1")
public class MerchantWorkbenchController {

    private final MerchantWorkbenchService merchantWorkbenchService;
    private final MerchantAuthService merchantAuthService;
    private final MerchantFulfillmentService merchantFulfillmentService;
    private final MerchantIdentityService merchantIdentityService;
    private final MerchantStaffService merchantStaffService;
    private final MerchantReservationService merchantReservationService;
    private final MerchantDashboardService merchantDashboardService;

    public MerchantWorkbenchController(MerchantWorkbenchService merchantWorkbenchService,
                                       MerchantAuthService merchantAuthService,
                                       MerchantFulfillmentService merchantFulfillmentService,
                                       MerchantIdentityService merchantIdentityService,
                                       MerchantStaffService merchantStaffService,
                                       MerchantReservationService merchantReservationService,
                                       MerchantDashboardService merchantDashboardService) {
        this.merchantWorkbenchService = merchantWorkbenchService;
        this.merchantAuthService = merchantAuthService;
        this.merchantFulfillmentService = merchantFulfillmentService;
        this.merchantIdentityService = merchantIdentityService;
        this.merchantStaffService = merchantStaffService;
        this.merchantReservationService = merchantReservationService;
        this.merchantDashboardService = merchantDashboardService;
    }

    @GetMapping("/health")
    public ApiResponse<MerchantHealthResponse> health() {
        return ApiResponse.success(new MerchantHealthResponse("merchant-workbench", "ok"));
    }

    @PostMapping("/auth/login")
    public ApiResponse<MerchantLoginResponse> login(@Valid @RequestBody MerchantLoginRequest request) {
        MerchantAuthService.MerchantLoginResult result = merchantAuthService.login(request.account(), request.password());
        return ApiResponse.success(
                "登录成功",
                "merchant.login_success",
                new MerchantLoginResponse(
                        result.accessToken(),
                        "Bearer",
                        result.session().merchantId(),
                        result.session().account()
                )
        );
    }

    @PostMapping("/auth/register")
    public ApiResponse<Map<String, Object>> register(@Valid @RequestBody MerchantRegisterRequest request) {
        return ApiResponse.success("注册成功", "merchant.register_success", merchantIdentityService.register(request));
    }

    @PostMapping("/settle/apply")
    public ApiResponse<Map<String, Object>> applySettlement(
            @Valid @RequestBody MerchantSettlementApplyRequest request
    ) {
        return ApiResponse.success("资质已提交", "merchant.settlement_submitted", merchantIdentityService.apply(request));
    }

    @GetMapping("/settle/status")
    public ApiResponse<Map<String, Object>> settlementStatus() {
        return ApiResponse.success(merchantIdentityService.status());
    }

    @PostMapping("/staffs")
    public ApiResponse<Map<String, Object>> createStaff(@Valid @RequestBody MerchantStaffCreateRequest request) {
        return ApiResponse.success("员工已创建", "merchant.staff_created", merchantStaffService.create(request));
    }

    @GetMapping("/staffs")
    public ApiResponse<PageResult<Map<String, Object>>> listStaffs(
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(merchantStaffService.list(page, pageSize));
    }

    @PutMapping("/staffs/{id}")
    public ApiResponse<Map<String, Object>> updateStaff(
            @PathVariable Long id,
            @Valid @RequestBody MerchantStaffUpdateRequest request
    ) {
        return ApiResponse.success("员工已更新", "merchant.staff_updated", merchantStaffService.update(id, request));
    }

    @PutMapping("/staffs/{id}/status")
    public ApiResponse<Map<String, Object>> changeStaffStatus(
            @PathVariable Long id,
            @Valid @RequestBody MerchantStaffStatusRequest request
    ) {
        return ApiResponse.success("员工状态已更新", "merchant.staff_status_updated", merchantStaffService.changeStatus(id, request.status()));
    }

    @GetMapping("/account/me")
    public ApiResponse<MerchantAccountResponse> accountMe() {
        return ApiResponse.success(merchantWorkbenchService.getAccountSummary(currentMerchant(), currentRegion()));
    }

    @GetMapping("/roles")
    public ApiResponse<MerchantRoleListResponse> roles() {
        return ApiResponse.success(merchantWorkbenchService.listRoles(currentMerchant(), currentRegion()));
    }

    @GetMapping("/shops")
    public ApiResponse<PageResult<ShopListItemResponse>> shops(@Valid ShopListQuery query) {
        return ApiResponse.success(merchantWorkbenchService.listShops(currentMerchant(), currentRegion(), query));
    }

    @PostMapping("/reservations/{id}/confirm")
    public ApiResponse<Map<String, Object>> confirmReservation(@PathVariable Long id) {
        return ApiResponse.success(merchantFulfillmentService.confirm(id));
    }

    @GetMapping("/reservations")
    public ApiResponse<PageResult<Map<String, Object>>> reservations(
            @RequestParam(required = false) Long shopId,
            @RequestParam(required = false) Integer status,
            @RequestParam(required = false) LocalDate dateFrom,
            @RequestParam(required = false) LocalDate dateTo,
            @RequestParam(required = false) Integer page,
            @RequestParam(required = false) Integer pageSize
    ) {
        return ApiResponse.success(merchantReservationService.list(
                shopId, status, dateFrom, dateTo, page, pageSize
        ));
    }

    @GetMapping("/reservations/{id}")
    public ApiResponse<Map<String, Object>> reservationDetail(@PathVariable Long id) {
        return ApiResponse.success(merchantReservationService.detail(id));
    }

    @PostMapping("/reservations/{id}/reschedule")
    public ApiResponse<Map<String, Object>> rescheduleReservation(
            @PathVariable Long id,
            @Valid @RequestBody ReservationRescheduleRequest request
    ) {
        return ApiResponse.success(merchantReservationService.reschedule(id, request));
    }

    @PostMapping("/reservations/{id}/reject")
    public ApiResponse<Map<String, Object>> rejectReservation(
            @PathVariable Long id,
            @Valid @RequestBody MerchantRejectReservationRequest request
    ) {
        return ApiResponse.success(merchantFulfillmentService.reject(id, request.reason()));
    }

    @PostMapping("/reservations/{id}/arrive")
    public ApiResponse<Map<String, Object>> arriveReservation(@PathVariable Long id) {
        return ApiResponse.success(merchantFulfillmentService.arrive(id));
    }

    @PostMapping("/reservations/{id}/no-show")
    public ApiResponse<Map<String, Object>> markReservationNoShow(@PathVariable Long id) {
        return ApiResponse.success(merchantFulfillmentService.noShow(id));
    }

    @PostMapping("/coupons/{code}/verify")
    public ApiResponse<Map<String, Object>> verifyCoupon(@PathVariable String code) {
        return ApiResponse.success(merchantFulfillmentService.verifyCoupon(code));
    }

    @GetMapping("/dashboard")
    public ApiResponse<Map<String,Object>> dashboard(
            @RequestParam(required=false) Long shopId,
            @RequestParam(required=false) LocalDate dateFrom,
            @RequestParam(required=false) LocalDate dateTo
    ) {
        return ApiResponse.success(merchantDashboardService.dashboard(shopId,dateFrom,dateTo));
    }

    private Region currentRegion() {
        return RegionContext.getRegion();
    }

    private MerchantSession currentMerchant() {
        return MerchantSessionContext.get();
    }
}
