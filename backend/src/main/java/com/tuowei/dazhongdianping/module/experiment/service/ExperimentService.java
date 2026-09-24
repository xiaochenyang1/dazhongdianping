package com.tuowei.dazhongdianping.module.experiment.service;

import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.UnauthorizedException;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.common.user.UserSession;
import com.tuowei.dazhongdianping.common.user.UserSessionContext;
import com.tuowei.dazhongdianping.module.experiment.mapper.ExperimentMapper;
import com.tuowei.dazhongdianping.module.experiment.model.ExperimentAssignmentRow;
import com.tuowei.dazhongdianping.module.experiment.model.ExperimentRow;
import com.tuowei.dazhongdianping.module.experiment.model.FeatureFlagRow;
import com.tuowei.dazhongdianping.module.experiment.model.request.ExperimentSaveRequest;
import com.tuowei.dazhongdianping.module.experiment.model.request.FlagSaveRequest;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import org.springframework.dao.DuplicateKeyException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

/** 功能开关与实验分组。C 端开关对匿名访客只按 flagKey 哈希分桶。 */
@Service
public class ExperimentService {

    private final ExperimentMapper mapper;

    public ExperimentService(ExperimentMapper mapper) {
        this.mapper = mapper;
    }

    /**
     * 匿名接口没有稳定 userId，分桶只使用 flagKey，因此同一开关对所有人结果一致。
     * enabled 为假或 rolloutPercent &lt;= 0 时关闭；rolloutPercent &gt;= 100 且 enabled 时开启；
     * 否则当 {@code Math.floorMod(Math.abs(flagKey.hashCode()), 100) < rolloutPercent} 时开启。
     */
    public static boolean resolvedEnabled(boolean enabled, int rolloutPercent, String flagKey) {
        if (!enabled || rolloutPercent <= 0) {
            return false;
        }
        if (rolloutPercent >= 100) {
            return true;
        }
        String key = flagKey == null ? "" : flagKey;
        return Math.floorMod(Math.abs(key.hashCode()), 100) < rolloutPercent;
    }

    public List<Map<String, Object>> flags() {
        return mapper.selectFlags(region()).stream().map(row -> {
            Map<String, Object> map = new LinkedHashMap<>();
            map.put("flagKey", row.getFlagKey());
            map.put("enabled", resolvedEnabled(
                    Boolean.TRUE.equals(row.getEnabled()),
                    row.getRolloutPercent() == null ? 0 : row.getRolloutPercent(),
                    row.getFlagKey()));
            return map;
        }).toList();
    }

    public List<Map<String, Object>> adminFlags() {
        return mapper.selectFlags(region()).stream().map(this::flagMap).toList();
    }

    @Transactional
    public Map<String, Object> createFlag(FlagSaveRequest request) {
        String region = region();
        String flagKey = request.flagKey().trim();
        if (mapper.selectFlagByKey(region, flagKey) != null) {
            throw new IllegalArgumentException("开关已存在");
        }
        FeatureFlagRow row = new FeatureFlagRow();
        row.setRegion(region);
        fillFlag(row, request, flagKey);
        try {
            mapper.insertFlag(row);
        } catch (DuplicateKeyException exception) {
            throw new IllegalArgumentException("开关已存在");
        }
        return flagMap(requireFlag(row.getId()));
    }

    @Transactional
    public Map<String, Object> updateFlag(Long id, FlagSaveRequest request) {
        FeatureFlagRow row = requireFlag(id);
        String flagKey = request.flagKey().trim();
        FeatureFlagRow occupied = mapper.selectFlagByKey(row.getRegion(), flagKey);
        if (occupied != null && !occupied.getId().equals(id)) {
            throw new IllegalArgumentException("开关已存在");
        }
        fillFlag(row, request, flagKey);
        if (mapper.updateFlag(row) == 0) {
            throw new NotFoundException("开关不存在");
        }
        return flagMap(requireFlag(id));
    }

    public List<Map<String, Object>> adminExperiments() {
        return mapper.selectExperiments(region()).stream().map(this::experimentMap).toList();
    }

    @Transactional
    public Map<String, Object> createExperiment(ExperimentSaveRequest request) {
        ExperimentRow row = new ExperimentRow();
        row.setRegion(region());
        row.setName(request.name().trim());
        row.setFlagKey(request.flagKey() == null ? "" : request.flagKey().trim());
        row.setStatus(experimentStatus(request.status()));
        mapper.insertExperiment(row);
        return experimentMap(requireExperiment(row.getId()));
    }

    @Transactional
    public Map<String, Object> assign(Long experimentId, String variant) {
        UserSession user = requireUser();
        String chosen = variant == null ? "" : variant.trim();
        if (!"A".equals(chosen) && !"B".equals(chosen)) {
            throw new IllegalArgumentException("variant 只能是 A 或 B");
        }
        ExperimentRow experiment = mapper.selectExperiment(experimentId, region());
        if (experiment == null || experiment.getStatus() == null || experiment.getStatus() != 1) {
            throw new NotFoundException("实验不存在或未开启");
        }
        ExperimentAssignmentRow existing = mapper.selectAssignment(experimentId, user.userId());
        if (existing != null) {
            return assignmentMap(experimentId, existing.getVariant());
        }
        ExperimentAssignmentRow row = new ExperimentAssignmentRow();
        row.setExperimentId(experimentId);
        row.setUserId(user.userId());
        row.setVariant(chosen);
        try {
            mapper.insertAssignment(row);
        } catch (DuplicateKeyException exception) {
            ExperimentAssignmentRow again = mapper.selectAssignment(experimentId, user.userId());
            if (again == null) {
                throw exception;
            }
            return assignmentMap(experimentId, again.getVariant());
        }
        return assignmentMap(experimentId, chosen);
    }

    private void fillFlag(FeatureFlagRow row, FlagSaveRequest request, String flagKey) {
        row.setFlagKey(flagKey);
        row.setDescription(request.description() == null ? "" : request.description().trim());
        row.setEnabled(request.enabled());
        row.setRolloutPercent(request.rolloutPercent());
    }

    private FeatureFlagRow requireFlag(Long id) {
        FeatureFlagRow row = mapper.selectFlag(id, region());
        if (row == null) {
            throw new NotFoundException("开关不存在");
        }
        return row;
    }

    private ExperimentRow requireExperiment(Long id) {
        ExperimentRow row = mapper.selectExperiment(id, region());
        if (row == null) {
            throw new NotFoundException("实验不存在");
        }
        return row;
    }

    private Map<String, Object> flagMap(FeatureFlagRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("flagKey", row.getFlagKey());
        map.put("description", row.getDescription() == null ? "" : row.getDescription());
        map.put("enabled", Boolean.TRUE.equals(row.getEnabled()));
        map.put("rolloutPercent", row.getRolloutPercent() == null ? 0 : row.getRolloutPercent());
        return map;
    }

    private Map<String, Object> experimentMap(ExperimentRow row) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("id", row.getId());
        map.put("name", row.getName());
        map.put("flagKey", row.getFlagKey() == null ? "" : row.getFlagKey());
        map.put("status", row.getStatus());
        map.put("createdAt", row.getCreatedAt());
        return map;
    }

    private Map<String, Object> assignmentMap(Long experimentId, String variant) {
        Map<String, Object> map = new LinkedHashMap<>();
        map.put("experimentId", experimentId);
        map.put("variant", variant);
        return map;
    }

    private int experimentStatus(Integer status) {
        if (status == null) {
            return 1;
        }
        if (status != 0 && status != 1) {
            throw new IllegalArgumentException("status 只能是 0 或 1");
        }
        return status;
    }

    private UserSession requireUser() {
        UserSession user = UserSessionContext.get();
        if (user == null) {
            throw new UnauthorizedException("用户登录状态不存在");
        }
        return user;
    }

    private String region() {
        return RegionContext.getRegion().name();
    }
}
