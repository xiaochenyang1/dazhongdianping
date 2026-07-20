# M5a Merchant Identity and RBAC Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the single configured merchant login with database-backed merchant registration, settlement review, staff roles, permissions, and shop scopes.

**Architecture:** Keep `merchant` as the business entity and add separate operator, role, application, scope, and operation-log tables. Authentication reads BCrypt credentials from the database; authorization resolves permissions and shop scope from MyBatis queries and is reused by later M5 operational modules.

**Tech Stack:** Java 17, Spring Boot 3, MyBatis, H2/MySQL, BCrypt, JUnit 5, MockMvc.

---

### Task 1: Lock the database contract with failing mapper tests

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/mapper/MerchantIdentityMapperTest.java`
- Modify: `backend/src/main/resources/schema.sql`
- Modify: `backend/src/main/resources/data.sql`
- Modify: `sql/mysql/01_schema.sql`
- Modify: `sql/mysql/02_seed_data.sql`

- [ ] Write a mapper integration test that expects seeded owner operator `merchant_eu_sichuan@example.com`, the four built-in roles, BCrypt password storage, and shop-scope rows.
- [ ] Run `backend/mvnw.cmd -Dtest=MerchantIdentityMapperTest test`; expect failure because the new tables and mapper do not exist.
- [ ] Add `merchant_operator`, `merchant_role`, `merchant_operator_role`, `merchant_operator_shop`, `merchant_application`, and `merchant_operation_log` to H2 and MySQL schemas.
- [ ] Seed owner operators for merchants `1001/1002/2001/2002`, seed the four roles, and bind every owner to `owner` with `shop_scope_type=1`.
- [ ] Re-run the mapper test; expect all assertions to pass.

### Task 2: Replace configured login with database authentication

**Files:**
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/mapper/MerchantIdentityMapper.java`
- Create: `backend/src/main/resources/mapper/MerchantIdentityMapper.xml`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/model/MerchantOperatorRow.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/auth/MerchantSession.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/auth/service/MerchantAuthService.java`
- Modify: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantWorkbenchControllerTest.java`

- [ ] Change the login test to prove that both seeded EU merchant accounts authenticate from database credentials and that a disabled operator is rejected.
- [ ] Run the focused test and verify it fails because `MerchantAuthService` still compares one configured account.
- [ ] Add mapper queries for account lookup and operator status; expand `MerchantSession` to `operatorId, merchantId, account, operatorType` while keeping a compatibility constructor for existing tests.
- [ ] Inject `PasswordEncoder` and `MerchantIdentityMapper` into `MerchantAuthService`; issue the current expiring opaque token only after BCrypt verification.
- [ ] Re-run the focused and existing merchant tests; expect green.

### Task 3: Implement registration and settlement lifecycle

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantSettlementControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/service/MerchantIdentityService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/model/request/MerchantRegisterRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/model/request/MerchantSettlementApplyRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantWorkbenchController.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/mapper/MerchantIdentityMapper.java`
- Modify: `backend/src/main/resources/mapper/MerchantIdentityMapper.xml`

- [ ] Write a MockMvc test: register a unique account, receive a token, submit license/legal-person/shop photos, and read pending settlement status.
- [ ] Add a second test proving duplicate account registration is rejected and rejected applications can be resubmitted.
- [ ] Run the tests and verify RED on missing routes.
- [ ] Implement transactional merchant + owner operator + owner role creation, BCrypt password storage, settlement upsert, and status response.
- [ ] Re-run the focused tests and verify GREEN.

### Task 4: Implement admin settlement review

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/admin/merchant/AdminMerchantApplicationControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/merchant/controller/AdminMerchantApplicationController.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/merchant/service/AdminMerchantApplicationService.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/admin/merchant/model/request/AdminMerchantAuditRequest.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/mapper/MerchantIdentityMapper.java`
- Modify: `backend/src/main/resources/mapper/MerchantIdentityMapper.xml`

- [ ] Write tests for paginated pending applications, approval, rejection-reason validation, and merchant audit-status synchronization.
- [ ] Run the tests and verify missing-route failures.
- [ ] Implement list/audit services and write an `admin_audit_log` entry for every decision.
- [ ] Re-run the focused tests and verify GREEN.

### Task 5: Implement roles, permissions, and shop-scope authorization

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/service/MerchantAuthorizationServiceTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/service/MerchantAuthorizationService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/service/MerchantWorkbenchService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/mapper/MerchantIdentityMapper.java`
- Modify: `backend/src/main/resources/mapper/MerchantIdentityMapper.xml`

- [ ] Write tests proving owner access, staff permission denial, assigned-shop access, and cross-merchant shop denial.
- [ ] Run and verify RED because permissions are still hard-coded.
- [ ] Implement role/permission/shop-scope queries and `requirePermission`/`requireShop` methods.
- [ ] Change `/account/me`, `/roles`, and `/shops` to return the current operator’s database permissions and assigned shops.
- [ ] Re-run authorization and workbench tests; expect GREEN.

### Task 6: Implement staff CRUD and disable semantics

**Files:**
- Create: `backend/src/test/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantStaffControllerTest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/model/request/MerchantStaffCreateRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/model/request/MerchantStaffUpdateRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/model/request/MerchantStaffStatusRequest.java`
- Create: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/identity/service/MerchantStaffService.java`
- Modify: `backend/src/main/java/com/tuowei/dazhongdianping/module/merchant/controller/MerchantWorkbenchController.java`

- [ ] Write tests for owner-created staff, role/shop bindings, staff login, update, disable, and blocked login after disable.
- [ ] Add negative tests for staff modifying the owner and assigning another merchant’s shop.
- [ ] Run and verify RED on missing routes.
- [ ] Implement paginated list/create/update/status operations with transactional replacement of role/shop mappings and operation logs.
- [ ] Re-run focused tests and all merchant tests; expect GREEN.

### Task 7: Verification and documentation

**Files:**
- Modify: `README.md`
- Modify: `docs/当前已完成功能与SQL导入说明.md`
- Modify: `docs/接口设计.md`
- Modify: `docs/数据库设计.md`
- Modify: `docs/测试清单与验收用例.md`

- [ ] Run `backend/mvnw.cmd test`; require zero failures.
- [ ] Run `scripts/ci/verify-all.ps1`; require backend, Web tests, and both builds to pass.
- [ ] Update endpoint, table, seed-account, and automated-test counts without claiming M5b/M5c/M5d completion.
- [ ] Review the design and plan for placeholders, contradictory status values, and missing security cases; fix any issue before moving to M5b.
