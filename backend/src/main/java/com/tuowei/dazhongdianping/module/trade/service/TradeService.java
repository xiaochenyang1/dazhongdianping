package com.tuowei.dazhongdianping.module.trade.service;
import com.tuowei.dazhongdianping.common.api.*;import com.tuowei.dazhongdianping.common.region.RegionContext;import com.tuowei.dazhongdianping.common.user.*;import com.tuowei.dazhongdianping.module.auth.service.UserGrowthService;import com.tuowei.dazhongdianping.module.notification.service.NotificationService;import com.tuowei.dazhongdianping.module.trade.mapper.TradeMapper;import com.tuowei.dazhongdianping.module.trade.model.*;import com.tuowei.dazhongdianping.module.trade.model.request.*;import com.tuowei.dazhongdianping.module.trade.payment.*;import java.math.*;import java.nio.charset.StandardCharsets;import java.security.MessageDigest;import java.time.*;import java.util.*;import org.springframework.beans.factory.annotation.Value;import org.springframework.stereotype.Service;import org.springframework.transaction.annotation.Propagation;import org.springframework.transaction.annotation.Transactional;
@Service public class TradeService {
 private static final String ORDER_PAID_TYPE = "order.paid";
 private final OrderInventoryService inventory;private final TradeMapper mapper;private final com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper authCommandMapper;private final UserGrowthService userGrowthService;private final CouponLifecycleService couponLifecycleService;private final NotificationService notificationService;private final String secret;private final PaymentChannelResolver channelResolver;private final com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService marketingCouponService;private final com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper campaignMapper;public TradeService(TradeMapper mapper,com.tuowei.dazhongdianping.module.auth.mapper.AuthCommandMapper authCommandMapper,UserGrowthService userGrowthService,CouponLifecycleService couponLifecycleService,NotificationService notificationService,@Value("${app.payment.notify-secret}")String secret,PaymentChannelResolver channelResolver,com.tuowei.dazhongdianping.module.marketing.service.MarketingCouponService marketingCouponService,OrderInventoryService inventory,com.tuowei.dazhongdianping.module.marketing.mapper.MarketingCampaignMapper campaignMapper){this.inventory=inventory;this.mapper=mapper;this.authCommandMapper=authCommandMapper;this.userGrowthService=userGrowthService;this.couponLifecycleService=couponLifecycleService;this.notificationService=notificationService;this.secret=secret;this.channelResolver=channelResolver;this.marketingCouponService=marketingCouponService;this.campaignMapper=campaignMapper;}
 public List<Map<String,Object>> shopDeals(Long shopId){return mapper.selectShopDeals(shopId,region()).stream().map(this::dealSummary).toList();}
 public Map<String,Object> deal(Long id){DealRow d=requireDeal(id);Map<String,Object> m=new LinkedHashMap<>(dealSummary(d));m.put("items",mapper.selectDealItems(id));m.put("rules",d.getRules());m.put("validStart",d.getValidStart());m.put("validEnd",d.getValidEnd());return m;}
 @Transactional
 public Map<String,Object> createOrder(OrderCreateRequest req) {
  UserSession u=user();
  var account=authCommandMapper.selectUserByIdForUpdate(u.userId());
  if(account==null||!Integer.valueOf(1).equals(account.getStatus()))throw new UnauthorizedException("用户登录状态不存在");
  DealRow d=mapper.selectDealForUpdate(req.dealId(),region());
  if(d==null)throw new NotFoundException("团购不存在");
  if(d.getValidEnd()!=null&&d.getValidEnd().isBefore(LocalDate.now()))throw new IllegalArgumentException("团购已过期");
  if(mapper.decrementDealStock(d.getId(),req.quantity())==0)throw new IllegalArgumentException("团购库存不足");
  OrderRow o=new OrderRow();
  o.setOrderNo("OD"+UUID.randomUUID().toString().replace("-", "").substring(0,30));
  o.setUserId(u.userId());o.setDealId(d.getId());o.setShopId(d.getShopId());o.setRegion(d.getRegion());
  o.setQuantity(req.quantity());o.setUnitPrice(d.getPrice());
  o.setDealTitleSnapshot(d.getTitle());o.setCouponValidEnd(d.getValidEnd());
  BigDecimal original=d.getPrice().multiply(BigDecimal.valueOf(req.quantity())).setScale(2);
  var discount=marketingCouponService.applyForOrder(u.userId(),req.userCouponId(),d.getShopId(),original);
  o.setOriginalAmount(original);o.setDiscountAmount(discount.discountAmount());o.setUserCouponId(discount.userCouponId());
  o.setAmount(original.subtract(discount.discountAmount()).setScale(2));o.setCurrency(d.getCurrency());
  o.setExpireAt(LocalDateTime.now().plusMinutes(30));mapper.insertOrder(o);
  if(discount.userCouponId()!=null)marketingCouponService.bindCouponToOrder(discount.userCouponId(),o.getId());
  return orderMap(requireOrder(o.getId()),false);
 }
 public PageResult<Map<String,Object>> orders(Integer payStatus,Integer page,Integer pageSize){int p=page==null?1:Math.max(1,page),s=pageSize==null?12:Math.min(50,Math.max(1,pageSize));UserSession u=user();long total=mapper.countUserOrders(u.userId(),region(),payStatus);List<Map<String,Object>> list=mapper.selectUserOrders(u.userId(),region(),payStatus,s,(p-1)*s).stream().map(o->orderMap(o,false)).toList();return new PageResult<>(list,total,p,s,(p-1)*s+list.size()<total);}
 public Map<String,Object> order(Long id){return orderMap(requireOrder(id),true);}
 /** 下单前预览：给定团购与数量，返回可用营销券列表。 */
 public List<?> usableCoupons(Long dealId,Integer quantity){user();DealRow d=requireDeal(dealId);int q=quantity==null?1:Math.min(20,Math.max(1,quantity));BigDecimal amount=d.getPrice().multiply(BigDecimal.valueOf(q)).setScale(2);return marketingCouponService.usableForOrder(d.getShopId(),amount);}
 @Transactional
 public Map<String,Object> pay(Long id) {
  OrderRow visible=requireOrder(id);
  PaymentChannel ch=channelResolver.resolve(visible.getRegion());
  OrderRow o=inventory.lockOrder(id);
  if(o.getStatus()!=1||o.getPayStatus()!=0)throw new IllegalArgumentException("订单当前不可支付");
  if(expired(o))throw new IllegalArgumentException("订单已超时，请重新下单");
  PaymentRow p=mapper.selectPaymentForUpdate(id);
  if(p==null){
   p=new PaymentRow();p.setOrderId(id);p.setOrderNo(o.getOrderNo());
   PaymentIntentResult intent=ch.createIntent(o,p);
   p.setChannel(intent.channel());p.setChannelTxn(intent.channelTxn());
   p.setClientSecret(intent.clientSecret()==null?"":intent.clientSecret());
   p.setAmount(o.getAmount());p.setCurrency(o.getCurrency());mapper.insertPayment(p);
  }
  return Map.of("paymentId",p.getId(),"channel",p.getChannel(),"channelTxn",p.getChannelTxn(),
      "clientSecret",p.getClientSecret()==null?"":p.getClientSecret(),"orderNo",o.getOrderNo(),
      "amount",o.getAmount(),"currency",o.getCurrency());
 }

 @Transactional
 public Map<String,Object> notifyInternal(String channel,PaymentNotifyResult r) {
  if(r==null||!r.success())return Map.of("processed",false);
  PaymentRow visible=mapper.selectPaymentByTxn(channel,r.channelTxn());
  if(visible==null||!visible.getOrderNo().equals(r.orderNo()))throw new NotFoundException("支付流水不存在");
  OrderRow o=inventory.lockOrder(visible.getOrderId());
  PaymentRow p=mapper.selectPaymentByTxnForUpdate(channel,r.channelTxn());
  if(r.amount()==null||o.getAmount().compareTo(r.amount())!=0||p.getAmount().compareTo(r.amount())!=0)
   throw new IllegalArgumentException("支付金额不一致");
  if(p.getStatus()==1)return Map.of("processed",false,"orderNo",o.getOrderNo());
  var recipient=authCommandMapper.selectUserByIdForUpdate(o.getUserId());
  boolean activeRecipient=recipient!=null&&Integer.valueOf(1).equals(recipient.getStatus());
  if(o.getStatus()==1&&(expired(o)||!activeRecipient&&(OrderInventoryService.isSeckill(o)||OrderInventoryService.isGroupBuy(o)))) {
   if(!inventory.closeUnpaid(o))throw new IllegalStateException("超时订单关闭失败");
  }
  p.setRawResponse(activeRecipient?r.toString():"");
  if(mapper.markPaymentSuccess(p)!=1)throw new IllegalStateException("支付状态更新失败");
  if(o.getStatus()==2&&o.getPayStatus()==0){
   if(mapper.markClosedOrderPaid(o.getId(),channel)!=1)throw new IllegalStateException("迟到支付入账失败");
   mapper.insertAutomaticRefund(o.getId(),o.getAmount(),channel,"late_payment","订单关闭后收到支付，自动退款");
   processAutomaticRefundLocked(o,mapper.selectRefundForUpdate(o.getId()));
  }else if(mapper.markOrderPaid(o.getId(),channel)==1){
   o.setPayStatus(1);
   completePaidOrder(o);
  }else throw new IllegalStateException("订单支付状态不一致");
  return Map.of("processed",true,"orderNo",o.getOrderNo());
 }

 private void completePaidOrder(OrderRow order) {
  inventory.markPaid(order);
  if(!OrderInventoryService.isGroupBuy(order)){
   fulfillPaidOrder(order);
   return;
  }
  var member=campaignMapper.selectMemberByOrderForUpdate(order.getId());
  if(member==null||campaignMapper.markGroupBuyMemberPaid(order.getId())!=1)
   throw new IllegalStateException("拼团成员支付状态不一致");
  if(campaignMapper.recordGroupBuyPayment(member.getTeamId())!=1)
   throw new IllegalStateException("拼团支付人数更新失败");
  var team=campaignMapper.selectTeamForUpdate(member.getTeamId());
  if(team==null)throw new IllegalStateException("拼团不存在");
  if(!Integer.valueOf(2).equals(team.getStatus()))return;
  for(Long orderId:campaignMapper.selectPaidGroupBuyOrderIds(team.getId())){
   OrderRow paid=orderId.equals(order.getId())?order:inventory.lockOrder(orderId);
   fulfillPaidOrder(paid);
  }
 }

 private void fulfillPaidOrder(OrderRow order) {
  if(!Integer.valueOf(1).equals(order.getPayStatus()))return;
  if(!mapper.selectOrderCouponsForUpdate(order.getId()).isEmpty())return;
  LocalDate validEnd=order.getCouponValidEnd();
  if(order.getDealTitleSnapshot()==null||order.getDealTitleSnapshot().isBlank()){
   DealRow deal=mapper.selectDeal(order.getDealId(),order.getRegion());
   if(deal==null)throw new IllegalStateException("订单套餐不存在");
   validEnd=deal.getValidEnd();
  }
  for(int i=0;i<order.getQuantity();i++){
   CouponRow coupon=new CouponRow();coupon.setOrderId(order.getId());coupon.setUserId(order.getUserId());
   coupon.setDealId(order.getDealId());coupon.setShopId(order.getShopId());
   coupon.setCode("CP"+UUID.randomUUID().toString().replace("-", "").substring(0,20).toUpperCase());
   coupon.setExpireAt(validEnd);mapper.insertCoupon(coupon);
  }
  var recipient=authCommandMapper.selectUserByIdForUpdate(order.getUserId());
  if(recipient!=null&&Integer.valueOf(1).equals(recipient.getStatus())){
   userGrowthService.rewardForCompletedOrder(order.getUserId(),order.getId());
   notifyOrderPaid(order);
  }
 }

 private boolean expired(OrderRow order) {
  return order.getExpireAt()!=null&&!order.getExpireAt().isAfter(LocalDateTime.now());
 }

 @Transactional
 public boolean closeExpiredOrder(Long id) {
  OrderRow order=inventory.lockOrder(id);
  return order.getStatus()==1&&order.getPayStatus()==0&&expired(order)&&inventory.closeUnpaid(order);
 }

 @Transactional
 public boolean processAutomaticRefund(Long orderId) {
  OrderRow order=inventory.lockOrder(orderId);
  RefundRow refund=mapper.selectRefundForUpdate(orderId);
  if(refund==null||!("late_payment".equals(refund.getRefundType())||"groupbuy_expired".equals(refund.getRefundType()))||refund.getStatus()!=3
      ||refund.getChannelRefundTxn()!=null&&!refund.getChannelRefundTxn().isBlank())return false;
  return processAutomaticRefundLocked(order,refund);
 }

 private boolean processAutomaticRefundLocked(OrderRow order,RefundRow refund) {
  PaymentRow payment=mapper.selectPaymentForUpdate(order.getId());
  RefundResult result;
  try {
   if(payment==null)throw new ServiceUnavailableException("订单缺少可退款的支付记录");
   String idempotencyKey="late_payment".equals(refund.getRefundType())
       ?"late-order-refund-"+order.getOrderNo():"groupbuy-expired-refund-"+order.getOrderNo();
   result=channelResolver.resolveByChannel(payment.getChannel()).refund(payment,refund.getAmount(),
       refund.getReason(),idempotencyKey);
   if(result==null||result.state()==null||!payment.getChannel().equals(result.channel())
       ||result.refundTxn()==null||result.refundTxn().isBlank()
       ||result.amount()==null||refund.getAmount().compareTo(result.amount())!=0)
    throw new ServiceUnavailableException("支付渠道退款结果不完整");
  }catch(RuntimeException unavailable){
   // A durable pending row survives transport errors; retries use the same key
   // even if an earlier channel response or database commit was lost.
   mapper.recordAutomaticRefundRetry(refund.getId());
   return false;
  }
  if(mapper.recordRefundChannelResult(refund.getId(),result.channel(),result.refundTxn(),
      result.state().name().toLowerCase(Locale.ROOT),safeFailureReason(result.failureReason()))!=1)
   throw new IllegalStateException("自动退款回执保存失败");
  applyRefundChannelState(refund,result.state(),result.failureReason());
  return true;
 }
 @Transactional public Map<String,Object> handleChannelWebhook(String channel,ChannelWebhookResult result){
  if(result==null||result.eventType()==ChannelWebhookResult.EventType.IGNORED)return Map.of("processed",false);
  if(result.eventType()==ChannelWebhookResult.EventType.PAYMENT_SUCCEEDED){
   return notifyInternal(channel,new PaymentNotifyResult(result.orderNo(),result.channelTxn(),result.amount(),true));
  }
  if(result.refundState()==null||result.refundTxn()==null||result.refundTxn().isBlank())return Map.of("processed",false);
  RefundRow refund=mapper.selectRefundByChannelTxn(channel,result.refundTxn());
  if(refund==null)throw new ServiceUnavailableException("退款回执尚未落库，请稍后重试");
  if(result.amount()==null||refund.getAmount()==null||refund.getAmount().compareTo(result.amount())!=0)throw new IllegalArgumentException("退款金额不一致");
  return applyRefundChannelState(refund, result.refundState(), result.failureReason());
 }

 @Transactional(propagation=Propagation.REQUIRES_NEW) public Map<String,Object> applyRefundChannelState(RefundRow refund,RefundChannelState state,String failureReason){
  if(refund==null||state==null)return Map.of("processed",false);
  OrderRow lockedOrder=inventory.lockOrder(refund.getOrderId());
  RefundRow currentRefund=mapper.selectRefundForUpdate(refund.getOrderId());
  if(currentRefund==null||!currentRefund.getId().equals(refund.getId()))throw new NotFoundException("退款不存在");
  refund=currentRefund;
  int current=refund.getStatus()==null?0:refund.getStatus();
  if(state==RefundChannelState.PENDING){
   if(current==1||current==2||current==4)return Map.of("processed",false,"refundId",refund.getId(),"status",current);
   int changed=mapper.updateRefundChannelState(refund.getId(),3,"pending",safeFailureReason(failureReason));
   return Map.of("processed",changed==1,"refundId",refund.getId(),"status",3);
  }
  if(state==RefundChannelState.FAILED){
   if(current==1||current==2||current==4)return Map.of("processed",false,"refundId",refund.getId(),"status",current);
   int changed=mapper.updateRefundChannelState(refund.getId(),4,"failed",safeFailureReason(failureReason));
   if(changed==1){
    OrderRow order=lockedOrder;
    if(order!=null)notifyRefundChannelResult(order,"failed",safeFailureReason(failureReason));
   }
   return Map.of("processed",changed==1,"refundId",refund.getId(),"status",4);
  }
  if(current==1)return Map.of("processed",false,"refundId",refund.getId(),"status",1);
  if(current==2||current==4)return Map.of("processed",false,"refundId",refund.getId(),"status",current);
  int changed=mapper.updateRefundChannelState(refund.getId(),1,"succeeded","");
  if(changed==1){
   OrderRow order=lockedOrder;
   if(order==null)throw new NotFoundException("退款对应订单不存在");
   if(mapper.markOrderRefunded(order.getId())!=1)throw new IllegalStateException("订单退款状态更新失败");
   mapper.markCouponsRefunded(order.getId());
   inventory.release(order);
   notifyRefundChannelResult(order,"succeeded","");
  }
  return Map.of("processed",changed==1,"refundId",refund.getId(),"status",1);
 }

 private String safeFailureReason(String reason){return reason==null?"":reason.length()>255?reason.substring(0,255):reason;}

 private void notifyRefundChannelResult(OrderRow order,String state,String reason){
  if(order==null||order.getUserId()==null)return;
  String title=switch(state){case "succeeded"->"退款已到账";case "failed"->"退款失败";default->"退款处理中";};
  String content=(order.getDealTitle()==null||order.getDealTitle().isBlank()?"团购订单":order.getDealTitle())
          +" · 订单 "+order.getOrderNo()+" · "+title+(reason==null||reason.isBlank()?"":"："+reason);
  String link="/user/orders/"+order.getId()+"?refund="+state;
  String refundRegion=order.getRegion()==null||order.getRegion().isBlank()?RegionContext.getRegion().name():order.getRegion();
  notificationService.create(order.getUserId(),refundRegion,"order.refund.result",title,content,link);
 }
 @Transactional public Map<String,Object> completeMockPayment(Long id){OrderRow o=requireOrder(id);channelResolver.resolve(o.getRegion());Map<String,Object> intent=pay(id);String channel=(String)intent.get("channel");if(!channel.endsWith("_mock"))throw new IllegalArgumentException("当前渠道不是模拟支付");String txn=(String)intent.get("channelTxn");notifyInternal(channel,new PaymentNotifyResult(o.getOrderNo(),txn,o.getAmount(),true));return orderMap(requireOrder(id),true);}
 @Transactional
 public Map<String,Object> cancel(Long id) {
  requireOrder(id);OrderRow o=inventory.lockOrder(id);
  if(!inventory.closeUnpaid(o))throw new IllegalArgumentException("订单当前不可取消");
  return orderMap(requireOrder(id),false);
 }
 @Transactional
 public Map<String,Object> refund(Long id,RefundRequest req) {
  requireOrder(id);OrderRow o=inventory.lockOrder(id);
  if(o.getPayStatus()!=1||o.getStatus()!=1)throw new IllegalArgumentException("订单当前不可退款");
  if(mapper.selectOrderCouponsForUpdate(id).stream().anyMatch(c->Integer.valueOf(2).equals(c.getStatus())))
   throw new IllegalArgumentException("存在已核销券，不能整单退款");
  if(mapper.selectRefundForUpdate(id)!=null)throw new IllegalArgumentException("订单已有退款申请");
  mapper.insertRefund(id,o.getAmount(),req.reason().trim());return orderMap(requireOrder(id),true);
 }
 public PageResult<Map<String,Object>> coupons(Integer status,Integer page,Integer pageSize){int p=page==null?1:Math.max(1,page),s=pageSize==null?12:Math.min(50,Math.max(1,pageSize));UserSession u=user();// Sync any past-due coupons so the list does not keep showing stale "待使用".
 couponLifecycleService.expireDueCouponsForUser(u.userId());long total=mapper.countCoupons(u.userId(),region(),status);List<Map<String,Object>> list=mapper.selectCoupons(u.userId(),region(),status,s,(p-1)*s).stream().map(this::couponMap).toList();return new PageResult<>(list,total,p,s,(p-1)*s+list.size()<total);}
 public Map<String,Object> couponDetail(String code){UserSession u=user();couponLifecycleService.expireDueCouponsForUser(u.userId());String normalized=code==null?"":code.trim();if(normalized.isBlank())throw new IllegalArgumentException("券码不能为空");CouponRow coupon=mapper.selectUserCouponByCode(normalized,u.userId(),region());if(coupon==null)throw new NotFoundException("券码不存在");return couponDetailMap(coupon);}
 private DealRow requireDeal(Long id){DealRow d=mapper.selectDeal(id,region());if(d==null)throw new NotFoundException("团购不存在");return d;}private OrderRow requireOrder(Long id){UserSession u=user();OrderRow o=mapper.selectUserOrder(id,u.userId(),region());if(o==null)throw new NotFoundException("订单不存在");return o;}private UserSession user(){UserSession u=UserSessionContext.get();if(u==null)throw new UnauthorizedException("用户登录状态不存在");return u;}private String region(){return RegionContext.getRegion().name();}
 private Map<String,Object> dealSummary(DealRow d){Map<String,Object>m=new LinkedHashMap<>();m.put("id",d.getId());m.put("shopId",d.getShopId());m.put("shopName",d.getShopName());m.put("title",d.getTitle());m.put("coverImage",d.getCoverImage());m.put("price",d.getPrice());m.put("originalPrice",d.getOriginalPrice());m.put("currency",d.getCurrency());m.put("stock",d.getStock());m.put("soldCount",d.getSoldCount());return m;}
 private Map<String,Object> orderMap(OrderRow o,boolean includeCoupons){Map<String,Object>m=new LinkedHashMap<>();m.put("id",o.getId());m.put("orderNo",o.getOrderNo());m.put("orderSource",o.getOrderSource());m.put("campaignId",o.getCampaignId());m.put("campaignTitle",o.getCampaignTitle());m.put("expireAt",o.getExpireAt());m.put("canPay",Integer.valueOf(1).equals(o.getStatus())&&Integer.valueOf(0).equals(o.getPayStatus())&&!expired(o));m.put("dealId",o.getDealId());m.put("dealTitle",o.getDealTitle());m.put("shopId",o.getShopId());m.put("shopName",o.getShopName());m.put("coverImage",o.getCoverImage());m.put("quantity",o.getQuantity());m.put("unitPrice",o.getUnitPrice());m.put("originalAmount",o.getOriginalAmount()==null?o.getAmount():o.getOriginalAmount());m.put("discountAmount",o.getDiscountAmount()==null?BigDecimal.ZERO:o.getDiscountAmount());m.put("amount",o.getAmount());m.put("currency",o.getCurrency());m.put("payStatus",o.getPayStatus());m.put("payStatusText",switch(o.getPayStatus()){case 1->"已支付";case 2->"已退款";case 3->"部分退款";default->"待支付";});m.put("status",o.getStatus());if(OrderInventoryService.isGroupBuy(o)){var team=campaignMapper.selectTeamByOrder(o.getId());if(team!=null){m.put("groupBuyTeamId",team.getId());m.put("groupBuyStatus",team.getStatus());m.put("groupBuyMemberCount",team.getMemberCount());m.put("groupBuyPaidCount",team.getPaidCount());m.put("groupBuySize",team.getGroupSize());}}RefundRow refund=mapper.selectRefundByOrder(o.getId());if(refund!=null)m.put("refund",refundMap(refund));if(includeCoupons)m.put("coupons",mapper.selectOrderCoupons(o.getId(),o.getUserId()).stream().map(this::couponMap).toList());return m;}
 private Map<String,Object> refundMap(RefundRow r){Map<String,Object>m=new LinkedHashMap<>();m.put("id",r.getId());m.put("amount",r.getAmount());m.put("reason",r.getReason());m.put("refundType",r.getRefundType());m.put("status",r.getStatus());m.put("statusText",switch(r.getStatus()){case 1->"退款成功";case 2->"已驳回";case 3->"退款处理中";case 4->"退款失败";default->"申请中";});m.put("channel",r.getChannel()==null?"":r.getChannel());m.put("channelRefundTxn",r.getChannelRefundTxn()==null?"":r.getChannelRefundTxn());m.put("channelStatus",r.getChannelStatus()==null?"":r.getChannelStatus());m.put("channelFailureReason",r.getChannelFailureReason()==null?"":r.getChannelFailureReason());m.put("auditReason",r.getAuditReason());m.put("auditedAt",r.getAuditedAt());m.put("createdAt",r.getCreatedAt());return m;}
 private Map<String,Object> couponMap(CouponRow c){Map<String,Object>m=new LinkedHashMap<>();m.put("id",c.getId());m.put("orderId",c.getOrderId());m.put("code",c.getCode());m.put("status",c.getStatus());m.put("statusText",switch(c.getStatus()){case 2->"已使用";case 3->"已过期";case 4->"已退款";default->"待使用";});m.put("dealId",c.getDealId());m.put("dealTitle",c.getDealTitle());m.put("shopId",c.getShopId());m.put("shopName",c.getShopName());m.put("coverImage",c.getCoverImage());m.put("expireAt",c.getExpireAt());return m;}
 private Map<String,Object> couponDetailMap(CouponRow c){
  Map<String,Object> m=new LinkedHashMap<>(couponMap(c));
  m.put("rules",c.getDealRules()==null?"":c.getDealRules());
  m.put("validStart",c.getValidStart());
  m.put("validEnd",c.getValidEnd());
  m.put("verifyAt",c.getVerifyAt());
  boolean usable=c.getStatus()!=null&&c.getStatus()==1
          &&(c.getExpireAt()==null||!c.getExpireAt().isBefore(LocalDate.now()));
  m.put("usable",usable);
  // Merchant verify API accepts the raw coupon code; keep payload identical for scan/manual entry.
  String qrPayload=c.getCode()==null?"":c.getCode();
  m.put("qrPayload",qrPayload);
  m.put("qrImageUrl",buildQrImageUrl(qrPayload));
  m.put("verifyHint",usable?"到店后出示二维码或券码，由商户核销。":"当前券码不可核销。");
  return m;
 }
 private String buildQrImageUrl(String payload){
  return CouponQrCodeRenderer.pngDataUrl(payload);
 }
 private void notifyOrderPaid(OrderRow order){
  if(order==null||order.getUserId()==null)return;
  String dealTitle=order.getDealTitle()==null||order.getDealTitle().isBlank()?"团购订单":order.getDealTitle();
  String amountText=order.getAmount()==null?"":order.getAmount().setScale(2,RoundingMode.HALF_UP).toPlainString();
  String currency=order.getCurrency()==null||order.getCurrency().isBlank()?"":order.getCurrency();
  String content=dealTitle
          +" · 订单 "+order.getOrderNo()
          +(amountText.isBlank()?"":" · "+amountText+(currency.isBlank()?"":" "+currency))
          +" · 券码已发放，可在我的券查看";
  String linkUrl="/user/orders/"+order.getId()+"?paid=1";
  String region=order.getRegion()==null||order.getRegion().isBlank()?RegionContext.getRegion().name():order.getRegion();
  notificationService.create(order.getUserId(),region,ORDER_PAID_TYPE,"支付成功",content,linkUrl);
 }
 private String sign(String orderNo,String txn,String status,BigDecimal amount){try{String raw=orderNo+"|"+txn+"|"+status+"|"+amount.setScale(2).toPlainString()+"|"+secret;return HexFormat.of().formatHex(MessageDigest.getInstance("SHA-256").digest(raw.getBytes(StandardCharsets.UTF_8)));}catch(Exception e){throw new IllegalStateException(e);}}
}
