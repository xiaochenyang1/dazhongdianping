package com.tuowei.dazhongdianping.module.waitlist.service;

import com.tuowei.dazhongdianping.module.waitlist.model.WaitlistEntryRow;
import java.util.LinkedHashMap;
import java.util.Map;
import org.springframework.stereotype.Component;

/** 排队候位行到响应体的统一映射。 */
@Component
public class WaitlistPresenter {

    public Map<String, Object> entry(WaitlistEntryRow w) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", w.getId());
        m.put("shopId", w.getShopId());
        m.put("shopName", w.getShopName() == null ? "" : w.getShopName());
        m.put("userId", w.getUserId());
        m.put("userNickname", w.getUserNickname() == null ? "" : w.getUserNickname());
        m.put("tableType", w.getTableType());
        m.put("tableTypeText", tableTypeText(w.getTableType()));
        m.put("partySize", w.getPartySize());
        m.put("queueNo", w.getQueueNo());
        m.put("status", w.getStatus());
        m.put("statusText", statusText(w.getStatus()));
        m.put("aheadCount", w.getAheadCount() == null ? 0 : w.getAheadCount());
        m.put("calledAt", w.getCalledAt());
        m.put("seatedAt", w.getSeatedAt());
        m.put("createdAt", w.getCreatedAt());
        return m;
    }

    private String tableTypeText(Integer t) {
        if (t == null) return "小桌";
        return switch (t) {
            case 2 -> "中桌";
            case 3 -> "大桌";
            default -> "小桌";
        };
    }

    private String statusText(Integer status) {
        if (status == null) return "排队中";
        return switch (status) {
            case 2 -> "已叫号";
            case 3 -> "已入座";
            case 4 -> "已过号";
            case 5 -> "已取消";
            default -> "排队中";
        };
    }
}
