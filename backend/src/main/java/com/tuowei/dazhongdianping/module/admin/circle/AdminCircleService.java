package com.tuowei.dazhongdianping.module.admin.circle;

import com.tuowei.dazhongdianping.common.api.ConflictException;
import com.tuowei.dazhongdianping.common.api.NotFoundException;
import com.tuowei.dazhongdianping.common.api.PageResult;
import com.tuowei.dazhongdianping.common.region.RegionContext;
import com.tuowei.dazhongdianping.module.admin.circle.model.CircleSaveRequest;
import com.tuowei.dazhongdianping.module.circle.mapper.CircleMapper;
import com.tuowei.dazhongdianping.module.circle.model.CircleRow;
import com.tuowei.dazhongdianping.module.circle.model.response.CircleResponse;
import java.util.List;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

@Service
public class AdminCircleService {
    private final CircleMapper mapper;
    public AdminCircleService(CircleMapper mapper) { this.mapper = mapper; }
    public PageResult<CircleResponse> list(Integer status, String keyword, Integer page, Integer pageSize) {
        int p=page==null?1:Math.max(1,page), size=pageSize==null?20:Math.min(50,Math.max(1,pageSize)), offset=(p-1)*size;
        String region=region(), key=keyword==null?"":keyword.trim();
        long total=mapper.countAdminCircles(region,status,key);
        List<CircleResponse> items=mapper.listAdminCircles(region,status,key,size,offset).stream().map(this::response).toList();
        return new PageResult<>(items,total,p,size,offset+items.size()<total);
    }
    @Transactional public CircleResponse create(CircleSaveRequest request) {
        String name=request.name().trim(); requireUnique(name,null);
        CircleRow row=new CircleRow(); row.setRegion(region()); row.setName(name); row.setDescription(text(request.description()));
        row.setCoverUrl(text(request.coverUrl())); row.setSort(request.sort()==null?0:request.sort()); mapper.insertCircle(row);
        return response(require(row.getId()));
    }
    @Transactional public CircleResponse update(Long id,CircleSaveRequest request) {
        CircleRow row=require(id); String name=request.name().trim(); requireUnique(name,id); row.setName(name);
        row.setDescription(text(request.description())); row.setCoverUrl(text(request.coverUrl())); row.setSort(request.sort()==null?0:request.sort());
        if(mapper.updateCircle(row)==0) throw new NotFoundException("圈子不存在"); return response(require(id));
    }
    @Transactional public CircleResponse status(Long id,Integer status) {
        require(id); if(mapper.updateCircleStatus(id,region(),status)==0) throw new NotFoundException("圈子不存在"); return response(require(id));
    }
    private CircleRow require(Long id){ CircleRow row=mapper.findAdminCircle(id,region()); if(row==null) throw new NotFoundException("圈子不存在"); return row; }
    private void requireUnique(String name,Long excludeId){ if(mapper.countNameConflict(region(),name,excludeId)>0) throw new ConflictException("当前区域已存在同名圈子"); }
    private CircleResponse response(CircleRow r){ return new CircleResponse(r.getId(),r.getRegion(),r.getName(),r.getDescription(),r.getCoverUrl(),r.getMemberCount(),r.getPostCount(),r.getSort(),r.getStatus(),false); }
    private String text(String value){ return value==null?"":value.trim(); }
    private String region(){ return RegionContext.getRegion().name(); }
}
