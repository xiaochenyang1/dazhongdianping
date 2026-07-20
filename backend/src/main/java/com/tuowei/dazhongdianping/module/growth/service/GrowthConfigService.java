package com.tuowei.dazhongdianping.module.growth.service;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.module.auth.model.GrowthRuleRow;
import com.tuowei.dazhongdianping.module.growth.mapper.GrowthConfigMapper;
import com.tuowei.dazhongdianping.module.growth.model.request.GrowthRuleSaveRequest;
import com.tuowei.dazhongdianping.module.growth.model.request.LevelConfigSaveRequest;
import com.tuowei.dazhongdianping.module.growth.model.LevelConfigRow;
import com.tuowei.dazhongdianping.module.growth.model.response.GrowthConfigResponse;
import java.util.Locale;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
@Service public class GrowthConfigService {
 private final GrowthConfigMapper mapper; public GrowthConfigService(GrowthConfigMapper mapper){this.mapper=mapper;}
 public GrowthConfigResponse list(){return new GrowthConfigResponse(mapper.selectRules(),mapper.selectLevels());}
 @Transactional public GrowthRuleRow create(GrowthRuleSaveRequest request){String action=normalize(request.action()); if(mapper.selectRuleByAction(action)!=null) throw new IllegalArgumentException("行为码已存在"); GrowthRuleRow row=toRow(null,request,action); mapper.insertRule(row); return mapper.selectRule(row.getId());}
 @Transactional public GrowthRuleRow update(Long id,GrowthRuleSaveRequest request){GrowthRuleRow current=mapper.selectRule(id); if(current==null) throw new NotFoundException("成长规则不存在"); String action=normalize(request.action()); GrowthRuleRow same=mapper.selectRuleByAction(action); if(same!=null&&!same.getId().equals(id)) throw new IllegalArgumentException("行为码已存在"); GrowthRuleRow row=toRow(id,request,action); if(mapper.updateRule(row)==0) throw new NotFoundException("成长规则不存在"); return mapper.selectRule(id);}
 @Transactional public LevelConfigRow updateLevel(Integer level,LevelConfigSaveRequest request){LevelConfigRow current=mapper.selectLevel(level);if(current==null)throw new NotFoundException("等级配置不存在");current.setMinGrowth(request.minGrowth());current.setLevelName(request.levelName().trim());current.setIcon(request.icon()==null?"":request.icon().trim());current.setPrivilegeJson(request.privilegeJson().trim());current.setEnabled(request.enabled());if(mapper.updateLevel(current)==0)throw new NotFoundException("等级配置不存在");return mapper.selectLevel(level);}
 private GrowthRuleRow toRow(Long id,GrowthRuleSaveRequest r,String action){GrowthRuleRow row=new GrowthRuleRow();row.setId(id);row.setAction(action);row.setActionName(r.actionName().trim());row.setGrowthValue(r.growthValue());row.setPoints(r.points());row.setDailyLimit(r.dailyLimit());row.setEnabled(r.enabled());return row;}
 private String normalize(String value){String action=value.trim().toLowerCase(Locale.ROOT);if(!action.matches("[a-z][a-z0-9_]{1,31}"))throw new IllegalArgumentException("action 格式非法");return action;}
}
