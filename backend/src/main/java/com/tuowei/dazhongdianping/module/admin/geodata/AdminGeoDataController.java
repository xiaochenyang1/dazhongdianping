package com.tuowei.dazhongdianping.module.admin.geodata;

import com.tuowei.dazhongdianping.common.api.ApiResponse;
import com.tuowei.dazhongdianping.module.admin.auth.AdminPermission;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.AreaSaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CategorySaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.CitySaveRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.request.GeoStatusRequest;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminAreaResponse;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminCategoryResponse;
import com.tuowei.dazhongdianping.module.admin.geodata.model.response.AdminCityResponse;
import jakarta.validation.Valid;
import java.util.List;
import org.springframework.web.bind.annotation.DeleteMapping;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.PutMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RequestParam;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/api/admin/v1")
public class AdminGeoDataController {

    private final AdminGeoDataService service;

    public AdminGeoDataController(AdminGeoDataService service) {
        this.service = service;
    }

    @GetMapping("/categories")
    @AdminPermission("data:geo:read")
    public ApiResponse<List<AdminCategoryResponse>> categories() {
        return ApiResponse.success(service.listCategories());
    }

    @PostMapping("/categories")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCategoryResponse> createCategory(@Valid @RequestBody CategorySaveRequest request) {
        return ApiResponse.success(service.createCategory(request));
    }

    @PutMapping("/categories/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCategoryResponse> updateCategory(
            @PathVariable Long id, @Valid @RequestBody CategorySaveRequest request) {
        return ApiResponse.success(service.updateCategory(id, request));
    }

    @PutMapping("/categories/{id}/status")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCategoryResponse> updateCategoryStatus(
            @PathVariable Long id, @Valid @RequestBody GeoStatusRequest request) {
        return ApiResponse.success(service.updateCategoryStatus(id, request.status()));
    }

    @DeleteMapping("/categories/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<Void> deleteCategory(@PathVariable Long id) {
        service.deleteCategory(id);
        return ApiResponse.success("分类已删除", "admin.geo.category_deleted", null);
    }

    @GetMapping("/cities")
    @AdminPermission("data:geo:read")
    public ApiResponse<List<AdminCityResponse>> cities() {
        return ApiResponse.success(service.listCities());
    }

    @PostMapping("/cities")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCityResponse> createCity(@Valid @RequestBody CitySaveRequest request) {
        return ApiResponse.success(service.createCity(request));
    }

    @PutMapping("/cities/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCityResponse> updateCity(
            @PathVariable Long id, @Valid @RequestBody CitySaveRequest request) {
        return ApiResponse.success(service.updateCity(id, request));
    }

    @PutMapping("/cities/{id}/status")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminCityResponse> updateCityStatus(
            @PathVariable Long id, @Valid @RequestBody GeoStatusRequest request) {
        return ApiResponse.success(service.updateCityStatus(id, request.status()));
    }

    @DeleteMapping("/cities/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<Void> deleteCity(@PathVariable Long id) {
        service.deleteCity(id);
        return ApiResponse.success("城市已删除", "admin.geo.city_deleted", null);
    }

    @GetMapping("/areas")
    @AdminPermission("data:geo:read")
    public ApiResponse<List<AdminAreaResponse>> areas(@RequestParam(required = false) Long cityId) {
        return ApiResponse.success(service.listAreas(cityId));
    }

    @PostMapping("/areas")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminAreaResponse> createArea(@Valid @RequestBody AreaSaveRequest request) {
        return ApiResponse.success(service.createArea(request));
    }

    @PutMapping("/areas/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminAreaResponse> updateArea(
            @PathVariable Long id, @Valid @RequestBody AreaSaveRequest request) {
        return ApiResponse.success(service.updateArea(id, request));
    }

    @PutMapping("/areas/{id}/status")
    @AdminPermission("data:geo:write")
    public ApiResponse<AdminAreaResponse> updateAreaStatus(
            @PathVariable Long id, @Valid @RequestBody GeoStatusRequest request) {
        return ApiResponse.success(service.updateAreaStatus(id, request.status()));
    }

    @DeleteMapping("/areas/{id}")
    @AdminPermission("data:geo:write")
    public ApiResponse<Void> deleteArea(@PathVariable Long id) {
        service.deleteArea(id);
        return ApiResponse.success("商圈已删除", "admin.geo.area_deleted", null);
    }
}
