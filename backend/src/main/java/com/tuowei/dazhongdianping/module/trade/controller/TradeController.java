package com.tuowei.dazhongdianping.module.trade.controller;
import com.tuowei.dazhongdianping.common.api.*;import com.tuowei.dazhongdianping.module.trade.model.request.*;import com.tuowei.dazhongdianping.module.trade.payment.*;import com.tuowei.dazhongdianping.module.trade.service.TradeService;import jakarta.servlet.http.HttpServletRequest;import jakarta.validation.Valid;import java.util.*;import org.springframework.web.bind.annotation.*;
@RestController @RequestMapping("/api/c/v1") public class TradeController {
 private final TradeService service;private final PaymentChannelResolver channelResolver;public TradeController(TradeService service,PaymentChannelResolver channelResolver){this.service=service;this.channelResolver=channelResolver;}
 @GetMapping("/shops/{shopId}/deals") public ApiResponse<List<Map<String,Object>>> shopDeals(@PathVariable Long shopId){return ApiResponse.success(service.shopDeals(shopId));}
 @GetMapping("/deals/{dealId}") public ApiResponse<Map<String,Object>> deal(@PathVariable Long dealId){return ApiResponse.success(service.deal(dealId));}
 @PostMapping("/orders") public ApiResponse<Map<String,Object>> create(@Valid @RequestBody OrderCreateRequest request){return ApiResponse.success(service.createOrder(request));}
 @GetMapping("/orders") public ApiResponse<PageResult<Map<String,Object>>> orders(@RequestParam(required=false)Integer payStatus,@RequestParam(defaultValue="1")Integer page,@RequestParam(defaultValue="12")Integer pageSize){return ApiResponse.success(service.orders(payStatus,page,pageSize));}
 @GetMapping("/orders/{id}") public ApiResponse<Map<String,Object>> order(@PathVariable Long id){return ApiResponse.success(service.order(id));}
 @PostMapping("/orders/{id}/pay") public ApiResponse<Map<String,Object>> pay(@PathVariable Long id){return ApiResponse.success(service.pay(id));}
 @PostMapping("/orders/{id}/pay/mock-complete") public ApiResponse<Map<String,Object>> completeMock(@PathVariable Long id){return ApiResponse.success(service.completeMockPayment(id));}
 @PostMapping("/orders/{id}/cancel") public ApiResponse<Map<String,Object>> cancel(@PathVariable Long id){return ApiResponse.success(service.cancel(id));}
 @PostMapping("/orders/{id}/refund") public ApiResponse<Map<String,Object>> refund(@PathVariable Long id,@Valid @RequestBody RefundRequest request){return ApiResponse.success(service.refund(id,request));}
 @PostMapping("/pay/notify/stripe") public ApiResponse<Map<String,Object>> notifyStripe(HttpServletRequest request){ChannelWebhookResult r=channelResolver.resolveByChannel("stripe").verifyWebhookEvent(request);return ApiResponse.success(service.handleChannelWebhook("stripe",r));}
 @PostMapping("/pay/notify/{channel}") public ApiResponse<Map<String,Object>> notify(@PathVariable String channel,HttpServletRequest request){ChannelWebhookResult r=channelResolver.resolveByChannel(channel).verifyWebhookEvent(request);return ApiResponse.success(service.handleChannelWebhook(channel,r));}
 @GetMapping("/coupons") public ApiResponse<PageResult<Map<String,Object>>> coupons(@RequestParam(required=false)Integer status,@RequestParam(defaultValue="1")Integer page,@RequestParam(defaultValue="12")Integer pageSize){return ApiResponse.success(service.coupons(status,page,pageSize));}
 @GetMapping("/coupons/{code}") public ApiResponse<Map<String,Object>> couponDetail(@PathVariable String code){return ApiResponse.success(service.couponDetail(code));}
}
