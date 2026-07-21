package com.tuowei.dazhongdianping.module.admin.auth.service;

import com.tuowei.dazhongdianping.module.admin.auth.model.response.AdminMenuResponse;
import java.util.ArrayList;
import java.util.List;
import java.util.Set;
import org.springframework.stereotype.Service;

@Service
public class AdminMenuService {
    public List<AdminMenuResponse> menus(Set<String> permissions) {
        List<MenuNode> roots = List.of(
                leaf("dashboard", "控制台", "/dashboard", "dashboard:read"),
                group("audit", "审核中心", "/audit", List.of(
                        leaf("audit.reviews", "点评审核", "/audit/reviews", "audit:review:read"),
                        leaf("audit.review_appeals", "商户点评申诉", "/audit/review-appeals", "audit:review_appeal:read"),
                        leaf("audit.posts", "帖子审核", "/audit/posts", "audit:post:read"),
                        leaf("audit.expert_certifications", "达人认证", "/audit/expert-certifications", "audit:expert_certification:read"),
                        leaf("audit.merchant_applications", "商户资质审核", "/audit/merchant-applications", "audit:merchant_application:read")
                )),
                group("data", "数据管理", "/data", List.of(
                        leaf("data.shops", "商户管理", "/data/shops", "data:shop:read"),
                        leaf("data.import", "种子导入", "/data/import", "data:shop:import"),
                        leaf("data.meta", "基础数据", "/data/meta", "data:geo:read"),
                        leaf("data.orders", "订单退款", "/data/orders", "data:order:read")
                )),
                group("operations", "运营配置", "/operations", List.of(
                        leaf("operations.ranks", "榜单规则", "/operations/ranks", "operations:rank:read"),
                        leaf("operations.growth", "成长规则", "/operations/growth", "operations:growth:read"),
                        leaf("operations.circles", "官方圈子", "/operations/circles", "operations:circle:read"),
                        leaf("operations.topics", "话题治理", "/operations/topics", "operations:topic:read"),
                        leaf("operations.banners", "Banner 配置", "/operations/banners", "operations:banner:read"),
                        leaf("operations.hotwords", "搜索热词", "/operations/hotwords", "operations:hotword:read"),
                        leaf("operations.activities", "运营活动", "/operations/activities", "operations:activity:read")
                )),
                group("system", "系统管理", "/system", List.of(
                        leaf("system.admins", "管理员账号", "/system/admins", "system:admin:read"),
                        leaf("system.roles", "角色权限", "/system/roles", "system:role:read"),
                        leaf("system.audit_logs", "审计日志", "/system/audit-logs", "system:audit_log:read"),
                        leaf("system.privacy_tasks", "隐私任务", "/system/privacy-tasks", "system:privacy_task:read")
                ))
        );
        List<AdminMenuResponse> result = new ArrayList<>();
        for (MenuNode root : roots) {
            AdminMenuResponse visible = visible(root, permissions);
            if (visible != null) result.add(visible);
        }
        return result;
    }

    private AdminMenuResponse visible(MenuNode node, Set<String> permissions) {
        if (node.children().isEmpty()) {
            return permissions.contains(node.permission())
                    ? new AdminMenuResponse(node.code(), node.name(), node.path(), List.of()) : null;
        }
        List<AdminMenuResponse> children = node.children().stream()
                .map(child -> visible(child, permissions)).filter(java.util.Objects::nonNull).toList();
        return children.isEmpty() ? null : new AdminMenuResponse(node.code(), node.name(), node.path(), children);
    }

    private MenuNode leaf(String code, String name, String path, String permission) { return new MenuNode(code, name, path, permission, List.of()); }
    private MenuNode group(String code, String name, String path, List<MenuNode> children) { return new MenuNode(code, name, path, "", children); }
    private record MenuNode(String code, String name, String path, String permission, List<MenuNode> children) {}
}
