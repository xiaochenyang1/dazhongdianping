# M5b1 Reservation Workbench and Dashboard Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build scoped merchant reservation queries, merchant rescheduling, permission-protected fulfillment, and a real-data operating dashboard.

**Architecture:** Extend the existing reservation mapper/service instead of creating a parallel state machine. Add a daily shop-view aggregate and a focused dashboard mapper; enforce operator permissions and shop scope before every merchant read or write while retaining SQL merchant/region predicates.

**Tech Stack:** Java 17, Spring Boot 3, MyBatis, H2/MySQL, MockMvc, JUnit 5.

---

### Task 1: Reservation list and detail

- [ ] Add failing `MerchantReservationWorkbenchControllerTest` cases for filters, pagination, detail timeline, and scoped-shop denial.
- [ ] Run the focused test and confirm missing-route failures.
- [ ] Add merchant list/count/detail mapper queries with merchant, region, date, status, and shop-scope predicates.
- [ ] Add `MerchantReservationService` and controller GET routes.
- [ ] Re-run focused tests and require green.

### Task 2: Merchant reschedule transaction

- [ ] Add failing tests for automatic/manual confirmation, capacity exchange, invalid state, and cross-shop slot rejection.
- [ ] Run RED on the missing route.
- [ ] Add a conditional merchant reschedule update and implement occupy-new/update/release-old/log action `6` in one transaction.
- [ ] Re-run reservation tests and require green.

### Task 3: Permission-protect fulfillment

- [ ] Add failing tests proving a coupon operator cannot confirm and a scoped operator cannot act on another shop.
- [ ] Add `requireShop` to `MerchantAuthorizationService` and inject authorization into fulfillment/reservation services.
- [ ] Write actual operator IDs into reservation logs and coupon `verify_by`.
- [ ] Re-run all merchant tests and require green.

### Task 4: Real shop-view aggregation and dashboard

- [ ] Add failing tests that visit shop detail, create/pay an order, verify a coupon, create a reservation, and assert dashboard totals/trends.
- [ ] Add `shop_view_daily` to H2/MySQL and atomically increment it from public shop detail reads.
- [ ] Add `MerchantDashboardMapper/Service` aggregating views, paid orders, verified coupons, reservations, score, and daily trends.
- [ ] Add `GET /api/b/v1/dashboard`, default 7 days and reject ranges over 90 days.
- [ ] Re-run focused tests and require green.

### Task 5: Verification and documentation

- [ ] Run `backend/mvnw.cmd test` with zero failures.
- [ ] Run `scripts/ci/verify-all.ps1` and require all checks/builds to pass.
- [ ] Update README, interface/database/test documents without claiming later M5b/M5c/M5d work is complete.
