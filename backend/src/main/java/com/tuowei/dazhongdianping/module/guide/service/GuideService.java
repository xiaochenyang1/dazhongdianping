package com.tuowei.dazhongdianping.module.guide.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.guide.mapper.GuideMapper;
import com.tuowei.dazhongdianping.module.guide.model.GuideArticleRow;
import com.tuowei.dazhongdianping.module.guide.model.GuideSectionRow;
import com.tuowei.dazhongdianping.module.guide.model.request.GuideSaveRequest;
import com.tuowei.dazhongdianping.module.guide.model.request.GuideSectionRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 攻略：C 端只读已发布，运营端维护草稿与章节。 */
@Service
public class GuideService {

    private final GuideMapper mapper;

    public GuideService(GuideMapper mapper) {
        this.mapper = mapper;
    }

    public PageResult<Map<String, Object>> published(Integer page, Integer pageSize) {
        String region = region();
        int p = page(page);
        int s = pageSize(pageSize);
        long total = mapper.countPublished(region);
        List<Map<String, Object>> list = mapper.selectPublished(region, s, (p - 1) * s)
                .stream().map(row -> articleMap(row, false)).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    public Map<String, Object> publishedDetail(Long id) {
        GuideArticleRow row = mapper.selectById(id, region());
        if (row == null || row.getStatus() == null || row.getStatus() != 2) {
            throw new NotFoundException("攻略不存在");
        }
        return articleMap(row, true);
    }

    public PageResult<Map<String, Object>> adminList(Integer page, Integer pageSize) {
        String region = region();
        int p = page(page);
        int s = pageSize(pageSize);
        long total = mapper.countAdmin(region);
        List<Map<String, Object>> list = mapper.selectAdmin(region, s, (p - 1) * s)
                .stream().map(row -> articleMap(row, false)).toList();
        return new PageResult<>(list, total, p, s, (p - 1) * s + list.size() < total);
    }

    @Transactional
    public Map<String, Object> create(GuideSaveRequest request) {
        GuideArticleRow row = new GuideArticleRow();
        row.setRegion(region());
        fill(row, request);
        mapper.insertArticle(row);
        replaceSections(row.getId(), request.sections());
        return articleMap(require(row.getId()), true);
    }

    @Transactional
    public Map<String, Object> update(Long id, GuideSaveRequest request) {
        GuideArticleRow row = require(id);
        fill(row, request);
        if (mapper.updateArticle(row) == 0) {
            throw new NotFoundException("攻略不存在");
        }
        replaceSections(id, request.sections());
        return articleMap(require(id), true);
    }

    @Transactional
    public Map<String, Object> updateStatus(Long id, Integer status) {
        require(id);
        int next = guideStatus(status);
        if (mapper.updateStatus(id, region(), next) == 0) {
            throw new NotFoundException("攻略不存在");
        }
        return articleMap(require(id), true);
    }

    private void fill(GuideArticleRow row, GuideSaveRequest request) {
        row.setTitle(request.title().trim());
        row.setSummary(text(request.summary()));
        row.setCoverUrl(text(request.coverUrl()));
        row.setCityId(request.cityId() == null ? 0L : request.cityId());
        row.setStatus(guideStatus(request.status()));
    }

    private void replaceSections(Long articleId, List<GuideSectionRequest> sections) {
        mapper.deleteSections(articleId);
        if (sections == null) {
            return;
        }
        int index = 0;
        for (GuideSectionRequest section : sections) {
            GuideSectionRow row = new GuideSectionRow();
            row.setArticleId(articleId);
            row.setSortNo(section.sortNo() == null ? index : section.sortNo());
            row.setHeading(text(section.heading()));
            row.setBody(text(section.body()));
            row.setShopId(section.shopId() == null ? 0L : section.shopId());
            mapper.insertSection(row);
            index++;
        }
    }

    private GuideArticleRow require(Long id) {
        GuideArticleRow row = mapper.selectById(id, region());
        if (row == null) {
            throw new NotFoundException("攻略不存在");
        }
        return row;
    }

    private Map<String, Object> articleMap(GuideArticleRow row, boolean withSections) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("cityId", row.getCityId());
        map.put("title", row.getTitle());
        map.put("summary", row.getSummary() == null ? "" : row.getSummary());
        map.put("coverUrl", row.getCoverUrl() == null ? "" : row.getCoverUrl());
        map.put("status", row.getStatus());
        map.put("createdAt", row.getCreatedAt());
        if (withSections) {
            map.put("sections", mapper.selectSections(row.getId()).stream().map(this::sectionMap).toList());
        }
        return map;
    }

    private Map<String, Object> sectionMap(GuideSectionRow section) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", section.getId());
        map.put("heading", section.getHeading() == null ? "" : section.getHeading());
        map.put("body", section.getBody() == null ? "" : section.getBody());
        map.put("shopId", section.getShopId());
        map.put("sortNo", section.getSortNo());
        return map;
    }

    private int guideStatus(Integer status) {
        if (status == null) {
            return 1;
        }
        if (status != 1 && status != 2) {
            throw new IllegalArgumentException("status 只能是 1 或 2");
        }
        return status;
    }

    private static String text(String value) {
        return value == null ? "" : value.trim();
    }

    private int page(Integer page) {
        return page == null ? 1 : Math.max(1, page);
    }

    private int pageSize(Integer pageSize) {
        return pageSize == null ? 10 : Math.min(50, Math.max(1, pageSize));
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
